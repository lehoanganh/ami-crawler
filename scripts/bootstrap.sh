#!/usr/bin/env bash
set -e
set -x

default_rubygems_version="1.8.22"
bootstrap_tar_url="http://s3.amazonaws.com/chef-solo/bootstrap-latest.tar.gz"

log()   { printf "===> $*\n" ; return $? ; }

fail()  { log "\nERROR: $*\n" ; exit 1 ; }

install_ruby_packages() {
	sudo apt-get update -y
	sleep 5
	sudo apt-get -y install ruby ruby-dev libopenssl-ruby rdoc ri irb build-essential wget ssl-cert
}

build_rubygems() {
  if gem --version | grep -q "${__rubygems_version}" >/dev/null ; then
    log "RubyGems ${__rubygems_version} is installed, so skipping..."
    return
  fi

  # Download and extract the source
  (cd /tmp && wget http://files.rubyforge.vm.bytemark.co.uk/rubygems/rubygems-${__rubygems_version}.tgz)
  (cd /tmp && tar xfz rubygems-${__rubygems_version}.tgz)

  # Setup and install
  (cd /tmp/rubygems-$__rubygems_version && ruby setup.rb --no-format-executable)

  # Clean up the source artifacts
  rm -rf /tmp/rubygems-${__rubygems_version}*
}

install_chef() {
  gem install ohai --no-ri --no-rdoc
  gem install chef --no-ri --no-rdoc
}

# Parse CLI arguments
while [[ $# -gt 0 ]] ; do
  token="$1"
  shift

  case "$token" in

    --rubygems-version|-r)
      case "$1" in
        *.*.*)
          __rubygems_version="$1"
          shift
          ;;
        *)
          fail "--rubygems-version must be followed by a version number x.y.z"
          ;;
      esac
      ;;

    help|usage)
      usage
      exit 0
      ;;

    *)
      usage
      exit 1
      ;;

  esac
done

if [[ -z "$__rubygems_version" ]] ; then
  __rubygems_version="$default_rubygems_version"
fi

# Perform the actual bootstrap

install_ruby_packages

build_rubygems

install_chef
