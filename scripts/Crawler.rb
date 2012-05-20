# @author: me[at]lehoanganh[dot]de

load "Introspection.rb"
include Introspection

# ================================

# get the logger from Module Init
logger = get_logger

# welcome
logger.info "-----------------------------------------------------------------------------------"
logger.info "Welcome!"
logger.info "You're using now KIT Virtual Appliance Introspection (KVAI), developed by AIFB, KIT"
logger.info "Version 0.5"
logger.info "Trace the logger to get the information you want to know!"
logger.info "-----------------------------------------------------------------------------------"

# initialize important files if these files do not exist
logger.info "-------------------------------"
logger.info "Initializing important files..."
logger.info "-------------------------------"
initialize_important_files

logger.info "----------------------------------"
logger.info "Checking the configuration file..."
logger.info "----------------------------------"
check_configuration_file

logger.info "-------------------------------------------------------------"
logger.info "If you want to use Filter Function --> Press (F)"
logger.info "Filter Function takes parameters in configuration file to get"
logger.info "... [FREE] AMIs"
logger.info "... with [MACHINE] as type"
logger.info "... with [PARAVIRTUAL] as virtualization type"
logger.info "... of the given [OWNER_ID]"
logger.info "... in the given [REGION]"
logger.info "... and AMIs are [UNKNOWN]"
logger.info ".... and [GOOD]"
logger.info "As output, you'll have [output/unknown_amis.txt]"
logger.info "-------------------------------------------------------------"

logger.info "---------------------------------------------------------------------------------------"
logger.info "If you want to use Introspection Function --> Press (I)"
logger.info "Introspection Function takes AMIs in [output/unknown_amis.txt]"
logger.info "... First, the AMIs are filtered with [output/known_amis.txt] and [output/bad_amis.txt]"
logger.info "... Second, the AMIs are introspected"
logger.info "As output, you'll have JSON files locally as well as in S3"
logger.info "---------------------------------------------------------------------------------------"

input = "dummy"

until ["F","I","Q"].include? input
  logger.info "-------------------------------------------------------"
  logger.info "So," 
  logger.info "press (F) for Filter"
  logger.info "press (I) for Introspection"
  logger.info "press (Q) to quit"
  logger.info "-------------------------------------------------------"
  
  # get input from user
  input = gets  
  input = input.chomp # delete the last enter character
end

if input == "F"
  logger.info "-----------------------------"
  logger.info "You've chosen Filter Function"
  logger.info "-----------------------------"
  filter

elsif input == "I"
	logger.info "------------------------------------"
  logger.info "You've chosen Introspection Function"
  logger.info "------------------------------------"
  introspect
  
elsif input == "Q"
  logger.info "---------------------"
  logger.info "OK, you want to quit!"
  logger.info "---------------------"
  exit 1
end