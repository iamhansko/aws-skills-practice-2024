#!/bin/bash
aws configure set default.region ap-northeast-2

echo "======= 1-1-A ======="
aws ec2 describe-vpcs --filter Name=tag:Name,Values=wsc-prod-vpc --query "Vpcs[0].CidrBlock" \
; aws ec2 describe-vpcs --filter Name=tag:Name,Values=wsc-inspect-vpc --query "Vpcs[0].CidrBlock" \
; aws ec2 describe-vpcs --filter Name=tag:Name,Values=wsc-ingress-vpc --query "Vpcs[0].CidrBlock" \
; aws ec2 describe-vpcs --filter Name=tag:Name,Values=wsc-egress-vpc --query "Vpcs[0].CidrBlock"

echo ""
echo "======= 1-2-A ======="
aws ec2 describe-subnets --filters \
"Name=tag:Name,Values=wsc-prod-peering-sn-a,wsc-prod-peering-sn-c,wsc-prod-workload-sn-a,wsc-prod-workload-sn-c,wsc-prod-protect-sn-a,wsc-prod-protect-sn-c,wsc-inspect-secure-sn-a,wsc-inspect-secure-sn-c,wsc-inspect-peering-sn-a,wsc-inspect-peering-sn-c,wsc-ingress-pub-sn-a,wsc-ingress-pub-sn-c,wsc-ingress-peering-sn-a,wsc-ingress-peering-sn-c,wsc-egress-pub-sn-a,wsc-egress-pub-sn-c,wsc-egress-peering-sn-a,wsc-egress-peering-sn-c" \
  --query "Subnets[*].{Tag:Tags[?Key=='Name']|[0].Value,CidrBlock:CidrBlock}" \
  --output text

echo ""
echo "======= 1-3-A ======="
tgw_id=$(aws ec2 describe-transit-gateways --query "TransitGateways[?Tags[?Value=='wsc-vpc-tgw']].TransitGatewayId" --output text)
attachment_ids=$(aws ec2 describe-transit-gateway-attachments --filter "Name=transit-gateway-id,Values=$tgw_id" --query "TransitGatewayAttachments[*].TransitGatewayAttachmentId" --output text)
subnet_ids=$(aws ec2 describe-transit-gateway-vpc-attachments --transit-gateway-attachment-ids $attachment_ids --query "TransitGatewayVpcAttachments[*].SubnetIds[]" --output text)
for subnet_id in $subnet_ids; do
    subnet_name=$(aws ec2 describe-tags --filters "Name=resource-id,Values=$subnet_id" "Name=key,Values=Name" --query "Tags[0].Value" --output text)
    echo $subnet_name
done


echo ""
echo "======= 1-4-A ======="
VPC_ID=$(aws ec2 describe-vpcs --filters "Name=tag:Name,Values=wsc-prod-vpc" --query "Vpcs[*].VpcId" --output text)
SUBNET_A_ID=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" "Name=tag:Name,Values=wsc-prod-workload-sn-a" --query "Subnets[*].SubnetId" --output text)
SUBNET_C_ID=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" "Name=tag:Name,Values=wsc-prod-workload-sn-c" --query "Subnets[*].SubnetId" --output text)
ROUTE_TABLE_A_ID=$(aws ec2 describe-route-tables --filters "Name=association.subnet-id,Values=$SUBNET_A_ID" --query "RouteTables[*].RouteTableId" --output text)
ROUTE_TABLE_C_ID=$(aws ec2 describe-route-tables --filters "Name=association.subnet-id,Values=$SUBNET_C_ID" --query "RouteTables[*].RouteTableId" --output text)
NAT_GATEWAY_ID_A=$(aws ec2 describe-route-tables --route-table-ids $ROUTE_TABLE_A_ID --query "RouteTables[*].Routes[?NatGatewayId].NatGatewayId" --output text)
NAT_GATEWAY_ID_C=$(aws ec2 describe-route-tables --route-table-ids $ROUTE_TABLE_C_ID --query "RouteTables[*].Routes[?NatGatewayId].NatGatewayId" --output text)
echo $NAT_GATEWAY_ID_A ; echo $NAT_GATEWAY_ID_C

echo ""
echo "======= 1-4-B ======="
SUBNET_A_TYPE=$(aws ec2 describe-route-tables --filters "Name=association.subnet-id,Values=$NAT_SUBNET_A_ID" --query "RouteTables[*].Routes[?GatewayId == 'igw-*'].GatewayId" --output text)
SUBNET_C_TYPE=$(aws ec2 describe-route-tables --filters "Name=association.subnet-id,Values=$NAT_SUBNET_C_ID" --query "RouteTables[*].Routes[?GatewayId == 'igw-*'].GatewayId" --output text)
NAT_SUBNET_A_ID=$(aws ec2 describe-nat-gateways --nat-gateway-ids $NAT_GATEWAY_ID_A --query "NatGateways[*].SubnetId" --output text)
NAT_SUBNET_C_ID=$(aws ec2 describe-nat-gateways --nat-gateway-ids $NAT_GATEWAY_ID_C --query "NatGateways[*].SubnetId" --output text)
aws ec2 describe-subnets --subnet-ids $NAT_SUBNET_A_ID --query "Subnets[*].Tags[?Key=='Name'].Value" --output text
aws ec2 describe-nat-gateways --nat-gateway-ids $NAT_GATEWAY_ID_A --query "NatGateways[*].ConnectivityType" --output text
aws ec2 describe-subnets --subnet-ids $NAT_SUBNET_C_ID --query "Subnets[*].Tags[?Key=='Name'].Value" --output text
aws ec2 describe-nat-gateways --nat-gateway-ids $NAT_GATEWAY_ID_C --query "NatGateways[*].ConnectivityType" --output text

