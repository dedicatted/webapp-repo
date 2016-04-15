node.default['apache']['mpm'] = 'prefork'

node.default['app_name'] = 'webapp'
node.default['app_dir'] = "/var/www/#{node['app_name']}"
node.default['db_name'] = "#{node['app_name']}"
