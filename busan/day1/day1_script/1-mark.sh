#!/bin/bash

# set default region of aws cli
read -p "DistributionID <Cloudfront_Distribution_ID>: " DistributionID
aws configure set default.region ap-northeast-2
aws configure set default.output json

echo ----- 1-1 -----
aws ec2 describe-vpcs --filter Name=tag:Name,Values=wsi-vpc --query "Vpcs[0].CidrBlock" \
; aws ec2 describe-subnets --filter Name=tag:Name,Values=wsi-public-a --query "Subnets[0].CidrBlock" \
; aws ec2 describe-subnets --filter Name=tag:Name,Values=wsi-public-b --query "Subnets[0].CidrBlock" \
; aws ec2 describe-subnets --filter Name=tag:Name,Values=wsi-public-c --query "Subnets[0].CidrBlock" \
; aws ec2 describe-subnets --filter Name=tag:Name,Values=wsi-private-a --query "Subnets[0].CidrBlock" \
; aws ec2 describe-subnets --filter Name=tag:Name,Values=wsi-private-b --query "Subnets[0].CidrBlock" \
; aws ec2 describe-subnets --filter Name=tag:Name,Values=wsi-private-c --query "Subnets[0].CidrBlock" \
; aws ec2 describe-subnets --filter Name=tag:Name,Values=wsi-data-a --query "Subnets[0].CidrBlock" \
; aws ec2 describe-subnets --filter Name=tag:Name,Values=wsi-data-b --query "Subnets[0].CidrBlock" \
; aws ec2 describe-subnets --filter Name=tag:Name,Values=wsi-data-c --query "Subnets[0].CidrBlock"
echo

echo ----- 1-2 -----
aws ec2 describe-route-tables --filter Name=tag:Name,Values=wsi-public-rt --query "RouteTables[].Routes[]" | grep "igw-" | wc -l \
; aws ec2 describe-route-tables --filter Name=tag:Name,Values=wsi-private-a-rt --query "RouteTables[].Routes[].NatGatewayId" | grep "nat-" | wc -l \
; aws ec2 describe-route-tables --filter Name=tag:Name,Values=wsi-private-b-rt --query "RouteTables[].Routes[].NatGatewayId" | grep "nat-" | wc -l \
; aws ec2 describe-route-tables --filter Name=tag:Name,Values=wsi-private-c-rt --query "RouteTables[].Routes[].NatGatewayId" | grep "nat-" | wc -l \
; aws ec2 describe-route-tables --filter Name=tag:Name,Values=wsi-data-rt --query "RouteTables[].Routes[]" | grep -E "igw-|nat-" | wc -l
echo

echo ----- 1-3 -----
aws ec2 describe-flow-logs --query "FlowLogs[0].Tags[0].Value" \
; aws ec2 describe-flow-logs --query "FlowLogs[0].LogFormat" \
; LATEST_LOG_STREAM=$(aws logs describe-log-streams --log-group-name wsi-traffic-logs --order-by LastEventTime --descending --limit 1 --query "logStreams[0].logStreamName" --output text) \
; aws logs get-log-events --log-group-name wsi-traffic-logs --log-stream-name $LATEST_LOG_STREAM --limit 5 --query "events[*].{message:message}" --output text
echo

echo ----- 2-1 -----
aws ec2 describe-instances --filter "Name=tag:Name,Values=wsi-bastion-ec2" "Name=tag:ec2,Values=bastion" --query "Reservations[0].Instances[0].InstanceType" \
; BASTION_SUBNET=$(aws ec2 describe-instances --filter "Name=tag:Name,Values=wsi-bastion-ec2" "Name=tag:ec2,Values=bastion" --query "Reservations[*].Instances[*].SubnetId" --output text) \
; aws ec2 describe-subnets --subnet-ids $BASTION_SUBNET --query "Subnets[*].Tags[?Key=='Name'].Value" --output text | grep wsi-public-c \
; echo "1.)" | grep "1.)"; aws ec2 describe-instances --filter "Name=tag:Name,Values=wsi-bastion-ec2" "Name=tag:ec2,Values=bastion" --query "Reservations[].Instances[].PublicIpAddress" \
; echo "2.)" | grep "2.)"; aws ec2 describe-addresses --query "Addresses[].PublicIp"
echo

echo ----- 2-2 -----
INSTANCE_ID=$(aws ec2 describe-instances --filter "Name=tag:Name,Values=wsi-bastion-ec2" "Name=tag:ec2,Values=bastion" --query "Reservations[*].Instances[*].InstanceId" --output text) \
; aws ec2 describe-instances --instance-ids $INSTANCE_ID --query "Reservations[*].Instances[*].IamInstanceProfile.Arn" --output text | grep wsi-bastion-role \
; IAM_ROLE_NAME=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query "Reservations[*].Instances[*].IamInstanceProfile.Arn" --output text | awk -F'/' '{print $NF}') \
; aws iam list-attached-role-policies --role-name $IAM_ROLE_NAME --query "AttachedPolicies[*].PolicyName" --output text
echo

echo ----- 2-3 -----
aws ec2 describe-instances --filter "Name=tag:Name,Values=wsi-bastion-ec2" "Name=tag:ec2,Values=bastion" --query "Reservations[0].Instances[0].SecurityGroups[0].GroupName" \
; aws ec2 describe-security-groups --filter "Name=group-name,Values=wsi-bastion-SG" --query "SecurityGroups[0].IpPermissions[].{FromPort:FromPort,ToPort:ToPort,IpRanges:IpRanges}"
echo

