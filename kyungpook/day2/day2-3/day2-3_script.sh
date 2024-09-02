#!/bin/bash

aws configure set default.region ap-northeast-2

echo =====1-1=====
aws ec2 describe-vpcs --filter Name=tag:Name,Values=wsi-vpc --query "Vpcs[].CidrBlock"
echo

echo =====1-2=====
aws ec2 describe-subnets --filter Name=tag:Name,Values=wsi-public-a --query "Subnets[].[AvailabilityZone, CidrBlock][]"
aws ec2 describe-subnets --filter Name=tag:Name,Values=wsi-public-b --query "Subnets[].[AvailabilityZone, CidrBlock][]"
aws ec2 describe-subnets --filter Name=tag:Name,Values=wsi-private-a --query "Subnets[].[AvailabilityZone, CidrBlock][]"
aws ec2 describe-subnets --filter Name=tag:Name,Values=wsi-private-b --query "Subnets[].[AvailabilityZone, CidrBlock][]"
echo

echo =====1-3=====
aws ec2 describe-route-tables --filter Name=tag:Name,Values=wsi-public-rtb --query "RouteTables[].Routes[].GatewayId"
aws ec2 describe-internet-gateways --filter Name=tag:Name,Values=wsi-igw --query "InternetGateways[].InternetGatewayId"
aws ec2 describe-route-tables --filter Name=tag:Name,Values=wsi-private-a-rtb --query "RouteTables[].Routes[].NatGatewayId"
aws ec2 describe-nat-gateways --filter Name=tag:Name,Values=wsi-nat-a --query "NatGateways[].NatGatewayId"
aws ec2 describe-route-tables --filter Name=tag:Name,Values=wsi-private-b-rtb --query "RouteTables[].Routes[].NatGatewayId"
aws ec2 describe-nat-gateways --filter Name=tag:Name,Values=wsi-nat-b --query "NatGateways[].NatGatewayId"
echo

echo =====2-1=====
aws ec2 describe-instances --filter Name=tag:Name,Values=wsi-bastion --query "Reservations[].Instances[].InstanceType"
echo

echo =====2-2=====
aws ec2 describe-instances --filter Name=tag:Name,Values=wsi-bastion --query "Reservations[].Instances[].PublicIpAddress"
aws ec2 describe-addresses --query "Addresses[].PublicIp"
echo

echo =====3-1=====
APP_PRIVATE_IP=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=wsi-app" --query "Reservations[*].Instances[*].PrivateIpAddress" --output text)
aws ec2 describe-instances --filters "Name=tag:Name,Values=wsi-app" --query "Reservations[*].Instances[*].PrivateIpAddress"
curl $APP_PRIVATE_IP:5000/log
echo

echo =====4-1=====
aws opensearch list-domain-names | grep wsi-opensearch
echo

OPENSEARCH_ENDPOINT=$(aws opensearch describe-domain --domain-name wsi-opensearch | jq -r '.DomainStatus.Endpoint')

echo =====4-2=====
aws opensearch describe-domain --domain-name wsi-opensearch --query "DomainStatus.ClusterConfig.[InstanceCount, DedicatedMasterCount]"
aws opensearch describe-domain --domain-name wsi-opensearch --query "DomainStatus.EngineVersion"
curl -s -u admin:Password01! "https://$OPENSEARCH_ENDPOINT/_cat/indices?v" | grep "app-log"
OPENSEARCH_ENDPOINT=$(aws opensearch describe-domain --domain-name wsi-opensearch | jq -r '.DomainStatus.Endpoint')
curl -s -u admin:Password01! https://$OPENSEARCH_ENDPOINT/app-log | jq '.["app-log"].mappings.properties | keys[]'
echo