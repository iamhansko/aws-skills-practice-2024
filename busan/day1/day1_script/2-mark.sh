#!/bin/bash

# set default region of aws cli
aws configure set default.region ap-northeast-2
aws configure set default.output json

echo ----- 4-2 -----
awk -F: '{print $1}' /etc/passwd | grep '^user$'
awk -F: '{print $1}' /etc/passwd | grep dev
echo

echo ----- 5-2 -----
kubectl exec -it $(kubectl get pod -l wsi=skills -n skills --no-headers -o custom-columns=":metadata.name" | grep customer | head -n 1) -n skills -- curl -X GET "localhost:8080/healthcheck"
echo

echo ----- 6-2 -----
kubectl get pods -l wsi=skills -n skills --no-headers | wc -l
echo

echo ----- 6-3 -----
kubectl exec -it $(kubectl get pod -l wsi=skills -n skills --no-headers -o custom-columns=":metadata.name" | grep wsi-customer | head -n 1) -n skills -- curl -X GET "http://meister.hrdkorea.or.kr/main/main.do" --max-time 10
kubectl exec -it $(kubectl get pod -l wsi=skills -n skills --no-headers -o custom-columns=":metadata.name" | grep wsi-customer | head -n 1) -n skills -- curl -X GET "http://wsi-customer-service.skills.svc.cluster.local/healthcheck" --max-time 10
echo

echo ----- 7-1 -----
kubectl get deployment -n skills | grep wsi- | wc -l
echo

echo ----- 7-2 -----
kubectl get service -n skills | grep wsi- | wc -l
echo