#!/bin/bash

# Export
aws configure set default.region ap-northeast-2
aws configure set default.output json


echo =====1-1=====
aws ec2 describe-vpcs --filter Name=tag:Name,Values=hrdkorea-vpc --query "Vpcs[0].CidrBlock" 
aws ec2 describe-subnets --filter Name=tag:Name,Values=hrdkorea-public-sn-a --query "Subnets[0].CidrBlock" 
aws ec2 describe-subnets --filter Name=tag:Name,Values=hrdkorea-public-sn-b --query "Subnets[0].CidrBlock" 
aws ec2 describe-subnets --filter Name=tag:Name,Values=hrdkorea-private-sn-a --query "Subnets[0].CidrBlock" 
aws ec2 describe-subnets --filter Name=tag:Name,Values=hrdkorea-private-sn-b --query "Subnets[0].CidrBlock" 
aws ec2 describe-subnets --filter Name=tag:Name,Values=hrdkorea-protect-sn-a --query "Subnets[0].CidrBlock" 
aws ec2 describe-subnets --filter Name=tag:Name,Values=hrdkorea-protect-sn-b --query "Subnets[0].CidrBlock"
echo
aws ec2 describe-vpcs --filter Name=tag:Name,Values=hrdkorea-vpc --query "Vpcs[0].CidrBlock" --region us-east-1 
aws ec2 describe-subnets --filter Name=tag:Name,Values=hrdkorea-public-sn-a --query "Subnets[0].CidrBlock" --region us-east-1 
aws ec2 describe-subnets --filter Name=tag:Name,Values=hrdkorea-public-sn-b --query "Subnets[0].CidrBlock" --region us-east-1 
aws ec2 describe-subnets --filter Name=tag:Name,Values=hrdkorea-private-sn-a --query "Subnets[0].CidrBlock" --region us-east-1 
aws ec2 describe-subnets --filter Name=tag:Name,Values=hrdkorea-private-sn-b --query "Subnets[0].CidrBlock" --region us-east-1 
aws ec2 describe-subnets --filter Name=tag:Name,Values=hrdkorea-protect-sn-a --query "Subnets[0].CidrBlock" --region us-east-1 
aws ec2 describe-subnets --filter Name=tag:Name,Values=hrdkorea-protect-sn-b --query "Subnets[0].CidrBlock" --region us-east-1
echo

echo =====1-2=====
aws ec2 describe-route-tables --filter Name=tag:Name,Values=hrdkorea-private-a-rt --query "RouteTables[].Routes[].NatGatewayId" | grep "nat-" | wc -l
aws ec2 describe-route-tables --filter Name=tag:Name,Values=hrdkorea-private-b-rt --query "RouteTables[].Routes[].NatGatewayId" | grep "nat-" | wc -l
aws ec2 describe-route-tables --filter Name=tag:Name,Values=hrdkorea-public-rt --query "RouteTables[].Routes[]" | grep "igw-" | wc -l
aws ec2 describe-route-tables --filter Name=tag:Name,Values=hrdkorea-protect-b-rt --query "RouteTables[].Routes[]" | grep -E "igw-|nat-" | wc -l
echo
aws ec2 describe-route-tables --filter Name=tag:Name,Values=hrdkorea-private-a-rt --query "RouteTables[].Routes[].NatGatewayId" --region us-east-1 | grep "nat-" | wc -l
aws ec2 describe-route-tables --filter Name=tag:Name,Values=hrdkorea-private-b-rt --query "RouteTables[].Routes[].NatGatewayId" --region us-east-1 | grep "nat-" | wc -l
aws ec2 describe-route-tables --filter Name=tag:Name,Values=hrdkorea-public-rt --query "RouteTables[].Routes[]" --region us-east-1 | grep "igw-" | wc -l
aws ec2 describe-route-tables --filter Name=tag:Name,Values=hrdkorea-protect-b-rt --query "RouteTables[].Routes[]" --region us-east-1| grep -E "igw-|nat-" | wc -l
echo