echo ""
echo "======= 1-5-A ======="
INSTANCE_DETAILS=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=wsc-prod-bastion" --query "Reservations[*].Instances[*].{InstanceType:InstanceType}" --output text)
SUBNET_ID=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=wsc-prod-bastion" --query "Reservations[*].Instances[*].{SubnetId:SubnetId}" --output text)
SUBNET_NAME=$(aws ec2 describe-subnets --subnet-ids $SUBNET_ID --query "Subnets[*].Tags[?Key=='Name'].Value" --output text)
echo "$INSTANCE_DETAILS"
echo "$SUBNET_NAME"

echo ""
echo "======= 2-1-A ======="
distribution_ids=$(aws cloudfront list-distributions --query "DistributionList.Items[*].Id" --output text)
account_id=$(aws sts get-caller-identity --query "Account" --output text)
for id in $distribution_ids; do
    tags=$(aws cloudfront list-tags-for-resource --resource "arn:aws:cloudfront::$account_id:distribution/$id" --query "Tags.Items" --output json)
    if echo $tags | jq -e '.[] | select(.Key=="Name" and .Value=="wsc-prod-cdn")' > /dev/null; then
        domain=$(aws cloudfront get-distribution --id $id --query "Distribution.DomainName" --output text)
        echo "https://$domain/static/index.html"
    fi
done

echo ""
echo "======= 2-1-B ======="
echo "2-1-B Manual"

echo ""
echo "======= 2-2-A ======="
curl -XPOST -H "Content-Type: application/json" -d '{"id": "99999", "name": "kim", "gender": "male"}' https://$domain/v1/customer
echo ""
curl -XPOST -H "Content-Type: application/json" -d '{"id": "100000", "name": "lee", "gender": "female"}' https://$domain/v1/customer

echo ""
echo "======= 2-2-B ======="
curl -XGET https://$domain/v1/customer?id=99999
echo ""
curl -XGET https://$domain/v1/customer?id=100000


echo ""
echo "======= 2-3-A ======="
curl -XPOST -H "Content-Type: application/json" -d '{"id": "99999", "name": "kim", "category": "phone"}' https://$domain/v1/product
echo ""
curl -XPOST -H "Content-Type: application/json" -d '{"id": "100000", "name": "lee", "category": "computer"}' https://$domain/v1/product

echo ""
echo "======= 2-3-B ======="
curl -XGET https://$domain/v1/product?id=99999
echo ""
curl -XGET https://$domain/v1/product?id=100000

echo ""
echo "======= 2-4-A ======="
curl -XPOST -H "Content-Type: application/json" -d '{"id": "100", "customerid": "99999", "productid": "p1"}' https://$domain/v1/order
echo ""
curl -XPOST -H "Content-Type: application/json" -d '{"id": "101", "customerid": "100000", "productid": "c1"}' https://$domain/v1/order

echo ""
echo "======= 2-4-B ======="
curl -XGET https://$domain/v1/product?id=99999
echo ""
curl -XGET https://$domain/v1/product?id=100000

echo ""
echo "======= 3-1-A ======="
load_balancer_arns=$(aws elbv2 describe-load-balancers --query "LoadBalancers[*].LoadBalancerArn" --output text)
for arn in $load_balancer_arns; do
    load_balancer_info=$(aws elbv2 describe-load-balancers --load-balancer-arns $arn --query "LoadBalancers[0].{Name:LoadBalancerName, VpcId:VpcId, Scheme:Scheme}" --output json)
    name=$(echo $load_balancer_info | jq -r '.Name')
    vpc_id=$(echo $load_balancer_info | jq -r '.VpcId')
    scheme=$(echo $load_balancer_info | jq -r '.Scheme')
    echo "$name $vpc_id $scheme"
done

echo ""
echo "======= 4-1-A ======="
rds_instance_identifiers=$(aws rds describe-db-clusters --db-cluster-identifier wsc-prod-db-cluster --query "DBClusters[0].DBClusterMembers[*].DBInstanceIdentifier" --output text)
for instance_id in $rds_instance_identifiers; do
    instance_info=$(aws rds describe-db-instances --db-instance-identifier $instance_id --query "DBInstances[0].{InstanceType:DBInstanceClass, Engine:Engine, EngineVersion:EngineVersion, Endpoint:Endpoint.Address}" --output json)
    instance_type=$(echo $instance_info | jq -r '.InstanceType')
    engine=$(echo $instance_info | jq -r '.Engine')
    engine_version=$(echo $instance_info | jq -r '.EngineVersion')
    endpoint=$(echo $instance_info | jq -r '.Endpoint')
