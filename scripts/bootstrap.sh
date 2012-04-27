#!/usr/bin/env bash
set -e
set -x

# @author: Le Hoang Anh | me[at]lehoanganh[dot]de
#
# --- DESCRIPTION ---
# The bootstrap script is used to bootstrap a Chef-Server on EC2 machine
# by using rubygems, chef-solo and some cookbooks to install chef-server
#
# --- USING ---
# 1. Transfer this script into the machine you want to set up chef-server
# 2. Login to the machine via ssh
# 3. Execute
# sudo bash bootstrap.sh
#
# --- COPYRIGHT ---
#
# Originally from https://github.com/fnichol/wiki-notes/wiki/Deploying-Chef-Server-On-Amazon-EC2
# Some parameters and configurations are modified to use with KCSD
#
# Another sources
# http://wiki.opscode.com/display/ChefCN/Bootstrap+Chef+RubyGems+Installation
# http://wiki.opscode.com/display/chef/Chef+Configuration+Settings
# http://rubygems.org/pages/download
#
# --- SPECIFICATIONS ---
# Ubuntu 11.10 x64 (e.g. ami-4dad7424 from alestic.com)
# Rubygems 1.8.22
# Chef latest
# 
# --- ATTENTION ---
# 1. If you change configurations and parameters below, the script may NOT work. 
# So, please do NOT! Just run it!
#
# 2. After setting up Chef Server sucessfully (hopefully :)), go to Chef Server Web UI
# in [chef-server-domain]:4040, login with username "admin" and password "p@ssw0rd1" 
#
# 3. Change the dummy password. Now!

default_rubygems_version="1.8.22"
bootstrap_tar_url="http://s3.amazonaws.com/chef-solo/bootstrap-latest.tar.gz"

install_ruby_packages() {
	apt-get update -y
	sleep 5
	apt-get -y install ruby ruby-dev libopenssl-ruby rdoc ri irb build-essential wget ssl-cert
}

build_rubygems() {
  if gem --version | grep -q "${default_rubygems_version}" >/dev/null ; then
    log "RubyGems ${default_rubygems_version} is installed, so skipping..."
    return
  fi

  # Download and extract the source
  (cd /tmp && wget http://production.cf.rubygems.org/rubygems/rubygems-${default_rubygems_version}.tgz)
  (cd /tmp && tar xfz rubygems-${default_rubygems_version}.tgz)

  # Setup and install
  (cd /tmp/rubygems-${default_rubygems_version} && ruby setup.rb --no-format-executable)

  # Clean up the source artifacts
  # rm -rf /tmp/rubygems-${default_rubygems_version}*
}

install_ohai() {
  gem install ohai --no-ri --no-rdoc
}

# Perform the actual bootstrap

install_ruby_packages

build_rubygems

install_ohai
