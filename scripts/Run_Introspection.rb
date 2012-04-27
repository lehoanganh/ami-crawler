require 'logger'
require 'yaml'

load "Introspection.rb"

include Introspection

logger = Logger.new(STDOUT)

current_dir = File.dirname(__FILE__)
config_path = File.expand_path(current_dir + "/../input/configuration.yml")
amis = File.expand_path(current_dir + "/../output/intermediate/region_owner_free_unknown_amis.txt")
conf = YAML.load(File.open config_path)


logger.info "---------------------------------------------------------"
logger.info "Calling Introspection to get all JSON files"
logger.info "Introspection the AMIs in #{amis}"
logger.info "---------------------------------------------------------"

Introspection.introspect(logger,conf,amis)
