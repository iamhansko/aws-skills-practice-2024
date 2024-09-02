#!/bin/bash

# 환경 변수 설정
export DISTRIBUTION_ID="<Cloudfront_Distribution_ID>" # cloudfront distribution id
export STATIC_BUCKET="wsi-static-<4words>"
export CF_DOMAIN=$(aws cloudfront get-distribution --id ${DISTRIBUTION_ID} --query "Distribution.DomainName" | sed s/\"//g)
export LAMBDA_NAME="wsi-resizing-function"

# 사전 설정
echo "----- 사전 설정 중 -----"
aws configure set default.region ap-northeast-2
aws configure set default.output json
export INVALIDATION_ID=$(aws cloudfront create-invalidation --distribution-id ${DISTRIBUTION_ID} --paths "/*" --query "Invalidation.Id" | sed s/\"//g)
aws cloudfront wait invalidation-completed --distribution-id ${DISTRIBUTION_ID} --id ${INVALIDATION_ID}
echo "----- 사전 설정 완료 -----"

# 채점

# 1-1
echo "----- 1-1 -----"
aws s3 ls s3://${STATIC_BUCKET}/ --recursive | awk '{print $4}'
echo "---------------"

# 2-1
echo "----- 2-1 -----"
curl -s "https://${CF_DOMAIN}/images/library.jpg?width=400&height=400" | file -b - | grep -oE '[0-9]+x[0-9]+' | tail -n 1
echo "---------------"

# 2-2
echo "----- 2-2 -----"
curl -sIL -o /dev/null -w '%{url_effective}\n' https://${CF_DOMAIN}/dev/
curl -sIL -o /dev/null -w '%{url_effective}\n' https://${CF_DOMAIN}/
echo "---------------"

# 2-3
echo "----- 2-3 -----"
curl -sI "https://${CF_DOMAIN}/images/library.jpg?width=123&height=32" | grep -i "x-cache"
curl -sI "https://${CF_DOMAIN}/images/library.jpg?width=123&height=32" | grep -i "x-cache"
curl -sI "https://${CF_DOMAIN}/images/library.jpg?width=123&height=40" | grep -i "x-cache"
echo "---------------"

# 2-4
echo "----- 2-4 -----"
curl -sI "https://${CF_DOMAIN}/index.html" | grep -i "x-cache"
curl -sI "https://${CF_DOMAIN}/index.html" | grep -i "x-cache"
echo "---------------"

# 2-5
echo "----- 2-5 -----"
aws cloudfront get-distribution-config --id ${DISTRIBUTION_ID} --query "DistributionConfig.DefaultCacheBehavior.FunctionAssociations.Quantity > \`0\` || DistributionConfig.CacheBehaviors.Items[].FunctionAssociations.Quantity > \`0\`" --output text
echo "---------------"

# 2-6
echo "----- 2-6 -----"
aws lambda get-function-configuration --function-name ${LAMBDA_NAME} --region us-east-1 --query "Runtime" --output text
echo "---------------"