echo =====2-1=====
aws ec2 describe-instances --filter Name=tag:Name,Values=hrdkorea-bastion --query "Reservations[].Instances[].InstanceId"
aws ec2 describe-instances --filter Name=tag:Name,Values=hrdkorea-bastion --query "Reservations[].Instances[].InstanceId" --region us-east-1
echo
aws ec2 describe-instances --filter Name=tag:Name,Values=hrdkorea-bastion --query "Reservations[].Instances[].InstanceType"
aws ec2 describe-instances --filter Name=tag:Name,Values=hrdkorea-bastion --region us-east-1 --query "Reservations[].Instances[].InstanceType"
echo
Seoul_IMAGE_ID=$(aws ec2 describe-instances --filter Name=tag:Name,Values=hrdkorea-bastion --query "Reservations[].Instances[].ImageId" --output text)
US_IMAGE_ID=$(aws ec2 describe-instances --filter Name=tag:Name,Values=hrdkorea-bastion --query "Reservations[].Instances[].ImageId" --output text --region us-east-1)
aws ec2 describe-images --image-ids $Seoul_IMAGE_ID --query "Images[].Description"
aws ec2 describe-images --image-ids $US_IMAGE_ID --query "Images[].Description" --region us-east-1
echo

echo =====3-1=====
aws dynamodb list-tables --query "TableNames[?@ == 'order']"
aws dynamodb list-tables --query "TableNames[?@ == 'order']" --region us-east-1
echo
aws dynamodb describe-table --table-name order --query "Table.BillingModeSummary.BillingMode"
aws dynamodb describe-table --table-name order --query "Table.BillingModeSummary.BillingMode" --region us-east-1
echo

echo =====4-1=====
aws rds describe-db-clusters --query "DBClusters[0].{Engine:Engine,Port:Port,MasterUsername:MasterUsername}"
aws rds describe-db-clusters --query "DBClusters[0].{Engine:Engine,Port:Port,MasterUsername:MasterUsername}" --region us-east-1
echo
aws rds describe-db-instances --db-instance-identifier hrdkorea-rds-instance --query "DBInstances[0].{Engine:Engine,DBInstanceStatus:DBInstanceStatus,DBInstanceClass:DBInstanceClass,StorageType:StorageType}"
aws rds describe-db-instances --db-instance-identifier hrdkorea-rds-instance-us --query "DBInstances[0].{Engine:Engine,DBInstanceStatus:DBInstanceStatus,DBInstanceClass:DBInstanceClass,StorageType:StorageType}" --region us-east-1
echo

echo =====5-1=====
aws ecr describe-repositories --repository-name hrdkorea-ecr-repo --query "repositories[].repositoryName"
echo

echo =====5-2=====
aws ecr describe-image-scan-findings --repository-name hrdkorea-ecr-repo --image-id imageTag=customer --query "imageScanStatus.status"
aws ecr describe-image-scan-findings --repository-name hrdkorea-ecr-repo --image-id imageTag=product --query "imageScanStatus.status"
aws ecr describe-image-scan-findings --repository-name hrdkorea-ecr-repo --image-id imageTag=order --query "imageScanStatus.status"
echo

echo =====5-3=====
aws ecr list-images --repository-name hrdkorea-ecr-repo --query "imageIds[].imageTag"
aws ecr list-images --repository-name hrdkorea-ecr-repo --query "imageIds[].imageTag" --region us-east-1
echo
aws ecr describe-registry --query "replicationConfiguration.rules[0].destinations[0].region"
echo

echo =====6-1=====
aws s3api list-buckets --query "Buckets[].Name"
BUCKET_NAME=$(aws s3api list-buckets --query "Buckets[].Name" --output text)
aws s3 ls s3://$BUCKET_NAME/static/
echo

echo =====7-1=====
aws eks describe-cluster --name hrdkorea-cluster --query "cluster.version"
aws eks describe-cluster --name hrdkorea-cluster --query "cluster.version" --region us-east-1
echo 

echo =====7-2=====
aws eks describe-cluster --name hrdkorea-cluster --query "cluster.logging.clusterLogging"
aws eks describe-cluster --name hrdkorea-cluster --query "cluster.logging.clusterLogging" --region us-east-1
echo 

echo =====7-3=====
aws eks describe-nodegroup --cluster-name hrdkorea-cluster --nodegroup-name hrdkorea-customer-ng --query "nodegroup.instanceTypes"
aws eks describe-nodegroup --cluster-name hrdkorea-cluster --nodegroup-name hrdkorea-customer-ng --query "nodegroup.instanceTypes" --region us-east-1
echo 

