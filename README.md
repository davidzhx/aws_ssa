Using the attached ansible playbook roles to deploy the SSA application to AWS 
This Ansible playbook includes roles for (including its security group):
- VPC
- EC2
- RDS (PostgreSQL)
- S3
- Httpdserver

This playbook spins up a VPC and create private and public subnets. An EC2 instance gets created in AZ a and b where Web app EC2 will be installed and placed in a public subnet for each AZ a and b. This public subnet will be accessible from the internet. Because the database must only be accessible from the EC2 instance and not from the outside world it is good practice to have it decoupled from the internet. On RDS, two postgres database instances get created for each AZ 1a (master) and 1b (replica) . They will be placed into a subnet group of three private subnets (from each AZ) allowing failover switches into another region in case of data center fail-outs for cross region AZ High Availability.
#1: Create an IAM User with Programmatic Access for each role of user with the listed IAM policies
A)	The Ansible roles VPC, RDS, EC2, and S3 need programmatic access to your AWS account. To do so generate a new IAM User with Programmatic access and attach the below policy list. You may not need the FullAccess types - feel free to limit the corresponding rights by shrinking them down to a minimum. If the user is not needed anymore delete it or just make the security key inactive.
IAM Users:
Cloud_admin:
AmazonVPCFullAccess
AmazonEC2FullAccess
AmazonEC2FullAccess

Web_admin:
ec2_only_access

DevOps:
AmazonRDSFullAccess
#2: Create A Key Pair
Within EC2 management console create a private key file and store it in a secure location. This key will allow Ansible to access the EC2 instance via SSH.
#3: Configure The Ansible Variables
You may want to configure the following variables first before running the play:
1 ./ansible.cfg: 
- Specify which inventory you want to use (development, staging, or production)
- Point to the private key file generated above

2 ./inventories/\< development \>/group_vars/all/credentials.yml:
- Specify the AWS credentials for the RDS database (username and password) and the generated access key and the corresponding secret.

3 ./inventories/\< development \>/group_vars/all/main.yml:
- Global variables for AWS which are used roles-wide like region, database settings, and S3 bucket name

4 ./roles/\<ec2|rds|s3|ssa|vpc|httpdserver\>/defaults/main.yml:
Each role has its own configuration. Check this variable definition if they fit your needs and change them if needed.

#4: Secure Your Credentials Using Ansible-vault (optional but recommended)
The AWS credentials access key/access secret and the RDS database username and password are stored as mentioned in ./inventories/< development >/group_vars/all/credentials.yml. It is strongly recommended to create an Ansible vault and encrypt this file instead of having the credentials in cleartext laying around.

#5: Run The Playbook With Asking For The Vaults Password** 
```bash
./site.yml --ask-vault-pass 
```
If the whole deployment went through successfully (takes up to 10–15 minutes) open your browser and open 
http://<public-dns-of-alb>:80
