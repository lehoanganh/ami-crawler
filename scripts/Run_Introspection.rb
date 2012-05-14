# @author: me[at]lehoanganh[dot]de

require 'yaml'

load "Introspection.rb"
include Introspection

# init logger
logger = Logger.new(STDOUT)

# welcome
logger.info "-----------------------------------------------------------------------------------"
logger.info "Welcome!"
logger.info "You're using now KIT Virtual Appliance Introspection (KVAI), developed by AIFB, KIT"
logger.info "Trace the logger to get the information you want to know!"
logger.info "2. Introspection Phase"
logger.info "-----------------------------------------------------------------------------------"



logger.info "------------------------------"
logger.info "Step 1: Checking user input..."
logger.info "------------------------------"

logger.info "Checking [input/configuration.yml]..."
check = true
if(!File.exist? Init::CONFIGURATION_FILE_PATH)
  logger.error "File [input/configuration.yml] does NOT EXIST !"
  check = false
elsif(File.zero? Init::CONFIGURATION_FILE_PATH)
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

# check chunk size
conf = YAML.load(File.open Init::CONFIGURATION_FILE_PATH)
chunk_size = conf['chunk_size'].to_s.strip.to_i
if(!((1..10).include? chunk_size))
  logger.error "Chunk Size: #{chunk_size}"
  logger.error "Parameter chunk_size has to be set in range (1..10)"
  exit 1
end

logger.info "Checking [input/configuration.yml]... [OK]"



logger.info "---------------------------------------------------------"
logger.info "Step 2: Calling Introspection to get all JSON files"
logger.info "Introspect the AMIs in #{Init::UNKNOWN_AMIS_FILE_PATH}"
logger.info "---------------------------------------------------------"

# a DUMMY introspection
#
# read all AMIs from output/intermediate/region_owner_free_unknown_amis.txt
# and write to output/known_amis.txt
#
# assumption, all AMIs are introspected successfully
# use to check the filter function
#Introspection.dummyIntrospect

# a SERIOUS introspection
Introspection.introspect(logger)