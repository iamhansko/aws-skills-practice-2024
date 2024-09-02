echo -------------------------------  전국 기능경기대회 2과제 -----------------------------------

buckets=$(aws s3 ls | awk '{print $3}')
filtered_buckets=$(echo "$buckets")
bucket1=$(echo "$filtered_buckets" | head -n 1)
bucket2=$(echo "$filtered_buckets" | tail -n 1)

echo ------------------------------------------- 1-1-A -------------------------------------------

aws s3 ls 

echo ----------------------------------------------------------------------------------------------

echo ------------------------------------------- 1-2-A -------------------------------------------

echo “test” > test.txt
aws s3 cp test.txt s3://$bucket2/
aws s3 cp test.txt s3://$bucket2/2024/
aws s3 cp test.txt s3://$bucket1/
sleep 80

echo ----------------------------------------------------------------------------------------------

echo ------------------------------------------- 1-2-B -------------------------------------------

aws s3 cp test.txt s3://$bucket1/2024/

echo ----------------------------------------------------------------------------------------------

echo ------------------------------------------- 1-3-A -------------------------------------------

echo “copy” > copy.txt
aws s3 cp copy.txt s3://$bucket2/2024/
sleep 80

echo ----------------------------------------------------------------------------------------------

echo ------------------------------------------- 1-3-B -------------------------------------------

echo Manual

echo ----------------------------------------------------------------------------------------------

echo ------------------------------------------- 2-1-A -------------------------------------------

echo “check” > check.txt
aws s3 cp check.txt s3://$bucket2/2024/
sleep 80

echo ----------------------------------------------------------------------------------------------

echo ------------------------------------------- 2-1-B -------------------------------------------

echo Manual

echo ----------------------------------------------------------------------------------------------

echo ------------------------------------------- 2-1-C -------------------------------------------

echo Manual

echo ----------------------------------------------------------------------------------------------

echo ------------------------------------------- 2-2-A -------------------------------------------

echo Manual

echo ----------------------------------------------------------------------------------------------

echo ------------------------------------------- 2-2-B -------------------------------------------

echo Manual

echo ----------------------------------------------------------------------------------------------

echo ------------------------------------------- 3-1-A -------------------------------------------

echo Manual

echo ----------------------------------------------------------------------------------------------

echo ------------------------------------------- 4-1-A -------------------------------------------

echo Manual

echo ----------------------------------------------------------------------------------------------