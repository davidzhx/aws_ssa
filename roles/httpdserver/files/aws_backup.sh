!#/bin/bash

load_date=$(date +'%Y-%m-%d-%H')

#backup and upload web contents to S3
tar czvf /tmp/web_content_${load_date}.tgz /var/www/html
#aws cli to s3
aws s3 cp /tmp/web_content_${load_date}.tgz s3://my-bucket-for-ssa
if [ $? = 0 ]; then 
	rm -rf /tmp/web_content_${load_date}.tgz
fi;

#create EC2 EBS snapshot and upload to S3 automatically
#For attached EBS volume as primary storage on EC2 instances
EC2_INSTANCE_ID=$(wget -q -O - http://169.254.169.254/latest/meta-data/instance-id)
EC2_VOLUME_ID=$(aws ec2 describe-volumes --filters Name=attachment.instance-id,Values=${EC2_INSTANCE_ID} | grep VolumeId | head -1 | cut -d":" -f2 | tr -d '\ ",')

if [ $? = 0 ]; then 
	#aws cli to take EBS snapshot
	aws ec2 create-snapshot --volume-id ${EC2_VOLUME_ID} --description "This is instance ${EC2_INSTANCE_ID} root volume snapshot"
	#use copy-snapshot to copy to another region if needed
	#aws ec2 copy-snapshot --source-region us-east-1 --source-snapshot-id snap-066877671789bd71b --encrypted --kms-key-id alias/my-kms-key
fi;

#create RDS snapshot annd upload to S3
aws rds create-db-snapshot --db-instance-identifier ssa-backend-db-a --db-snapshot-identifier ssa_db_snapshot_${load_date}
aws rds start-export-task --export-task-identifier my-snapshot-export-ssa-db_${load_date} --source-arn arn:aws:rds:ap-southeast-1:547311110462:snapshot:rds:ssa_db_snapshot_${load_date} \
    --s3-bucket-name my-bucket-for-ssa --iam-role-arn iam-role --kms-key-id alias/my-kms-key