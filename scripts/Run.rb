require "logger"
require "yaml"
load "Filter.rb"
load "Introspection.rb"
include Filter
include Introspection

current_dir = File.dirname(__FILE__)
input_path = File.expand_path(current_dir + "/../input")
output_path = File.expand_path(current_dir + "/../output")

# AWS Credentials
configuration = "#{input_path}/configuration.yml"

# all AMIs
amis = "#{input_path}/amis.txt"

# init Logger
logger = Logger.new(STDOUT)

# welcome
logger.info "-----------------------------------------------------------------------------------"
logger.info "Welcome!"
logger.info "You're using now KIT Virtual Appliance Introspection (KVAI), developed by AIFB, KIT"
logger.info "Trace the logger to get the information you want to know!"
logger.info "-----------------------------------------------------------------------------------"

logger.info "--------------------"
logger.info "Checking input files"
logger.info "--------------------"

# check existence and emptiness of amis.txt
logger.info "Checking [amis.txt]..."
if(!File.exist? amis)
  logger.error "#{amis} does NOT exist !!!"
  logger.error "Please create one !!!"
  logger.error "Each AMI in a line"
  logger.error "Checking [amis.txt]... [failed]"
  exit 1
elsif(File.zero? amis)
  logger.error "#{amis} contains NOTHING !!!"
  logger.error "Input your AMIs you want to introspect"
  logger.error "Each AMI in one line"
  logger.error "Checking [amis.txt]... [failed]"
  exit 1
end
logger.info "Checking [amis.txt]... [OK]"

# check existence and emptiness of configuration.yml
logger.info "Checking [configuration.yml]..."
if(!File.exist? configuration)
  logger.error "#{configuration} does NOT exist !!!"
  logger.error "Create one please !!!"
  logger.error "Checking [configuration.yml]... [failed]"
  exit 1
elsif(File.zero? configuration)
  logger.error "#{configuration} contains NOTHING !!!"
  logger.error "Input your AWS Credentials as follows"
  logger.error "access_key_id: [your access key id]"
  logger.error "secret_access_key: [your secret access key]"
  logger.error "owner_id: [the AMIs of the owner you want to detect]"
  logger.error "Checking [configuration.yml]... [failed]"
  exit 1
# not quite good formatted
elsif(!YAML.load(File.open "#{configuration}").kind_of?(Hash))
  logger.error "#{configuration} is not good FORMATTED"
  logger.error "Input your AWS Credentials as follows"
  logger.error "access_key_id: [your access key id]"
  logger.error "secret_access_key: [your secret access key]"
  logger.error "owner_id: [the AMIs of the owner you want to detect]"
  logger.error "Checking [configuration.yml]... [failed]"
  exit 1
end
logger.info "Checking [configuration.yml]... [OK]"

conf = YAML.load(File.open "#{configuration}")
owner = conf['os']

# START FILTER
logger.info "-------------------------"
logger.info "Using filters for #{amis}"
logger.info "-------------------------"
free_unknown_os_amis = Filter.start(logger,amis,os)

# FINALLY, call Introspection --> #{output_path}/known_amis.txt and JSON files
logger.info "-------------"
logger.info "Introspection"
logger.info "-------------"
Introspection.introspection(logger,free_unknown_os_amis)
