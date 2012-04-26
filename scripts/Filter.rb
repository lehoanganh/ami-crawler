# ====================================================================================================
# @author: Hoang Anh Le | me[at]lehoanganh[dot]de
#
# Filters, use for AMI Introspection
#
# GetFreeAmis: capture FREE AMIs from a list
# GetUnknownAmis: capture AMIs that are NOT KNOWN
# GetSpecificOSAmis: capture AMIs with a selected OS
#
# ====================================================================================================

module Filter

  public
  def start(logger,amis,os)

    init

    # check existence and emptiness of input
    if(!File.exist? amis)
      logger.error "#{amis} does NOT exist !!!"
      exit 1
    elsif(File.zero? amis)
      logger.error "#{amis} contains NOTHING !!!"
      exit 1
    end

    # get FREE AMIs
    free_amis = getFreeAmis(logger,amis)

    # get UNKNOWN AMIs
    known_amis = "#{@output_path}/known_amis.txt"
    # if no known_amis.txt -> create a new empty one
    if(!File.exist? known_amis)
      File.open(known_amis,"w") {}
    end
    free_unknown_amis = getUnknownAmis(logger,free_amis,known_amis)

    # get OS AMIs
    free_unknown_os_amis = getSpecificOSAmis(logger,free_unknown_amis,os)

    return free_unknown_os_amis
  end


  # INPUT: a list of all AMIs
  # OUTPUT: a list of only FREE AMIs
  # Output File: #{input_path}/free.txt
  private
  def getFreeAmis(logger, amis)
    # invoke FREE Filter to get only FREE AMIs -> #{input_path}/free_amis.txt
    logger.info "----------------------------------------------"
    logger.info "FREE filter is now being used to get FREE AMIs"
    logger.info "----------------------------------------------"

    # check existence and emptiness of input
    if(!File.exist? amis)
      logger.error "#{amis} does NOT exist !!!"
      exit 1
    elsif(File.zero? amis)
      logger.error "#{amis} contains NOTHING !!!"
      exit 1
    end

    # get all AMIs,
    # put them into an tmp var
    # in order to call ec2-describe-images to retrieve meta data of all AMIs
    logger.info "Getting meta data of all AMIs in [amis.txt]..."
    str = ""
    File.open(amis,"r").each do |line|
      str << line.to_s.strip << "\s" # delete the leading and the ending whitespace with strip method
    end
    str.chop # delete the last char (whitespace)

    # save all meta data into amis_meta_data_all.txt
    logger.info "Saving meta data of all AMIs in [amis_meta_data_all.txt]..."
     system "ec2-describe-images #{str} > #{@input_path}/amis_meta_data_all.txt"

    # check existence and emptiness
    if(!File.exist? "#{@input_path}/amis_meta_data_all.txt")
      logger.error "File [amis_meta_data_all.txt] does NOT exist !!!"
      exit 1
    elsif(File.zero? "#{@input_path}/amis_meta_data_all.txt")
      logger.error "File [amis_meta_data_all.txt] contains NOTHING !!!"
      exit 1
    end

    # analyze the meta data of all amis to get the only FREE AMIs
    # then save them in free_amis.txt
    logger.info "Analyzing the meta data to get only FREE AMIs..."
    free_amis = "#{@input_path}/free_amis.txt"
    File.open("#{free_amis}","w") do |file|
      File.open("#{@input_path}/amis_meta_data_all.txt","r").each do |line|
        if(line.to_s.start_with? "IMAGE")
          #array var, used to hold all info of the AMI in each iteration
          arr = []

          #one line ~ one AMI
          #split with tab character
          line.to_s.split("\t").each {|element| arr << element}

          #detect this image if it is free or commercial by checking the production code
          # http://docs.amazonwebservices.com/AWSEC2/latest/CommandLineReference/ApiReference-cmd-DescribeImages.html

          # if in this position there is nothing -> FREE AMI
          if(arr[6].length==0)
            logger.info "Checking AMI: #{arr[1]}...... [FREE]"
            file << arr[1] << "\n"
          else
            logger.info "Checking AMI: #{arr[1]}...... [COMMERCIAL]"
          end
        end
      end
    end

    return free_amis
  end





  # INPUT: a list of all FREE AMIs, a list of all KNOWN AMIs
  # OUTPUT: a list of all FREE and UNKNOWN AMIs
  # Output file: #{input_path}/free_unknown_amis.txt
  private
  def getUnknownAmis(logger, free_amis, known_amis)
    # invoke UNKNOWN Filter to get only UNKNOWN AMIs -> #{input_path}/free_unknown_amis.txt
    logger.info "-----------------------------------------------------------"
    logger.info "UNKNOWN filter is now being used to get FREE & UNKNOWN AMIs"
    logger.info "-----------------------------------------------------------"

    # check existence
    if(!File.exist? free_amis)
      logger.error "#{free_amis} does NOT exist !!!"
      exit 1
    end
    if(!File.exist? known_amis)
      logger.error "#{known_amis} does NOT exist !!!"
      exit 1
    end

    free_unknown_amis = "#{@input_path}/free_unknown_amis.txt"

    # if free_amis NOT EMPTY --> there is FREE AMIs detected
    if(!File.zero? free_amis)
      logger.info "Comparing FREE AMIs with KNOWN AMIs to get the UNKNOWN AMIs..."

      logger.info "Retrieving all KNOWN AMIs from [known_amis.txt]..."

      # known array contains all KNOWN AMIs for now
      known = []
      File.open("#{known_amis}","r").each do |line|
        logger.info "KNOWN AMI: #{line.to_s.strip}"
        known << line.to_s.strip
      end
      logger.info "FOR NOW, #{known.size} AMIs are already known"

      # iterate all FREE AMIs in free_amis.txt
      # check every one, if this one is already including in KNOWN array or not
      # if not, put it into free_unknown_amis.txt
      File.open("#{free_unknown_amis}","w") do |file|
        File.open(free_amis).each do |line|
          if known.include?(line.to_s.strip)
            logger.info "Checking AMI: #{line.to_s.strip}... [already KNOWN]"
          else
            logger.info "Checking AMI: #{line.to_s.strip}... [UNKNOWN]"
            logger.info "--> Adding AMI: #{line.to_s.strip} to the free_unknown_amis list"
            file << line.to_s.strip << "\n"
          end
        end
      end

      logger.info "Saving all FREE and UNKNOWN AMIs to [free_unknown_amis.txt]..."

    # the free_amis list is empty
    else
      File.open(free_unknown_amis,"w") {}
    end

    return free_unknown_amis
  end




  # INPUT: a list of all FREE and UNKNOWN AMIs
  # OUTPUT: a list of all FREE and UNKNOWN AMIs with a specific Platform
  # Output file: #{input_path}/free_unknown_os_amis.txt
  private
  def getSpecificOSAmis(logger, free_unknown_amis,os)
    # invoke OS Filter to get only AMIs with a SPECIFIC OS -> #{input_path}/free_unknown_os.txt
    logger.info "-------------------------------------------------------------------------"
    logger.info "OS filter is now being used to get FREE & UNKNOWN AMIs with a SPECIFIC OS"
    logger.info "-------------------------------------------------------------------------"

    # check existence and emptiness of input
    if(!File.exist? free_unknown_amis)
      logger.error "#{free_unknown_amis} does NOT exist !!!"
      exit 1
    end

    free_unknown_os_amis = "#{@input_path}/free_unknown_os_amis.txt"

    # if free_unknown_amis list is NOT EMPTY --> there is FREE, UNKNOWN AMIs detected
    if(!File.zero? free_unknown_amis)
      # capture all FREE, UNKNOWN AMIs in free_unknown_amis.txt
      # forward them to ec2-describe to detect the OS of each AMI
      str = ""
      File.open(free_unknown_amis,"r").each do |line|
        str << line.to_s.strip << "\s" # delete the leading and the ending whitespace
      end

      # if the free, unknown list is NOT empty
      # that means, there are AMIs to call ec2-describe-images
      # if not, ec2-describe-images returns all AMIs that you own
      if (str.length > 1)
        logger.info "Saving meta data of all AMIs in [amis_meta_data_os].txt..."
        system "ec2-describe-images #{str} > #{@input_path}/amis_meta_data_os.txt"
        if(!File.exist? "#{@input_path}/amis_meta_data_os.txt")
          logger.error "File [amis_meta_data_os.txt] does NOT exist !!!"
          exit(1)
        elsif(File.zero? "#{@input_path}/amis_meta_data_os.txt")
          logger.error "File [amis_meta_data_os.txt] contains NOTHIN !!!"
          exit(1)
        end

        logger.info "Analyzing meta data to get only AMIs with specific OS #{os}..."
        File.open(free_unknown_os_amis,"w") do |file|
          File.open("#{@input_path}/amis_meta_data_os.txt","r").each do |line|
            if(line.to_s.start_with? "IMAGE")
              #array var, used to hold all info of the AMI in each iteration
              arr = []

              #one line ~ one AMI
              #split with tab character
              line.to_s.split("\t").each {|element| arr << element}

              #detect this image if it is free or commercial by checking the production code
              # http://docs.amazonwebservices.com/AWSEC2/latest/CommandLineReference/ApiReference-cmd-DescribeImages.html

              if(arr[2].to_s.include?"#{os}")
                logger.info "Checking AMI: #{arr[1]}... [#{os}]"
                logger.info "--> Adding AMI: #{arr[1]} to the free_unknown_os_amis list"
                file << arr[1] << "\n"
              else
                logger.info "Checking AMI: #{arr[1]}... [NOT #{os}]"
              end
            end
          end
        end
      end

    # empty free_unknown_amis
    else
      File.open(free_unknown_os_amis,"w") {}
    end

    return free_unknown_os_amis
  end





  private
  def init
    @current_dir = File.dirname(__FILE__)
    @input_path = File.expand_path(@current_dir + "/../input")
    @output_path = File.expand_path(@current_dir + "/../output")
  end

end