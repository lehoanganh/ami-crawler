module Filter

  protected
  def filter(logger, configuration)

    region = configuration['region']
    owner_id = configuration['owner_id']

    logger.info "-------------------"
    logger.info "Starting filters..."
    logger.info "-------------------"

    # init, to get all paths
    initFilter

    # FIRST, call Region, Owner, Free AMIs filter
    region_owner_free_amis_path = getRegionOwnerFreeAmis(logger, region, owner_id)

    # SECOND, call Unknown AMIs filter
    # if known_amis does not exist -> create a new empty one
    known_amis_path = "#{@output_path}/known_amis.txt"
    if (!File.exist? known_amis_path)
      File.open(known_amis_path, "w") {}
    end
    region_owner_free_unknown_amis_path = getUnknownAmis(logger, region_owner_free_amis_path, known_amis_path)

    # return
    logger.info "-------------------------"
    logger.info "Ending filters..."
    logger.info "Return the final AMI list"
    logger.info "-------------------------"
    return region_owner_free_unknown_amis_path
  end


  # INPUT: Region, Owner_ID
  # OUTPUT: all Free AMIs in given Region with Owner_ID
  # OUTPUT FILE: output/intermediate/region_owner_free_amis.txt
  private
  def getRegionOwnerFreeAmis(logger, region, owner_id)

    # NOTICE:
    # region has to be correct
    # owner_id has to be correct

    logger.info "-----------------------------------------"
    logger.info "Using Region-Owner-Free filter to get"
    logger.info "FREE AMIs of given OWNER in given REGION "
    logger.info "-----------------------------------------"

    logger.info "Getting AMIs with a given Region, Owner ID from AWS..."
    meta_data_region_owner_path = "#{@tmp_path}/meta_data_region_owner.txt"
    system "ec2dim --show-empty-fields --owner #{owner_id}  --region #{region} > #{meta_data_region_owner_path}"

    logger.info "Parsing the meta data to get only FREE AMIs..."


    if(File.zero? meta_data_region_owner_path)
      logger.error "No meta data for AMIs in Region: #{region} of Owner ID: #{owner_id}"
      logger.error "Ensure the Region and OwnerID are correct"
      logger.error "Or maybe there are no AMIs"
      exit 1
    end

    region_owner_free_amis_path = "#{@intermediate_path}/region_owner_free_amis.txt"
    free_amis_counter = 0
    str = ""
    File.open(region_owner_free_amis_path, "w") do |file|
      File.open(meta_data_region_owner_path, "r").each do |line|
        if (line.to_s.start_with? "IMAGE")
          # holds all info for each AMI in each iteration
          arr = []

          # get all info of the AMI
          # split a line with tab character
          line.to_s.split("\t").each { |ele| arr << ele.to_s.strip }

          #detect this image if it is free or commercial by checking the production code
          # http://docs.amazonwebservices.com/AWSEC2/latest/CommandLineReference/ApiReference-cmd-DescribeImages.html
          if (arr[6].to_s.include? "nil")
            logger.info "Checking AMI #{arr[1]}... [FREE]"
            logger.info "-----> Adding this AMI #{arr[1]} to the list..."
            free_amis_counter += 1
            str << arr[1] << "\n"
          else
            logger.info "Checking AMI #{arr[1]}... [COMMERCIAL]"
          end
        end
      end
      file.write(str.strip)
    end

    logger.info "----------------------------------------------------------"
    logger.info "Found #{free_amis_counter} FREE AMIs"
    logger.info "With OWNER: #{owner_id}"
    logger.info "In REGION: #{region}"
    logger.info "Saving [output/intermediate/region_owner_free_amis.txt]..."
    logger.info "----------------------------------------------------------"
    return region_owner_free_amis_path

  end






  # INPUT: AMIs, KNOWN AMIs
  # OUTPUT: UNKNOWN AMIs
  # OUTPUT FILE: output/intermediate/region_owner_free_unknown_amis.txt
  private
  def getUnknownAmis(logger, amis, known_amis)

    logger.info "---------------------------"
    logger.info "Using Unknown filter to get"
    logger.info "UNKNOWN AMIs"
    logger.info "---------------------------"

    # check existence and emptiness of amis
    if (!File.exist? amis)
      logger.error "#{amis} does NOT EXIST !"
      exit 1
    elsif(File.zero? amis)
      logger.error "#{amis} is EMPTY"
      logger.error "That means, there are no FREE AMIs at all"
      exit 1
    end

    # check existence of known_amis
    if (!File.exist? known_amis)
      logger.error "#{known_amis} does NOT EXIST !"
      exit 1
    end


    logger.info "Getting KNOWN AMIs from [output/known_amis.txt]..."

    # known amis array contains all KNOWN AMIs
    known_amis_array = []
    File.open(known_amis, "r").each do |line|
      known_amis_array << line.to_s.strip # strip: delete the first and the last whitespace
    end
    logger.info "Now, we have #{known_amis_array.size} KNOWN AMIs"

    logger.info "Check [output/region_owner_free_amis.txt]"
    logger.info "and compare the AMIs with KNOWN AMIs to get UNKNOWN AMIs"

    # iterate the region_owner_free_amis
    # check if AMI exist already in known_amis
    # YES -> ignore
    # NO -> write to region_owner_free_unknown_amis
    unknown_amis_counter = 0
    region_owner_free_unknown_amis_path = "#{@intermediate_path}/region_owner_free_unknown_amis.txt"
    str = ""
    File.open(region_owner_free_unknown_amis_path, "w") do |file|
      File.open(amis, "r").each do |ami|
        if (!known_amis_array.include? ami.to_s.strip)
          unknown_amis_counter += 1
          logger.info "Checking AMI #{ami.to_s.strip}... [UNKNOWN]"
          logger.info "-----> Adding AMI #{ami.to_s.strip} to the list"
          str << ami.to_s.strip << "\n"
        else
          logger.info "Checking AMI #{ami.to_s.strip}... [already KNOWN]"
        end
      end
      file.write(str.strip)
    end

    logger.info "............................................................."
    logger.info "Found #{unknown_amis_counter} UNKNOWN AMIs"
    logger.info "Saving [output/intermediate/region_owner_free_unknown.txt]..."
    logger.info "............................................................."

    return region_owner_free_unknown_amis_path
  end


  private
  def initFilter
    @current_dir = File.dirname(__FILE__)
    @input_path = File.expand_path(@current_dir + "/../input")
    @output_path = File.expand_path(@current_dir + "/../output")
    @intermediate_path = "#{@output_path}/intermediate"
    @tmp_path = "#{@output_path}/tmp"
  end


end