echo =====7-4=====
aws eks describe-fargate-profile --cluster-name hrdkorea-cluster --fargate-profile-name hrdkorea-addon-profile --query "fargateProfile.fargateProfileName"
aws eks describe-fargate-profile --cluster-name hrdkorea-cluster --fargate-profile-name hrdkorea-addon-profile --query "fargateProfile.fargateProfileName" --region us-east-1
echo

echo =====7-5=====
POD_NAME=$(kubectl get pods -n hrdkorea | grep customer | awk '{print $1}' | head -n 1)
NODE_NAME=$(kubectl get po  $POD_NAME -n hrdkorea -o jsonpath='{.spec.nodeName}')
NODE_GROUP=$(kubectl get node $NODE_NAME --show-labels | grep -o 'hrdkorea-customer-ng')
echo "$NODE_GROUP"
echo
POD_NAME=$(kubectl get pods -n hrdkorea | grep product | awk '{print $1}' | head -n 1)
NODE_NAME=$(kubectl get po  $POD_NAME -n hrdkorea -o jsonpath='{.spec.nodeName}')
NODE_GROUP=$(kubectl get node $NODE_NAME --show-labels | grep -o 'hrdkorea-product-ng')
echo "$NODE_GROUP"
echo 
POD_NAME=$(kubectl get pods -n hrdkorea | grep order | awk '{print $1}' | head -n 1)
NODE_NAME=$(kubectl get po  $POD_NAME -n hrdkorea -o jsonpath='{.spec.nodeName}')
NODE_GROUP=$(kubectl get node $NODE_NAME --show-labels | grep -o 'hrdkorea-order-ng')
echo "$NODE_GROUP"
echo

echo =====8-1=====
aws elbv2 describe-load-balancers --names hrdkorea-app-alb --query "LoadBalancers[].LoadBalancerName"
aws elbv2 describe-load-balancers --names hrdkorea-app-alb --query "LoadBalancers[].LoadBalancerName" --region us-east-1
aws elbv2 describe-load-balancers --names hrdkorea-app-alb --query "LoadBalancers[].Scheme"
aws elbv2 describe-load-balancers --names hrdkorea-app-alb --query "LoadBalancers[].Scheme" --region us-east-1
echo

echo =====8-2=====
SEOUL_ALB_ADDRESS=$(aws elbv2 describe-load-balancers --query "LoadBalancers[?LoadBalancerName=='hrdkorea-app-alb'].DNSName" --output text)
US_ALB_ADDRESS=$(aws elbv2 describe-load-balancers --query "LoadBalancers[?LoadBalancerName=='hrdkorea-app-alb'].DNSName" --output text --region us-east-1)
curl -o /dev/null -s -w "%{http_code}\n" http://$SEOUL_ALB_ADDRESS/healthcheck?path=skills
echo 
curl http://$SEOUL_ALB_ADDRESS/healthcheck?path=customer
echo  
curl http://$SEOUL_ALB_ADDRESS/healthcheck?path=order
echo 
curl http://$SEOUL_ALB_ADDRESS/healthcheck?path=product
echo
curl -o /dev/null -s -w "%{http_code}\n" http://$US_ALB_ADDRESS/healthcheck?path=skills
echo
curl http://$US_ALB_ADDRESS/healthcheck?path=customer
echo
curl http://$US_ALB_ADDRESS/healthcheck?path=order
echo
curl http://$US_ALB_ADDRESS/healthcheck?path=product
echo

echo =====9-1=====
aws resourcegroupstaggingapi get-resources --tag-filters Key=Name,Values=hrdkorea-cdn --resource-type-filters 'cloudfront' --region us-east-1 --query "ResourceTagMappingList[0].ResourceARN" --output text | sed 's:.*/::' | xargs -I {} aws cloudfront get-distribution --id {} --query "Distribution.DomainName" --output text
aws resourcegroupstaggingapi get-resources --tag-filters Key=Name,Values=hrdkorea-cdn --resource-type-filters 'cloudfront' --region us-east-1 --query "ResourceTagMappingList[0].ResourceARN" --output text | sed 's:.*/::' | xargs -I {} aws cloudfront get-distribution --id {} --query "Distribution.DistributionConfig.PriceClass"
echo 

