echo ------------------------------- 2024 전국기능경기대회 2과제 CICD 부분 채점기준표 -------------------------------
echo
echo
echo ------------------------------- 1-1 -------------------------------
echo
echo
aws codecommit get-repository --repository-name wsc2024-cci --query "repositoryMetadata.repositoryName"
echo
echo -------------------------------------------------------------------
echo
echo
echo ------------------------------- 1-2 -------------------------------
echo
aws codecommit get-folder --repository-name wsc2024-cci --commit-specifier master --folder-path / --region us-west-1 | grep Dockerfile'
echo
echo aws codepipeline start-pipeline-execution --name wsc2024-pipeline --region us-west-1
echo 출력된 결과에 Dockerfile이라는 문구가 없을 경우에 위에 명령어 실행
echo
echo -------------------------------------------------------------------
echo
echo
echo ------------------------------- 2-1 -------------------------------
echo
aws codebuild batch-get-projects --names wsc2024-cbd --query "projects[*].name"
echo
echo -------------------------------------------------------------------
echo
echo
echo ------------------------------- 3-1 -------------------------------
echo
   aws deploy get-application --application-name wsc2024-cdy --query "application.applicationName"
echo
echo -------------------------------------------------------------------
echo
echo
echo ------------------------------- 4-1 -------------------------------
echo
aws codepipeline get-pipeline --name wsc2024-pipeline --query "pipeline.name"
echo
echo -------------------------------------------------------------------
echo
echo
echo ------------------------------- 4-2 -------------------------------
echo
echo 수동 채점 필요함. *채점기준표 확인*
echo
echo -------------------------------------------------------------------
echo
echo
echo ------------------------------- 5-1 -------------------------------
echo
elb_dns=$(aws elbv2 describe-load-balancers --query "LoadBalancers[*].DNSName" --output text)
curl $elb_dns/healthcheck 
echo 
echo
echo -- 채점 종료 -- 충청남도 공주마이스터고
echo