# Web App provision

### Install pip
```bash
curl -O https://bootstrap.pypa.io/get-pip.py
sudo python get-pip.py
```

### Install awscli
```bash
sudo pip install awscli
```

### Add you settings to env variables
```bash
export AWS_ACCESS_KEY_ID=AKIA_sample_ZLQ
export AWS_SECRET_ACCESS_KEY=iIFpw_sample_hiHl7h
export AWS_DEFAULT_REGION=eu-west-1
```

### Install ChefDK
```bash
wget -q https://packages.chef.io/stable/ubuntu/12.04/chefdk_0.12.0-1_amd64.deb
sudo dpkg -i chefdk_0.12.0-1_amd64.deb
```

### Install git
```bash
sudo apt-get install -y git
```

### Clone the repo to your home folder
```bash
git clone https://github.com/dedicatted/webapp-repo.git ~/webapp-repo
```

### Cd to repo dir
```bash
cd ~/webapp-repo
```

### Create .chef directory
```bash
mkdir .chef
```

### Put to the .chef directory manage.chef.io files (user.pem, organization-validator.pem, knife.rb)

### Create secret file
```bash
openssl rand -base64 512 | tr -d '\r\n' > .chef/encrypted_data_bag_secret
```

### Create data bag
```bash
knife data bag create db
```

### Create encrypted data bag item with sample data
```bash
knife data bag from file db users.json --secret-file .chef/encrypted_data_bag_secret
```

### Edit encrypted data bag to update passwords (here you have to change the default passwords with the complex ones and exit the editor with save)
```bash
knife data bag edit db users --secret-file .chef/encrypted_data_bag_secret --editor=vi
```

### If your AWS region is not 'us-east-1', replace the ami_image_id value with the correct one for your region in the bootstrap.sh file (line 6)

### Run bootstrap.sh
```bash
./bootstrap.sh
```

## Cleanup

### If something went wrong during bootstrap.sh run and you need a second try, you have to complete some manual cleanup steps.

### In the AWS management console:
1. Stop and terminate 'webserver' and 'dbserver' ec2 instances.
2. Delete 'webapp-key' key pair.
3. Delete 'webserver-sg' and 'dbserver-sg' EC2 security groups.

### In the Chef Manage console:
1. Delete 'webserver' and 'dbserver' nodes.

### On your workstation.
1. Delete ~/webapp-key.pem file.