echo =====9-2=====
CLOUDFRONT_DNS=$(aws resourcegroupstaggingapi get-resources --tag-filters Key=Name,Values=hrdkorea-cdn --resource-type-filters 'cloudfront' --region us-east-1 --query "ResourceTagMappingList[0].ResourceARN" --output text | sed 's:.*/::' | xargs -I {} aws cloudfront get-distribution --id {} --query "Distribution.DomainName" --output text)
curl --silent --head https://$CLOUDFRONT_DNS/static/index.html | grep "x-cache"
aws resourcegroupstaggingapi get-resources --tag-filters Key=Name,Values=hrdkorea-cdn --resource-type-filters 'cloudfront' --region us-east-1 --query "ResourceTagMappingList[0].ResourceARN" --output text | sed 's:.*/::' | xargs -I {} aws cloudfront get-distribution --id {} --query "Distribution.DistributionConfig.Origins.Items[*].DomainName" | grep "hrdkorea-static-"
aws resourcegroupstaggingapi get-resources --tag-filters Key=Name,Values=hrdkorea-cdn --resource-type-filters 'cloudfront' --region us-east-1 --query "ResourceTagMappingList[0].ResourceARN" --output text | sed 's:.*/::' | xargs -I {} aws cloudfront get-distribution --id {} --query "Distribution.DistributionConfig.Origins.Items[*].DomainName" | grep "hrdkorea-app-alb-"
echo 

echo =====10-1=====
CLOUDFRONT_DNS=$(aws resourcegroupstaggingapi get-resources --tag-filters Key=Name,Values=hrdkorea-cdn --resource-type-filters 'cloudfront' --region us-east-1 --query "ResourceTagMappingList[0].ResourceARN" --output text | sed 's:.*/::' | xargs -I {} aws cloudfront get-distribution --id {} --query "Distribution.DomainName" --output text)
curl -X POST -H "Content-type: application/json" -d '{"id":"cloud","name":"user","gender":"man"}' https://$CLOUDFRONT_DNS/v1/customer
echo
curl -X GET https://$CLOUDFRONT_DNS/v1/customer?id=cloud
echo

echo =====10-2=====
CLOUDFRONT_DNS=$(aws resourcegroupstaggingapi get-resources --tag-filters Key=Name,Values=hrdkorea-cdn --resource-type-filters 'cloudfront' --region us-east-1 --query "ResourceTagMappingList[0].ResourceARN" --output text | sed 's:.*/::' | xargs -I {} aws cloudfront get-distribution --id {} --query "Distribution.DomainName" --output text)
curl -X POST -H "Content-type: application/json" -d '{"id":"cloud","name":"user","category":"stduent"}' https://$CLOUDFRONT_DNS/v1/product
echo
curl -X GET https://$CLOUDFRONT_DNS/v1/product?id=cloud
echo

echo =====10-3=====
CLOUDFRONT_DNS=$(aws resourcegroupstaggingapi get-resources --tag-filters Key=Name,Values=hrdkorea-cdn --resource-type-filters 'cloudfront' --region us-east-1 --query "ResourceTagMappingList[0].ResourceARN" --output text | sed 's:.*/::' | xargs -I {} aws cloudfront get-distribution --id {} --query "Distribution.DomainName" --output text)
curl -X POST -H "Content-type: application/json" -d '{"id":"cloud","customerid":"user","productid":"skills"}' https://$CLOUDFRONT_DNS/v1/order
echo
curl -X GET https://$CLOUDFRONT_DNS/v1/order?id=cloud
echo 

echo =====11-1=====
echo "콘솔에서 채점을 진행합니다"
echo 

echo =====11-2=====
echo "콘솔에서 채점을 진행합니다"
echo

echo =====12-1=====
echo "수동으로 채점을 진행합니다"
echo

echo =====12-2=====
echo "수동으로 채점을 진행합니다"
echo 

echo =====12-3=====
echo "수동으로 채점을 진행합니다"
echo

echo "재채점 요구 시 Deployment를 재생성 후 재채점을 진행합니다."