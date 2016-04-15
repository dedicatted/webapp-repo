# Web App provision

## Install pip
curl -O https://bootstrap.pypa.io/get-pip.py
sudo python get-pip.py

## Install awscli
sudo pip install awscli

## Add you settings to env variables
export AWS_ACCESS_KEY_ID=AKIAJCKOM3YEGLFGPZLQ
export AWS_SECRET_ACCESS_KEY=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
export AWS_DEFAULT_REGION=eu-west-1

## Install ChefDK
wget -q https://packages.chef.io/stable/ubuntu/12.04/chefdk_0.12.0-1_amd64.deb
sudo dpkg -i chefdk_0.12.0-1_amd64.deb

## Install git
sudo apt-get install -y git

## Clone the repo to your home folder
git clone https://github.com/dedicatted/webapp-repo.git ~/webapp-repo

## Cd to repo dir
cd ~/webapp-repo

## Create .chef directory
mkdir .chef

## Put to the .chef directory manage.chef.io files (user.pem, organization-validator.pem, knife.rb)

## Create secret file
openssl rand -base64 512 | tr -d '\r\n' > .chef/encrypted_data_bag_secret

## Create data bag
knife data bag create db

## Create encrypted data bag item with sample data
knife data bag from file db users.json --secret-file .chef/encrypted_data_bag_secret

## Edit encrypted data bag to update passwords (here you have to change the default passwords with the complex ones and exit the editor with save)
knife data bag edit db users --secret-file .chef/encrypted_data_bag_secret --editor=vi

## Run bootstrap.sh
./bootstrap.sh