echo ----- 2-4 -----
aws logs get-log-events --log-group-name wsi-bastion-user-logs --log-stream-name wsi-bastion-stream --limit 4 --query "events[*].{message:message}" --output text --start-from-head
echo

echo ----- 3-1 -----
aws s3 ls | grep -E "wsi-cc-data-"
echo

echo ----- 3-2 -----
BUCKET=$(aws s3api list-buckets --query "Buckets[?starts_with(Name, 'wsi-cc-data-')].Name" --output text) \
; aws s3 ls s3://$BUCKET/frontend/index.html
echo


echo ----- 4-1 -----
aws ec2 describe-instances --filter "Name=tag:Name,Values=wsi-control-plane" --query "Reservations[0].Instances[0].InstanceType" \
; CONTROL_PLANE_SUBNET=$(aws ec2 describe-instances --filter "Name=tag:Name,Values=wsi-control-plane" --query "Reservations[*].Instances[*].SubnetId" --output text) \
; aws ec2 describe-subnets --subnet-ids $CONTROL_PLANE_SUBNET --query "Subnets[*].Tags[?Key=='Name'].Value" --output text | grep wsi-private-a \
; INSTANCE_ID=$(aws ec2 describe-instances --filter "Name=tag:Name,Values=wsi-control-plane" --query "Reservations[*].Instances[*].InstanceId" --output text) \
; aws ec2 describe-instances --instance-ids $INSTANCE_ID --query "Reservations[*].Instances[*].IamInstanceProfile.Arn" --output text | grep wsi-control-plane-role
echo

echo ----- 4-2 -----
echo "2-mark.sh를 control instance에 실행합니다."
echo

echo ----- 4-3 -----
aws ec2 describe-instances --filter "Name=tag:Name,Values=wsi-control-plane" --query "Reservations[0].Instances[0].SecurityGroups[0].GroupName" \
; aws ec2 describe-security-groups --filter "Name=group-name,Values=wsi-control-plane-SG" --query "SecurityGroups[0].IpPermissions[].{FromPort:FromPort,ToPort:ToPort,IpRanges:IpRanges}"
echo

echo ----- 4-4A -----
echo "2-mark.sh를 control instance에 실행합니다."
echo


echo ----- 4-4B -----
echo "2-mark.sh를 control instance에 실행합니다."
echo

echo ----- 5-1 -----
aws ecr describe-repositories --query "repositories[*].repositoryName[]"
echo

echo ----- 5-2 -----
echo "2-mark.sh를 control instance에 실행합니다."
echo

echo ----- 6-1 -----
aws eks list-clusters --query "clusters[]" \
; aws eks describe-cluster --name wsi-cluster --region ap-northeast-2 --output json | jq -r '.cluster.logging.clusterLogging' \
; aws eks describe-cluster --name wsi-cluster --region ap-northeast-2 --output json | jq -r '.cluster.version' \
; aws eks list-nodegroups --cluster-name wsi-cluster --region ap-northeast-2 --output json | jq -r '.nodegroups'
echo

echo ----- 6-2 -----
echo "2-mark.sh를 control instance에 실행합니다."
echo

echo ----- 6-3 -----
echo "2-mark.sh를 control instance에 실행합니다."
echo

echo ----- 7-1 -----
echo "2-mark.sh를 control instance에 실행합니다."
echo

echo ----- 7-2 -----
echo "2-mark.sh를 control instance에 실행합니다."
echo

echo ----- 8-1 -----
LB_ARN=$(aws elbv2 describe-load-balancers --names wsi-alb --query 'LoadBalancers[0].LoadBalancerArn' --output text) \
; TARGET_GROUP_ARNS=$(aws elbv2 describe-target-groups --load-balancer-arn "$LB_ARN" --query 'TargetGroups[*].TargetGroupArn' --output text) \
; for TG_ARN in $TARGET_GROUP_ARNS; do
  echo "Target Group ARN: $TG_ARN"
  aws elbv2 describe-target-group-attributes --target-group-arn "$TG_ARN" --query 'Attributes[?Key==`load_balancing.algorithm.type`].Value' --output text
done \
; aws elbv2 describe-load-balancers --names wsi-alb --query 'LoadBalancers[0].Scheme' --output text
echo

echo ----- 8-2 -----
LB_DNS=$(aws elbv2 describe-load-balancers --names wsi-alb --query 'LoadBalancers[0].DNSName' --output text) \
; curl http://${LB_DNS}/ --max-time 10
echo

echo ----- 8-3 -----
LB_ARN=$(aws elbv2 describe-load-balancers --names wsi-alb --query 'LoadBalancers[0].LoadBalancerArn' --output text) \
; TARGET_GROUP_ARNS=$(aws elbv2 describe-target-groups --load-balancer-arn "$LB_ARN" --query 'TargetGroups[*].TargetGroupArn' --output text) \
; for TG_ARN in $TARGET_GROUP_ARNS; do
  echo "Target Group ARN: $TG_ARN"
  aws elbv2 describe-target-health --target-group-arn "$TG_ARN" --query 'TargetHealthDescriptions[*].{TargetId:Target.Id,State:TargetHealth.State}' --output text
done
echo

echo ----- 9-1 -----
aws rds describe-db-instances --query 'DBInstances[*].{DBInstanceIdentifier:DBInstanceIdentifier,DBInstanceClass:DBInstanceClass,Engine:Engine}' --output table
echo

echo ----- 10-1 -----
aws cloudfront list-tags-for-resource --resource "arn:aws:cloudfront::$(aws sts get-caller-identity --query Account --output text):distribution/${DistributionID}" --query "Tags.Items[?Key=='Name']" \
; aws cloudfront get-distribution --id ${DistributionID} --query "Distribution.DomainName"
echo