done
echo -e "$instance_type\n$engine\n$engine_version" 

echo ""
echo "======= 4-2-A ======="
mysql -u skill -pSkill53## -h $endpoint -e "use wscdb ; SHOW TABLES"



echo ""
echo "======= 5-1-A ======="
aws dynamodb scan --table-name order --attributes-to-get "id" "customerid" "productid" --query Items[]

echo ""
echo "======= 5-2-A ======="
vpc_endpoint_dynamodb=$(aws ec2 describe-vpc-endpoints --filters "Name=service-name,Values=com.amazonaws.ap-northeast-2.dynamodb" "Name=vpc-id,Values=$(aws ec2 describe-vpcs --filters "Name=tag:Name,Values=wsc-prod-vpc" --query "Vpcs[0].VpcId" --output text)" --query "VpcEndpoints[0].VpcEndpointId" --output text)
if [ -z "$vpc_endpoint_dynamodb" ]; then
    echo ""
else
    echo $vpc_endpoint_dynamodb
fi

echo ""
echo "======= 6-1-A ======="
aws ecr list-images --repository-name customer --query 'imageIds[*].imageTag' --output text | wc -l
aws ecr list-images --repository-name order --query 'imageIds[*].imageTag' --output text | wc -l
aws ecr list-images --repository-name product --query 'imageIds[*].imageTag' --output text | wc -l

echo ""
echo "======= 7-1-A ======="
firewall_info=$(aws network-firewall describe-firewall --firewall-name wsc-inspect-firewall)
echo "$firewall_info" | jq -r '.Firewall.SubnetMappings[] | "ID: \(.SubnetId)"' | while read -r subnet_info; do
    subnet_id=$(echo "$subnet_info" | awk '{print $2}')
    subnet_name=$(aws ec2 describe-subnets --subnet-ids "$subnet_id" --query 'Subnets[*].Tags[?Key==`Name`].Value' --output text)
    echo $subnet_name
done


echo ""
echo "======= 7-2-A ======="
aws network-firewall describe-firewall-policy --firewall-policy-name wsc-inspect-rules --query 'FirewallPolicyResponse.{FirewallPolicyName: FirewallPolicyName}' --output text
arn=$(aws network-firewall list-rule-groups --query "RuleGroups[?contains(Name, 'wsc-deny')].Arn" --output text) && \
(aws network-firewall describe-rule-group --rule-group-arn $arn --query 'RuleGroup.RulesSource' --output json | grep -q "RulesString" && echo "Suricata" || echo "null")

echo ""
echo "======= 7-3-A ======="
curl --max-time 10 ifconfig.io
timeout 5 openssl s_client -connect www.naver.com:443 -tls1
timeout 5 openssl s_client -connect www.naver.com:443 -tls1_1
timeout 2 openssl s_client -connect www.naver.com:443 -tls1_2 | grep "SSL handshake has read"


echo ""
echo "======= 7-4-A ======="
echo "manual"
echo 'cat << EOF > update_rule.json
{
  "RulesSource": {
    "RulesString": "pass tcp any any -> any any (msg:\"Allow all traffic\"; sid:1; rev:1;)"
  }
}
EOF
UPDATE_TOKEN=$(aws network-firewall describe-rule-group --rule-group-name wsc-deny --type STATEFUL --query UpdateToken --output text)
aws network-firewall update-rule-group --update-token $UPDATE_TOKEN --rule-group-name "wsc-deny" --type STATEFUL --rule-group file://update_rule.json
echo ""
echo "wait 30 seconds"
echo ""
curl -s -o /dev/null -w "%{http_code}" --max-time 10 ifconfig.io
timeout 5 openssl s_client -connect www.naver.com:443 -tls1 | grep "SSL handshake has read"
timeout 5 openssl s_client -connect www.naver.com:443 -tls1_1 | grep "SSL handshake has read"
'

echo ""
echo "======= 8-1-A ======="
eksctl get cluster --region ap-northeast-2 | grep wsc-prod-cluster

echo ""
echo "======= 8-2-A ======="
kubectl get deployment -n wsc-prod | awk '{print $1}' 

echo ""
echo "======= 8-3-A ======="
for node in $(kubectl get nodes -o jsonpath='{.items[*].metadata.name}'); do
    instance_id=$(aws ec2 describe-instances --filters "Name=private-dns-name,Values=$node" --query "Reservations[*].Instances[*].InstanceId" --output text)
    instance_type=$(aws ec2 describe-instances --instance-ids $instance_id --query "Reservations[*].Instances[*].InstanceType" --output text)
    instance_name=$(aws ec2 describe-instances --instance-ids $instance_id --query "Reservations[*].Instances[*].Tags[?Key=='Name'].Value" --output text)
done
echo $instance_type
echo $instance_name

echo ""
echo "======= 9-1-A ======="
echo "manual"
echo "for i in {1..1000000}; do ping -c 1 1.1.1.1; done"