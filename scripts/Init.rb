# @author: me[at]lehoanganh[dot]de

require 'logger'
require 'yaml'
require 'aws-sdk'

# contains
# all important paths
# initialize all important files if they do not exist
module Init

  # constants
  
  # folder paths
  CURRENT_DIR = File.dirname(__FILE__)
  INPUT_FOLDER_PATH = File.expand_path(CURRENT_DIR + "/../input")
  OUTPUT_FOLDER_PATH = File.expand_path(CURRENT_DIR + "/../output")

  # file paths
  CONFIGURATION_FILE_PATH = "#{INPUT_FOLDER_PATH}/configuration.yml"
  UNKNOWN_AMIS_FILE_PATH = "#{OUTPUT_FOLDER_PATH}/unknown_amis.txt"
  KNOWN_AMIS_FILE_PATH = "#{OUTPUT_FOLDER_PATH}/known_amis.txt"
  BAD_AMIS_FILE_PATH = "#{OUTPUT_FOLDER_PATH}/bad_amis.txt"
  


  
  protected
  def get_logger
    Logger.new(STDOUT)
  end
  
  
  
  protected
  def initialize_important_files
    if !(File.exist? UNKNOWN_AMIS_FILE_PATH)
      File.open(UNKNOWN_AMIS_FILE_PATH,'w') {}    
    elsif !(File.exist? KNOWN_AMIS_FILE_PATH)
      File.open(KNOWN_AMIS_FILE_PATH,'w') {}
    elsif !(File.exist? BAD_AMIS_FILE_PATH)
      File.open(BAD_AMIS_FILE_PATH,'w') {}
    end
  end



  protected
  def check_configuration_file

    # initialize logger
    logger = get_logger
    
    check = true
    if !(File.exist? CONFIGURATION_FILE_PATH)
      logger.error "File [input/configuration.yml] does NOT EXIST !"
      check = false
    elsif (File.zero? CONFIGURATION_FILE_PATH)
      logger.error "File [input/configuration.yml] is EMPTY !"
      check = false
    end
    
    if (!check)
      logger.info "Create a [input/configuration.yml] from the template [input/configuration.yml.tmpl]"
      logger.info "Checking [input/configuration.yml]... [FAILED]"
      logger.info "KVAI is stopping..."
      logger.info "-----------------------------------------------------------------------------------"
      exit 1
    end
    
    conf = get_configuration
    chunk_size = conf['chunk_size'].to_s.strip.to_i
    if !((1..10).include? chunk_size)
      logger.info "Chunk Size: #{chunk_size}"
      logger.info "Parameter chunk_size has to be set in range (1..10)"
      logger.info "KVAI is stopping..."
      logger.info "---------------------------------------------------"
      exit 1
    end
    
    logger.info "------------------------------------------"
    logger.info "Checking [input/configuration.yml]... [OK]"
    logger.info "------------------------------------------"
  end



  protected
  def get_configuration
    YAML.load(File.open CONFIGURATION_FILE_PATH)
  end

end