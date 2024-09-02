#!/bin/bash
# control plane 인스턴스에 user라는 사용자에서 진행합니다.

# set default region of aws cli
aws configure set default.region ap-northeast-2
aws configure set default.output json

echo ----- 4-4A -----
rm ~/.aws/credentials
ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)
aws sts assume-role --role-arn arn:aws:iam::${ACCOUNT_ID}:role/user --role-session-name user-session > credential.json
cat credential.json
echo

echo ----- 4-4B -----
AWS_ACCESS_KEY_ID=$(jq -r '.Credentials.AccessKeyId' credential.json)
AWS_SECRET_ACCESS_KEY=$(jq -r '.Credentials.SecretAccessKey' credential.json)
AWS_SESSION_TOKEN=$(jq -r '.Credentials.SessionToken' credential.json)
echo
export AWS_ACCESS_KEY_ID
export AWS_SECRET_ACCESS_KEY
export AWS_SESSION_TOKEN
aws sts get-caller-identity
aws eks update-kubeconfig --name wsi-cluster --region ap-northeast-2
kubectl get all -n skills
kubectl get all
kubectl delete deployment/wsi-customer-deployment -n skills
unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN
aws eks update-kubeconfig --name wsi-cluster --region ap-northeast-2
echo