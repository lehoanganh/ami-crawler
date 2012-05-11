# @author: me[at]lehoanganh[dot]de

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

logger.info "---------------------------------------------------------"
logger.info "Calling Introspection to get all JSON files"
logger.info "Introspection the AMIs in #{Init::UNKNOWN_AMIS_FILE_PATH}"
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