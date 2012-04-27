require 'yaml'
require 'logger'

load "Filter.rb"
load "Introspection.rb"

include Filter
include Introspection

#init logger
logger = Logger.new(STDOUT)

# welcome
logger.info "-----------------------------------------------------------------------------------"
logger.info "Welcome!"
logger.info "You're using now KIT Virtual Appliance Introspection (KVAI), developed by AIFB, KIT"
logger.info "Trace the logger to get the information you want to know!"
logger.info "-----------------------------------------------------------------------------------"

# important paths
current_dir = File.dirname(__FILE__)
input_path = File.expand_path(current_dir + "/../input")
output_path = File.expand_path(current_dir + "/../output")

# configuration
configuration_file_path = "#{input_path}/configuration.yml"

logger.info "----------------------"
logger.info "Checking user input..."
logger.info "----------------------"

logger.info "Checking [input/configuration.yml]..."

check = true
if(!File.exist? configuration_file_path)
  logger.error "File [input/configuration.yml] does NOT EXIST !"
  check = false
elsif(File.zero? configuration_file_path)
  logger.error "File [input/configuration.yml] is EMPTY !"
  check = false
end

if(!check)
  logger.error "Create a new one as follows"

  logger.error "access_key_id: [your access key id]"
  logger.error "secret_access_key: [your secret access key]"
  logger.error "owner_id: [the AMIs of the owner you want to detect]"
  logger.error "region: [the AMIs in the region you want to detect]"

  logger.info "Checking [input/configuration.yml]... [FAILED]"

  exit 1
end
logger.info "Checking [input/configuration.yml]... [OK]"

# parse configuration file
configuration = YAML.load(File.open configuration_file_path)

logger.info "---------------------------------------------------------"
logger.info "Calling Filter to get all AMIs with following user input"
logger.info "---------------------------------------------------------"

# use filter
region_owner_free_unknown_amis_path = Filter.filter(logger,configuration)

#logger.info "---------------------------------------------------------"
#logger.info "Calling Introspection to get all JSON files"
#logger.info "---------------------------------------------------------"
#region_owner_free_unknown_amis_path = "#{output_path}/intermediate/region_owner_free_unknown_amis.txt"
## use introspection
#Introspection.introspect(logger,configuration,region_owner_free_unknown_amis_path)
