# @author: me[at]lehoanganh[dot]de

require 'logger'
load "Filter.rb"
include Filter

# init logger
logger = Logger.new(STDOUT)

# welcome
logger.info "-----------------------------------------------------------------------------------"
logger.info "Welcome!"
logger.info "You're using now KIT Virtual Appliance Introspection (KVAI), developed by AIFB, KIT"
logger.info "Trace the logger to get the information you want to know!"
logger.info "1. Filter Phase"
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
logger.info "Checking [input/configuration.yml]... [OK]"



logger.info "---------------------------------------------------------"
logger.info "Step 2: Calling Filter to get all AMIs with user input..."
logger.info "---------------------------------------------------------"
Filter.filter(logger)