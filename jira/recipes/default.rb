#
# Cookbook Name:: jira
# Recipe:: default
#
# Copyright 2008, OpsCode, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#     http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

#
# Manual Steps!
#
# MySQL:
#
#   create database jiradb character set utf8;
#   grant all privileges on jiradb.* to '$jira_user'@'localhost' identified by '$jira_password';
#   flush privileges;

include_recipe "runit"
include_recipe "java"
include_recipe "apache2"
include_recipe "apache2::mod_proxy"
include_recipe "apache2::mod_proxy_http"
include_recipe "apache2::mod_ssl"

unless FileTest.exists?(node[:jira_install_path])
  remote_file "jira" do
    path "/tmp/jira.tar.gz"
    source "http://www.atlassian.com/software/jira/downloads/binary/atlassian-jira-#{node[:jira_version]}-standalone.tar.gz"
  end
  
  bash "untar-jira" do
    code "(cd /tmp; tar zxvf /tmp/jira.tar.gz)"
  end
  
  bash "install-jira" do
    code "mv /tmp/atlassian-jira-#{node[:jira_version]}-standalone #{node[:jira_install_path]}"
  end
  
  if node[:jira_database] == "mysql"
    remote_file "mysql-connector" do
      path "/tmp/mysql-connector.tar.gz"
      source "http://dev.mysql.com/get/Downloads/Connector-J/mysql-connector-java-5.1.6.tar.gz/from/http://mysql.osuosl.org/"
    end
  
    bash "untar-mysql-connector" do
      code "(cd /tmp; tar zxvf /tmp/mysql-connector.tar.gz)"
    end
  
    bash "install-mysql-connector" do
      code "cp /tmp/mysql-connector-java-5.1.6/mysql-connector-java-5.1.6-bin.jar #{node[:jira_install_path]}/common/lib"
    end
  end
end

remote_file "#{node[:jira_install_path]}/bin/startup.sh" do
  source "startup.sh"
  owner "root"
  mode 0755
end
  
remote_file "#{node[:jira_install_path]}/bin/catalina.sh" do
  source "catalina.sh"
  owner "root"
  mode 0755
end

template "#{node[:jira_install_path]}/conf/server.xml" do
  source "server.xml.erb"
  owner "root"
  mode 0755
end
  
template "#{node[:jira_install_path]}/atlassian-jira/WEB-INF/classes/entityengine.xml" do
  source "entityengine.xml.erb"
  owner "root"
  mode 0755
end

runit_service "jira"

template "#{node[:apache_dir]}/sites-available/jira.conf" do
  source "apache.conf.erb"
  owner "root"
  mode 0644
end

apache_site "jira.conf"
