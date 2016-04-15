#!/usr/bin/env bash

# Variables
webserver_sg_name="webserver-sg"
dbserver_sg_name="dbserver-sg"
key_file_name="webapp-key"

# System variables
GREEN='\033[1;32m'
NC='\033[0m'

# Create aws security groups
echo -e "${GREEN}Creating aws security groups...${NC}"
webserver_sg_id="$(aws ec2 create-security-group --group-name ${webserver_sg_name} --description 'security group for web server' --output text)"
aws ec2 authorize-security-group-ingress --group-name ${webserver_sg_name} --protocol tcp --port 80 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-name ${webserver_sg_name} --protocol tcp --port 22 --cidr 0.0.0.0/0
dbserver_sg_id="$(aws ec2 create-security-group --group-name ${dbserver_sg_name} --description 'security group for database server' --output text)"
aws ec2 authorize-security-group-ingress --group-name ${dbserver_sg_name} --protocol tcp --port 3306 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-name ${dbserver_sg_name} --protocol tcp --port 22 --cidr 0.0.0.0/0

# Create aws key pair
echo -e "${GREEN}Creating aws key pair...${NC}"
if [ ! -f "~/${key_file_name}.pem" ]; then
  aws ec2 create-key-pair --key-name ${key_file_name} --query 'KeyMaterial' --output text > ~/${key_file_name}.pem
  chmod 400 ~/${key_file_name}.pem
fi

# Create ec2 instances
echo -e "${GREEN}Creating aws ec2 instances...${NC}"
webserver_instance_id="$(aws ec2 run-instances --image-id ami-f95ef58a --security-group-ids ${webserver_sg_id} --count 1 --instance-type t2.micro --key-name ${key_file_name} --query 'Instances[0].InstanceId' --output text)"
dbserver_instance_id="$(aws ec2 run-instances --image-id ami-f95ef58a --security-group-ids ${dbserver_sg_id} --count 1 --instance-type t2.micro --key-name ${key_file_name} --query 'Instances[0].InstanceId' --output text)"
webserver_public_ip="$(aws ec2 describe-instances --instance-ids ${webserver_instance_id} --query 'Reservations[0].Instances[0].PublicIpAddress' --output text)"
dbserver_public_ip="$(aws ec2 describe-instances --instance-ids ${dbserver_instance_id} --query 'Reservations[0].Instances[0].PublicIpAddress' --output text)"

# Wait for instances launch
echo -e "${GREEN}Waiting for instances launch...${NC}"
sleep 1m

# Bootstrap chef-client on both instances
echo -e "${GREEN}Bootstrap chef-clients...${NC}"
knife bootstrap ${webserver_public_ip} --ssh-user ubuntu --sudo --node-name webserver --identity-file ~/${key_file_name}.pem
knife bootstrap ${dbserver_public_ip} --ssh-user ubuntu --sudo --node-name dbserver --identity-file ~/${key_file_name}.pem

# Copy encrypted_data_bag_secret to nodes /etc/chef directory
echo -e "${GREEN}Copy encrypted_data_bag_secret...${NC}"
scp -q -i ~/${key_file_name}.pem .chef/encrypted_data_bag_secret ubuntu@${webserver_public_ip}:~/
ssh -i ~/${key_file_name}.pem ubuntu@${webserver_public_ip} "sudo mv ~/encrypted_data_bag_secret /etc/chef/encrypted_data_bag_secret"
scp -q -i ~/${key_file_name}.pem .chef/encrypted_data_bag_secret ubuntu@${dbserver_public_ip}:~/
ssh -i ~/${key_file_name}.pem ubuntu@${dbserver_public_ip} "sudo mv ~/encrypted_data_bag_secret /etc/chef/encrypted_data_bag_secret"

# Update nodes run lists
echo -e "${GREEN}Updating run lists...${NC}"
knife node run_list add webserver 'recipe[webapp::web]'
knife node run_list add dbserver 'recipe[webapp::database]'

# Run chef-clients
echo -e "${GREEN}Run chef-clients...${NC}"
ssh -i ~/${key_file_name}.pem ubuntu@${dbserver_public_ip} "sudo chef-client"
ssh -i ~/${key_file_name}.pem ubuntu@${webserver_public_ip} "sudo chef-client"

echo -e "${GREEN}Building complete!${NC}"
