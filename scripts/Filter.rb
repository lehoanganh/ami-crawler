# @author: me[at]lehoanganh[dot]de

load "Init.rb"
include Init

module Filter

  protected
  def filter

    # get logger
    logger = get_logger

    # get configuration
    configuration = get_configuration
    access_key_id = configuration['access_key_id']
    secret_access_key = configuration['secret_access_key']
    region = configuration['region']
    owner_id = configuration['owner_id']
    
    logger.info "--------------------------------------------------------------------------------"
    logger.info "Using Region-Owner-Free-Machine Filter to get"
    logger.info "...[FREE] AMIs with [MACHINE] type of the given [OWNER_ID] in the given [REGION]"
    logger.info "Please wait..."
    logger.info "--------------------------------------------------------------------------------"
    region_owner_free_machine_amis = get_region_owner_free_machine_amis(access_key_id, secret_access_key,region, owner_id) 
    logger.info "-------------------------------------------------"
    logger.info "After Region-Owner-Free-Machine Filter"
    logger.info "Found #{region_owner_free_machine_amis.size} AMIs"
    logger.info "-------------------------------------------------"

    logger.info "--------------------------------"
    logger.info "Using Unknown-Good Filter to get"
    logger.info "...[UNKNOWN] and [GOOD] AMIs"
    logger.info "Please wait..."
    logger.info "--------------------------------"
    unknown_good_amis = get_unknown_good_amis(region_owner_free_machine_amis)
    logger.info "------------------------------------"
    logger.info "After Unknown-Good Filter"
    logger.info "Found #{unknown_good_amis.size} AMIs"
    logger.info "------------------------------------"

    # save
    logger.info "-------------------------------------------------------------------"
    logger.info "Ending filters..."
    logger.info "Return the final AMI list in [output/unknown_amis.txt]"
    File.open(UNKNOWN_AMIS_FILE_PATH,'w') do |file|
      unknown_good_amis.each {|ami| file << ami << "\n"}
    end
    logger.info "-------------------------------------------------------------------"
  end


  # INPUT: region, owner_id
  # OUTPUT: array of amis in the given region, with given owner_id, have machine type and are free
  protected
  def get_region_owner_free_machine_amis(access_key_id, secret_access_key, region, owner_id)
    
    # results array
    region_owner_free_machine_amis = []
    
    # create an EC2 object for the given REGION
    ec2 = AWS::EC2.new(:access_key_id => access_key_id,
                       :secret_access_key => secret_access_key,
                       :ec2_endpoint => "ec2.#{region}.amazonaws.com")
    
    # filter with OWNER ID
    ec2.images.with_owner(owner_id).each do |img|
      
      # filter with MACHINE and FREE
      if (img.type == :machine) && (img.product_codes.size == 0)
        region_owner_free_machine_amis << img.id
      end  
    end
    
    region_owner_free_machine_amis    
  end


  
  # INPUT: array of amis
  # OUTPUT: array of amis that are unknown and good
  protected
  def get_unknown_good_amis(checking_amis)

    logger = get_logger
    
    # results array
    unknown_good_amis = []
    
    # assign
    unknown_good_amis = checking_amis
    
    # delete duplicates
    unknown_good_amis = unknown_good_amis.uniq

    # check emptiness of checking_amis
    if (unknown_good_amis.size == 0)
      logger.info "-----------------------------------"
      logger.info "There are NO AMIs to filter at all!"
      logger.info "KVAI is stopping..."
      logger.info "-----------------------------------"
      exit 1
    end
    
    # [output/known_amis.txt] synchronized with S3    
    synchronize_known_amis_with_s3

    logger.info "---------------------------------------------------------"

    # contains all KNOWN AMIs
    known_amis = []
    File.open(KNOWN_AMIS_FILE_PATH,'r').each {|line| known_amis << line.to_s.strip}
    known_amis = known_amis.uniq
    logger.info "We have #{known_amis.size} KNOWN AMIs"

    # filter with KNOWN AMIs
    known_amis.each do |ami|
      if unknown_good_amis.include? ami
        unknown_good_amis.delete ami
      end
    end
    
    logger.info "After KNOWN Filter we have #{unknown_good_amis.size} AMIs"
    logger.info "---------------------------------------------------------"

    logger.info "---------------------------------------------------------"

    # contains all BAD AMIs
    bad_amis = []
    File.open(BAD_AMIS_FILE_PATH,'r').each {|line| bad_amis << line.to_s.strip}
    bad_amis = bad_amis.uniq
    logger.info "We have #{bad_amis.size} BAD AMIs"
    
    # filter with BAD AMIs    
    bad_amis.each do |ami|
      if unknown_good_amis.include? ami
        unknown_good_amis.delete ami
      end
    end

    logger.info "After GOOD Filter we have #{unknown_good_amis.size} AMIs"
    logger.info "---------------------------------------------------------"

    unknown_good_amis    
  end
  
  
  
  private
  def synchronize_known_amis_with_s3
    
    # get configuration parameters
    conf = get_configuration
    access_key_id = conf['access_key_id']
    secret_access_key = conf['secret_access_key']
    region = conf['region']
    
    # create a S3 object
    s3 = AWS::S3.new(:access_key_id => access_key_id, :secret_access_key => secret_access_key)
    
    # contains all ami names
    amis = []
    
    # search if there is data in S3 with corresponding region
    s3.buckets.each do |bucket|
      
      # found the corresponding bucket
      if bucket.name == "#{access_key_id.downcase}-#{region}"
      
        # iterate all objects in the bucket
        bucket.objects.each {|object| amis << object.key.to_s.strip[/ami-\w*/]}
      
        # delete duplicates
        amis = amis.uniq
    
      end
    
    end

    # update [output/known_amis.txt]        
    File.open(KNOWN_AMIS_FILE_PATH,'w') do |file|
      amis.each {|ami| file << ami << "\n"}
    end
    
  end

end