# Update apt cache.
include_recipe 'apt::default'

# Configure the mysql2 Ruby gem.
mysql2_chef_gem 'default' do
  action :install
end

# Configure the MySQL client.
mysql_client 'default' do
  action :create
end

# Load the encrypted data bag item.
db_users = data_bag_item('db', 'users')

# Configure the MySQL service.
mysql_service 'default' do
  initial_root_password db_users['root_password']
  action [:create, :start]
end

# Create the database instance.
mysql_database "#{node['db_name']}" do
  connection(
    :host => '127.0.0.1',
    :username => 'root',
    :password => db_users['root_password']
  )
  action :create
end

# Get web server object
web_server = search( :node, "name:webserver" )[0]

# Add a database user.
mysql_database_user 'webuser' do
  connection(
    :host => '127.0.0.1',
    :username => 'root',
    :password => db_users['root_password']
  )
  password db_users['webuser_password']
  database_name "#{node['db_name']}"
  host "#{web_server['fqdn']}"
  action [:create, :grant]
end

# Write sample sql data file to filesystem.
cookbook_file '/tmp/insert-sample-data.sql' do
  source 'insert-sample-data.sql'
  owner 'root'
  group 'root'
  mode '0600'
end

# Initialize database with a table and sample data.
execute 'initialize database' do
  command "mysql -h 127.0.0.1 -u root -p'#{db_users['root_password']}' -D #{node['db_name']} < /tmp/insert-sample-data.sql"
  not_if  "mysql -h 127.0.0.1 -u root -p'#{db_users['root_password']}' -D #{node['db_name']} -e 'describe goods;'"
end
