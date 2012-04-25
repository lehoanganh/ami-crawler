# ====================================================================================================
# @author: Hoang Anh Le | me[at]lehoanganh[dot]de
#
# Filter use for ami_introspection
#
# ====================================================================================================
module Filter

  # INPUT: a list of all AMIs
  # OUT: a list of only FREE AMIs
  # Output File: #{input_path}/free.txt
  def getFreeAmis(amis)
    init()

    # get all AMIs, and call ec2-describe-images to retrieve meta data of all AMIs
    puts "Getting meta data of all AMIs in [amis.txt]..."
    tmp = ""
    File.open(amis,"r").each do |line|
      tmp += line.to_s.strip # delete the leading and the ending whitespace
      tmp += " "
    end
    puts "Saving meta data of all AMIs in [amis_meta_data_all].txt..."
    system "ec2-describe-images #{tmp} > #{@input_path}/amis_meta_data_all.txt"


    # analyze the meta data of all amis to get the only FREE AMIs
    # than save them in a text file
    puts "Analyzing the meta data to get only FREE AMIs..."
    str = ""
    if(!File.exist?(File.open("#{@input_path}/amis_meta_data_all.txt")))
      puts "[ERROR] File [amis_meta_data_all.txt] does NOT exist!"
      exit(1)
    end
    File.open("#{@input_path}/amis_meta_data_all.txt","r").each do |line|
      if (line.to_s.start_with? "IMAGE")
        # array variable, used to hold all information of the AMI in each iteration
        tmp	= []

        # one line ~ one AMI
        line.split("\t").each do |elem|
          tmp << elem
        end

        # detect this image is free
        # based on a call with ec2-describe-images
        # http://docs.amazonwebservices.com/AWSEC2/latest/CommandLineReference/ApiReference-cmd-DescribeImages.html
        if (tmp[6].length==0)
          puts "Checking AMI: #{tmp[1]}.... [FREE]"
          str += tmp[1]
          str += "\n"
        else
          puts "Checking AMI: #{tmp[1]}.... [COMMERCIAL]"
        end
      end
    end

    # finally, save all FREE AMIs in a text file
    puts "Saving all FREE AMIs in [free_amis].txt"
    f = File.open("#{@input_path}/free_amis.txt","w")
    f.write(str)
    f.close()
  end






  # INPUT: a list of all FREE AMIs, a list of all KNOWN AMIs
  # OUTPUT: a list of all FREE and UNKNOWN AMIs
  # Output file: #{input_path}/free_unknown_amis.txt
  def getUnknownAmis(free_amis, known_amis)
    init()

    puts "Comparing FREE AMIs with KNOWN AMIs to get the UNKNOWN AMIs..."

    puts "Retrieving all KNOWN AMIs from [known_amis].txt..."
    if (!File.exist?(File.open("#{@output_path}/known_amis.txt")))
      puts "[ERROR] File [known_amis.txt] does NOT exist"
      exit(1)
    end
    known = []
    File.open("#{@output_path}/known_amis.txt").each do |line|
      puts "KNOWN AMI: #{line.to_s.strip()}"
      known << line.to_s.strip()
    end
    puts "---> NOW, #{known.size} AMIs are already known"

    if(!File.exist?(File.open(free_amis)))
      puts "[ERROR] File [free_amis.txt] does NOT exist!"
      exit(1)
    end

    unknown = ""
    File.open(free_amis).each do |line|
      if known.include?(line.to_s.strip())
        puts "Checking AMI: #{line.to_s.strip()}....... [already KNOWN]"
      else
        puts "Checking AMI: #{line.to_s.strip()}....... [UNKNOWN]"
        puts "Adding AMI: #{line.to_s.strip()} to the list..."
        unknown += line.to_s.strip()
        unknown += "\n"
      end
    end

    puts "Saving all FREE and UNKNOWN AMIs to [free_unknown_amis.txt]..."
    f = File.open("#{@input_path}/free_unknown_amis.txt","w")
    f.write(unknown)
    f.close()
  end




  # INPUT: a list of all FREE and UNKNOWN AMIs
  # OUTPUT: a list of all FREE and UNKNOWN AMIs with a specific Platform
  # Output file: #{input_path}/free_unknown_os_amis.txt
  def getSpecificOSAmis(free_unknown,os)
    if(!File.exist?(File.open(free_unknown)))
      puts "[ERROR] File [free_unknown_amis.txt] does NOT exist"
      exit(1)
    end

    tmp = ""
    File.open(free_unknown,"r").each do |line|
      tmp += line.to_s.strip # delete the leading and the ending whitespace
      tmp += " "
    end

    # if the free, unknown list is empty
    if (tmp.length > 1)
      system "ec2-describe-images #{tmp} > #{@input_path}/amis_meta_data_os.txt"
      puts "Saving meta data of all AMIs in [amis_meta_data_os].txt..."

      puts "Analyzing meta data to get only AMIs with specific OS #{os}..."
      str = ""
      if(!File.exist?(File.open("#{@input_path}/amis_meta_data_os.txt")))
        puts "[ERROR] File [amis_meta_data_os.txt] does NOT exist!"
        exit(1)
      end
      File.open("#{@input_path}/amis_meta_data_os.txt","r").each do |line|
        if (line.to_s.start_with? "IMAGE")
          # array variable, used to hold all information of the AMI in each iteration
          tmp	= []

          # one line ~ one AMI
          line.split("\t").each do |elem|
            tmp << elem
          end

          # detect this image is free
          # based on a call with ec2-describe-images
          # http://docs.amazonwebservices.com/AWSEC2/latest/CommandLineReference/ApiReference-cmd-DescribeImages.html
          if (tmp[2].to_s.include?("#{os}"))
            puts "Checking AMI: #{tmp[1]}.... [#{os}]"
            str += tmp[1]
            str += "\n"
          else
            puts "Checking AMI: #{tmp[1]}.... [NOT #{os}]"
          end
        end
      end
    end

    # finally, save all  AMIs in a text file
    puts "Saving all FREE, UNKNOWN, OS SPECIFIC AMIs in [free_unknown_os_amis.txt].txt..."
    f = File.open("#{@input_path}/free_unknown_os_amis.txt","w")
    f.write(str)
    f.close()
  end





  private
  def init
    @current_dir = File.dirname(__FILE__)
    @input_path = File.expand_path(@current_dir + "/../input")
    puts "Input path: #{@input_path}"

    @output_path = File.expand_path(@current_dir + "/../output")
    puts "Output path: #{@output_path}"
  end

end