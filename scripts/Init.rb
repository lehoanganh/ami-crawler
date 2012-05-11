# @author: me[at]lehoanganh[dot]de

# contains all important paths
module Init

  CURRENT_DIR = File.dirname(__FILE__)

  INPUT_FOLDER_PATH = File.expand_path(CURRENT_DIR + "/../input")
  CONFIGURATION_FILE_PATH = "#{INPUT_FOLDER_PATH}/configuration.yml"

  OUTPUT_FOLDER_PATH = File.expand_path(CURRENT_DIR + "/../output")
  TMP_FOLDER_PATH = "#{OUTPUT_FOLDER_PATH}/tmp"
  INTERMEDIATE_FOLDER_PATH = "#{OUTPUT_FOLDER_PATH}/intermediate"
  UNKNOWN_AMIS_FILE_PATH = "#{INTERMEDIATE_FOLDER_PATH}/region_owner_free_unknown_amis.txt"
  KNOWN_AMIS_FILE_PATH = "#{OUTPUT_FOLDER_PATH}/known_amis.txt"

end