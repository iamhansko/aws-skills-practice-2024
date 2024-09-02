export DistributionID="<Cloudfront_Distribution_ID>"
export S3_BUCKET="skills-static-<4words>"
export CF_DOMAIN=$(aws cloudfront get-distribution --id ${DistributionID} --query "Distribution.DomainName" | sed s/\"//g)
aws configure set default.region ap-northeast-2
export InvalidationID=$(aws cloudfront create-invalidation --distribution-id ${DistributionID} --paths "/*" --query "Invalidation.Id" | sed s/\"//g)
aws cloudfront wait invalidation-completed --distribution-id ${DistributionID} --id ${InvalidationID}

echo -e "============1-1-A============"
aws ec2 describe-vpcs --filter Name=tag:Name,Values=skills-vpc --query "Vpcs[0].CidrBlock" \
; aws ec2 describe-subnets --filter Name=tag:Name,Values=skills-app-a --query "Subnets[0].CidrBlock" \
; aws ec2 describe-subnets --filter Name=tag:Name,Values=skills-app-b --query "Subnets[0].CidrBlock" \
; aws ec2 describe-subnets --filter Name=tag:Name,Values=skills-public-a --query "Subnets[0].CidrBlock" \
; aws ec2 describe-subnets --filter Name=tag:Name,Values=skills-public-b --query "Subnets[0].CidrBlock" \
; aws ec2 describe-subnets --filter Name=tag:Name,Values=skills-data-a --query "Subnets[0].CidrBlock" \
; aws ec2 describe-subnets --filter Name=tag:Name,Values=skills-data-b --query "Subnets[0].CidrBlock"

echo -e "\n============1-2-A============"
aws ec2 describe-route-tables --filter Name=tag:Name,Values=skills-app-a-rt --query "RouteTables[].Routes[].NatGatewayId" | grep "nat-" | wc -l \
; aws ec2 describe-route-tables --filter Name=tag:Name,Values=skills-app-b-rt --query "RouteTables[].Routes[].NatGatewayId"  | grep "nat-" | wc -l \
; aws ec2 describe-route-tables --filter Name=tag:Name,Values=skills-public-rt --query "RouteTables[].Routes[]" | grep "igw-" | wc -l \
; aws ec2 describe-route-tables --filter Name=tag:Name,Values=skills-data-rt --query "RouteTables[].Routes[]" | grep -E "igw-|nat-" | wc -l

echo -e "\n============1-3-A============"
aws ec2 describe-vpc-endpoints --query "VpcEndpoints[].ServiceName"

echo -e "\n============2-1-A============"
aws ec2 describe-instances --filter Name=tag:Name,Values=skills-bastion --query "Reservations[0].Instances[0].InstanceType" \
; aws ec2 describe-subnets --subnet-ids $(aws ec2 describe-instances --filters "Name=tag:Name,Values=skills-bastion" | jq -r '.Reservations[].Instances[].SubnetId') | jq -r '.Subnets[0].Tags[] | select(.Key=="Name") | .Value'

echo -e "\n============3-1-A============"
aws rds describe-db-instances --db-instance-identifier $(aws rds describe-db-clusters --db-cluster-identifier skills-aurora-mysql --query "DBClusters[0].DBClusterMembers[0].DBInstanceIdentifier" --output text) --query "DBInstances[0].{Engine:Engine,DBInstanceClass:DBInstanceClass,DBInstanceStatus:DBInstanceStatus,StorageEncrypted:StorageEncrypted}" \
; aws ec2 describe-subnets --subnet-ids $(aws rds describe-db-subnet-groups --db-subnet-group-name $(aws rds describe-db-clusters --db-cluster-identifier skills-aurora-mysql --query 'DBClusters[*].DBSubnetGroup' --output text) --query 'DBSubnetGroups[*].Subnets[*].SubnetIdentifier' --output text) --query 'Subnets[*].Tags[?Key==`Name`].Value' --output text

echo -e "\n============4-1-A============"
aws dynamodb describe-table --table-name order --query 'Table.{Encryption: {Status: SSEDescription.Status, SSEType: SSEDescription.SSEType}, PrimaryKey: KeySchema[?KeyType==`HASH`].AttributeName | [0],CapacityMode: BillingModeSummary.BillingMode}' --output json

echo -e "\n============5-1-A============"
curl -X POST --max-time 5 -w "\n%{http_code}\n" https://${CF_DOMAIN}/v1/customer -H "Content-Type: application/json" -d '{"id":"8fa5cde15b9a","name":"James","gender":"male"}' \
; curl -X GET --max-time 5 -w "\n%{http_code}\n" https://${CF_DOMAIN}/v1/customer?id=8fa5cde15b9a

echo -e "\n============5-1-B============"
curl -X POST --max-time 5 -w "\n%{http_code}\n" https://${CF_DOMAIN}/v1/product -H "Content-Type: application/json" -d '{"id":"1b67ba873206","name":"sushi","category":"food"}' \
; curl -X GET --max-time 5 -w "\n%{http_code}\n" https://${CF_DOMAIN}/v1/product?id=1b67ba873206

echo -e "\n============5-2-A============"
curl -X POST --max-time 5 -w "\n%{http_code}\n" https://${CF_DOMAIN}/v1/order -H "Content-Type: application/json" -d '{"id":"a596f991de36","customerid":"8fa5cde15b9a","productid":"1b67ba873206"}'

echo -e "\n============5-2-B============"
curl -X GET --max-time 5 -w "\n%{http_code}\n" https://${CF_DOMAIN}/v1/order?id=a596f991de36

echo -e "\n============5-3-A============"
kubectl get ExternalSecret application-db-secret -n app | awk 'NR==2 {print $4}' \
; aws secretsmanager describe-secret --secret-id skills-rds-secret --query RotationEnabled

echo -e "\n============6-1-A============"
aws eks describe-nodegroup --cluster-name skills-eks-cluster --nodegroup-name skills-eks-addon-nodegroup --query 'nodegroup.{NodeGroupName:nodegroupName, Status:status, DesiredSize:scalingConfig.desiredSize, InstanceTypes:instanceTypes, LaunchTemplateExists:launchTemplate != null}' --output json \
; aws eks describe-nodegroup --cluster-name skills-eks-cluster --nodegroup-name skills-eks-app-nodegroup --query 'nodegroup.{NodeGroupName:nodegroupName, Status:status, DesiredSize:scalingConfig.desiredSize, InstanceTypes:instanceTypes, LaunchTemplateExists:launchTemplate != null}' --output json

echo -e "\n============6-2-A============"
POD_NODES=$(kubectl get pod -n app --no-headers | awk '{print $1}' | xargs -I {} kubectl describe pod {} -n app | grep 'Node:' | awk '{gsub(/\/.*/, "", $2); print $2}' | sort | uniq)
NODEGROUP_NODES=$(kubectl get nodes -l eks.amazonaws.com/nodegroup=skills-eks-app-nodegroup --no-headers | awk '{print $1}' | sort | uniq)
DIFF=$(diff <(echo "$POD_NODES") <(echo "$NODEGROUP_NODES"))
if [ -z "$DIFF" ]; then echo "True"; else echo "False"; fi

echo -e "\n============6-3-A============"
kubectl get pods -n kube-system -o wide --selector=eks.amazonaws.com/fargate-profile=coredns-profile --no-headers | awk '{print $3, $7}'

echo -e "\n============7-1-A============"
kubectl describe deploy -n ingress-nginx ingress-nginx-controller | grep "Image:" | awk '{print $2}'

echo -e "\n============7-2-A============"
kubectl get ingress ingress-nginx -n app -o yaml | grep "path:" | awk '{print $2}'

echo -e "\n============8-1-A============"
aws s3 ls | grep skills-static-

echo -e "\n============8-1-B============"
aws s3api get-bucket-policy --bucket $S3_BUCKET --output text | jq '.Statement[].Principal'

echo -e "\n============8-2-A============"
SSEAlgorithm=$(aws s3api get-bucket-encryption --bucket $S3_BUCKET --query 'ServerSideEncryptionConfiguration.Rules[].ApplyServerSideEncryptionByDefault.SSEAlgorithm' --output text); if [[ "$SSEAlgorithm" == "aws:kms" || "$SSEAlgorithm" == "aws:kms:dsse" ]]; then echo "True"; else echo "False"; fi

echo -e "\n============9-1-A============"
for i in {1..5}; do curl --silent -i -X GET --max-time 5 -w "\n%{http_code}\n" https://${CF_DOMAIN}/v1/customer?id=8fa5cde15b9a | grep -iE "x-cache:|^200$"; done

echo -e "\n============9-1-B============"
sleep 30 \
; for i in {1..5}; do curl --silent -i -X GET --max-time 5 -w "\n%{http_code}\n" https://${CF_DOMAIN}/v1/customer?id=8fa5cde15b9a | grep -iE "x-cache:|^200$"; done

echo -e "\n============9-2-A============"
cat << EOF >> testobject-cdn.txt
This is testobject for marking that CDN perform.
EOF
aws s3 cp --quiet testobject-cdn.txt s3://${S3_BUCKET}/static/ \
; for i in {1..5}; do curl --silent -i -X GET --max-time 5 -w "\n%{http_code}\n" https://${CF_DOMAIN}/static/testobject-cdn.txt | grep -iE "x-cache:|^200$"; done

echo -e "\n============9-2-B============"
sleep 30 \
; for i in {1..5}; do curl --silent -i -X GET --max-time 5 -w "\n%{http_code}\n" https://${CF_DOMAIN}/static/testobject-cdn.txt | grep -iE "x-cache:|^200$"; done

echo -e "\n============9-3-A============"
cat << EOF >> testobject-cdn2.txt
This is testobject for marking that CDN perform.
EOF
aws s3 cp --quiet testobject-cdn2.txt s3://${S3_BUCKET}/static/ \
; curl --silent -i -X GET --max-time 5 -w "\n%{http_code}\n" http://${CF_DOMAIN}/static/testobject-cdn2.txt | grep -iE "x-cache:|location:|^301$"

echo -e "\n============10-1-A============"
POD_NODES=$(kubectl get pods -n default | grep fluent-bit | awk '{print $1}' | xargs -I {} kubectl describe pod {} -n default | grep 'Node:' | awk '{gsub(/\/.*/, "", $2); print $2}' | sort)
NODEGROUP_NODES=$(kubectl get nodes -l eks.amazonaws.com/nodegroup=skills-eks-app-nodegroup --no-headers | awk '{print $1}' | sort | uniq)
DIFF=$(diff <(echo "$POD_NODES") <(echo "$NODEGROUP_NODES"))
if [ -z "$DIFF" ]; then echo "True"; else echo "False"; fi

echo -e "\n============10-1-B============"
aws opensearch describe-domain --domain-name skills-opensearch-domain --query 'DomainStatus.[EngineVersion, ClusterConfig.InstanceType]' --output json

echo -e "\n============10-2-A============"
kubectl exec -it -n app deployment.apps/customer -- curl localhost:8080/v1/customer?id=Logtest \
; kubectl exec -it -n app deployment.apps/product -- curl localhost:8080/v1/product?id=Logtest \
; kubectl exec -it -n app deployment.apps/order -- curl localhost:8080/v1/order?id=Logtest

echo -e "\n============11-1-A============"
echo "작업 수행"

echo -e "\n============12-1-A============"
curl -X GET --max-time 5 -w "\n%{http_code}\n" https://${CF_DOMAIN}/v1/customer?id=8fa5cde15b9a

echo -e "\n============12-1-B============"
curl -X PUT --max-time 5 -w "\n%{http_code}\n" https://${CF_DOMAIN}/v1/customer?id=8fa5cde15b9a

echo -e "\n============12-2-A============"
curl -X GET --max-time 5 -w "\n%{http_code}\n" https://${CF_DOMAIN}/v1/customer?id=skills-baduser-test
