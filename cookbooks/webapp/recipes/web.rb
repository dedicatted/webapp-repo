# Update apt cache.
include_recipe 'apt::default'

# Install MySQL client.
mysql_client 'default' do
  action :create
end

# Install apache2 and mod_php5.
include_recipe 'apache2::default'
include_recipe 'apache2::mod_php5'

# Install php5-mysql.
package 'php5-mysql' do
  action :install
end

# Create web application directory.
directory "#{node['app_dir']}" do
  owner 'root'
  group 'root'
  mode '0755'
  action :create
end

# Load the encrypted data bag item.
db_users = data_bag_item('db', 'users')

# Get database server object
db_server = search( :node, "name:dbserver" )[0]

# Create index.php page.
template "#{node['app_dir']}/index.php" do
  source 'index.php.erb'
  owner 'root'
  group 'root'
  mode '0644'
  variables({
    :db_server => "#{db_server['ec2']['public_hostname']}",
    :db_name => "#{node['db_name']}",
    :webuser_password => db_users['webuser_password']
  })
end

# Configure and enable apache2 site.
web_app "#{node['app_name']}" do
  template 'webapp.conf.erb'
  server_name node['fqdn']
  docroot "#{node['app_dir']}"
end
