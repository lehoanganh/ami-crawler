# @author: me[at]lehoanganh[dot]de

require 'rubygems'

require 'json'
gem 'json', '~> 1.7.3'

require 'yaml'

require 'aws-sdk'
gem 'aws-sdk', '~> 1.5.2'

require 'net/ssh'
gem 'net-ssh', '~> 2.4.0'

require 'thread'

require 'logger'
# gem 'logger', '~> 1.2.8'

# include JSON

load 'Filter.rb'
include Filter

module Introspection

  public
  def introspect
    
    logger = get_logger



    # validate input
    if !(File.exist? UNKNOWN_AMIS_FILE_PATH)
      logger.info "------------------------------------------"
      logger.info "#{UNKNOWN_AMIS_FILE_PATH} does NOT EXIST !"
      logger.info "KVAI is stopping..."
      logger.info "------------------------------------------"
      exit 1
    elsif (File.zero? UNKNOWN_AMIS_FILE_PATH)
      logger.info "--------------------------------------------"
      logger.info "#{UNKNOWN_AMIS_FILE_PATH} contains NOTHING !"
      logger.info "That means, there is NOTHING to introspect"
      logger.info "KVAI is stopping..."
      logger.info "--------------------------------------------"
      exit 1
    end



    # contains all AMIs that should be introspected
    introspect_amis = []
    File.open(UNKNOWN_AMIS_FILE_PATH,'r').each {|line| introspect_amis << line.to_s.strip}
    introspect_amis = introspect_amis.uniq

    logger.info "----------------------------------------------"
    logger.info "AMIs in [output/unknown_amis.txt]"
    logger.info "We have #{introspect_amis.size} AMIs"
    logger.info "----------------------------------------------"




    logger.info "------------------------------"
    logger.info "Calling Unknown-Good Filter..."
    introspect_amis = get_unknown_good_amis(introspect_amis)
    logger.info "------------------------------"
    
    # nothing to introspect
    if(introspect_amis.size == 0)
      logger.info "----------------------------"
      logger.info "No new AMIs to introspect..."
      logger.info "KVAI is stopping..."
      logger.info "----------------------------"
      exit 1
    end




    # get the configuration parameters
    config = get_configuration
    chunk_size = config['chunk_size'].to_s.strip.to_i
    owner_id = config['owner_id'].to_s.strip
    @region = config['region'].to_s.strip
    region_dir = "#{OUTPUT_FOLDER_PATH}/regions/#{@region}"
    @access_key_id = config['access_key_id'].to_s.strip
    @secret_access_key = config['secret_access_key'].to_s.strip
    key_pair_name = config['key_pair'].to_s.strip
    group_name = config['group'].to_s.strip
    login_users = config['login_users'].to_s.strip.split(",")

    # ec2 object
    @ec2 = AWS::EC2.new(
        :access_key_id => "#{@access_key_id}",
        :secret_access_key => "#{@secret_access_key}",
        :ec2_endpoint => "ec2.#{@region}.amazonaws.com"
    )
    
    # s3 object
    @s3 = AWS::S3.new(
        :access_key_id => "#{@access_key_id}",
        :secret_access_key => "#{@secret_access_key}"
    )



    # all already KNOWN AMIs in an array
    # this array will be updated later
    @known_amis = []
    File.open(KNOWN_AMIS_FILE_PATH,'r').each {|line| @known_amis << line.to_s.strip}
    @known_amis = @known_amis.uniq

    # all BAD AMIs in an array
    # this array will be updated later
    @bad_amis = []
    File.open(BAD_AMIS_FILE_PATH,'r').each {|line| @bad_amis << line.to_s.strip}
    @bad_amis = @bad_amis.uniq



    # START INTROSPECTING
    logger.info "------------------------------------------"
    logger.info "The key pair will be used: #{key_pair_name}"
    logger.info "The security group will be used: #{group_name}"
    logger.info "------------------------------------------"

    # init
    @key_pair = @group = nil



    logger.info "------------------------"
    logger.info "Checking the key pair..."
    
    private_key_path = "#{CURRENT_DIR}/#{key_pair_name}.pem"

    if (File.exist? private_key_path)
      logger.info "Deleting the old [PRIVATE] key in client side..."
      File.delete private_key_path
    end
    if !(@ec2.key_pairs[key_pair_name].nil?)
      logger.info "Deleting the old [PUBLIC] key in server side..."
      @ec2.key_pairs[key_pair_name].delete
    end
    
    logger.info "Creating a new key pair #{key_pair_name}"
    @key_pair = @ec2.key_pairs.create("#{key_pair_name}")

    # save the private key
    File.open(private_key_path,'w') {|file| file << @key_pair.private_key}

    # only user can read/write
    system "chmod 600 #{private_key_path}"
    logger.info "------------------------"



    logger.info "------------------------------"
    logger.info "Checking the security group..."

    # existing a security group already
    check = false
    @ec2.security_groups.each do |gr|
      if (gr.name == "#{group_name}")
        check = true
        logger.info "Security group #{group_name} exists in EC2 Environment"
        logger.info "Retrieving the security group from EC2"
        @group = gr
      end
    end

    # do not exist in EC2 => create a new one
    if (!check)
      logger.info "Create a new security group #{group_name}"
      @group = @ec2.security_groups.create("#{group_name}")
      @group.authorize_ingress(:tcp, 22, "0.0.0.0/0")
    end
    logger.info "------------------------------"



    logger.info "----------------------"
    logger.info "Start introspecting..."
    logger.info "----------------------"

    # TAKE chunk by chunk
    while (introspect_amis.size > 0)

      # delete old stuff of the last SSH connections
      delete_old_known_hosts

      # get a chunk
      chunk = introspect_amis.pop chunk_size

      # multithreaded
      threads = []

      # mutex
      @mutex = Mutex.new

      # a hash map, ami => instance
      # key: ami is a string
      # value: instance is a string
      @ami_instance_map = Hash.new

      logger.info "------------------------------------------"
      logger.info "Step 1: Launching ALL AMIs in the CHUNK..."
      chunk.each {|ami| logger.info "--- AMI: #{ami}"}
      logger.info "------------------------------------------"

      # create threads
      chunk.each do |ami|
        thread = create_thread_launch(ami)
        threads << thread
      end
      threads.each {|thread| thread.join}
      
      # update [output/bad_amis.txt]
      File.open(BAD_AMIS_FILE_PATH,'w') do |file|
        @bad_amis.each {|bad_ami| file << bad_ami << "\n"}        
      end  

      #a small pause
      logger.info "Please wait a little moment..."
      sleep 20
      
      # INTROSPECT each running instance
      logger.info "--------------------------------------------------------------------"
      logger.info "Step 2: Introspecting EACH RUNNING instance for AMIs in the CHUNK..."
      logger.info "--------------------------------------------------------------------"

      @ami_instance_map.each do |ami,instance|
        
        logger.info "----------------------------------------------------"
        logger.info "Try to introspect:"
        logger.info "AMI: #{ami}"
        logger.info "Its corresponding Instance: #{instance.id}"
        logger.info "----------------------------------------------------"

        private_key_file = File.open private_key_path
        instance_ip = instance.ip_address

        check = false

        # try to find the correct login_user for the instance
        login_users.each do |user|
          user = user.to_s.strip

          logger.info "-------------------------------------------------------"
          logger.info "Try 5 times to make a SSH connection with user: #{user}"
          logger.info "-------------------------------------------------------"

          counter = 0

          begin

            Net::SSH.start(instance_ip, user, :keys => [private_key_file]) do |ssh|

              logger.info "Connection for user: #{user} is OK"
              logger.info "Do Introspection now"



              logger.info "Uploading script..."
              if(user=="root")
                system "scp -i #{private_key_path} introspect.sh #{user}@#{instance_ip}:/#{user}"
              else
                system "scp -i #{private_key_path} introspect.sh #{user}@#{instance_ip}:/home/#{user}"
              end



              logger.info "Running script..."
              # bug: ssh.exec! always hangs. So sad!!!
              # logger.info ssh.exec!("bash $HOME/introspect.sh")
              system "ssh -i #{private_key_path} #{user}@#{instance_ip} 'bash $HOME/introspect.sh'"



              logger.info "Downloading results..."

              files = []
              prefix = "#{region_dir}/#{owner_id}-#{ami}"
              files << "#{prefix}-package_manager_info"
              files << "#{prefix}-ohai_info.json"
              files << "#{prefix}-package_manager_info.json"

              if(user=="root")
                system "scp -i #{private_key_path} #{user}@#{instance_ip}:/#{user}/package_manager_info.txt #{files[0]}"
                system "scp -i #{private_key_path} #{user}@#{instance_ip}:/#{user}/ohai_info.json #{files[1]}"
              else
                system "scp -i #{private_key_path} #{user}@#{instance_ip}:/home/#{user}/package_manager_info.txt #{files[0]}"
                system "scp -i #{private_key_path} #{user}@#{instance_ip}:/home/#{user}/ohai_info.json #{files[1]}"
              end



              logger.info "Parsing results..."
              software_parser("#{files[0]}")



              # save into S3
              logger.info "Uploading to S3..."
              bucket = @s3.buckets.create("#{@access_key_id.downcase}-#{@region}")
              logger.info "...into bucket: #{@access_key_id.downcase}-#{@region}"
              files.each do |file_path|
                basename = File.basename file_path
                logger.info "-- Uploading: #{basename}"
                object = bucket.objects[basename]
                object.write(:file => file_path)
              end

              # OK, don't repeat
              check = true
            end

          rescue Errno::ECONNREFUSED,Net::SSH::AuthenticationFailed, SystemCallError, Timeout::Error => e
            if ( counter == 5 )
              logger.info "-----------------------------------------------------------------------------------"
              logger.info "5 times already to try to build a SSH connection to the instance with user: #{user}"
              logger.info "Not successful!!!"
              logger.info "Try the next login user"
              logger.info "-----------------------------------------------------------------------------------"
            else

              # increment counter
              counter += 1
              logger.info "Please wait for #{counter}. try..."

              # sleep 4 second
              sleep 3

              # next try
              retry
            end
          end

          if check
            logger.info "We have the infos we want. Kill the instance: #{instance.id}"
            instance.terminate

            logger.info "Updating #{ami} in [output/known_amis.txt]..."

            # prevent duplicate
            if !(@known_amis.include? ami)
              File.open(KNOWN_AMIS_FILE_PATH,'a') {|file| file << ami.to_s.strip << "\n"}
            end

            break
          end
        end



        # can not build a SSH connection with all given login users
        if !check
          logger.info "Something wrong with the Instance: #{instance.id} of the AMI: #{ami}"
          logger.info "The program can not build a SSH connection to the Instance: #{instance.id}"
          logger.info "Kill the instance: #{instance.id}"
          instance.terminate
          
          logger.info "AMI: #{ami} is written in [output/bad_amis.txt]..."
          File.open(BAD_AMIS_FILE_PATH,'a') {|file| file << ami.to_s.strip << "\n"}
        end
      end

    end



    logger.info "-------------------"
    logger.info "Ended Introspection"
    logger.info "-------------------"
  end




  private
  def create_thread_launch(ami)

    thread = Thread.new do
      
      logger = get_logger

      # every thread has an own ec2 object
      ec2 = AWS::EC2.new(
        :access_key_id => "#{@access_key_id}",
        :secret_access_key => "#{@secret_access_key}",
        :ec2_endpoint => "ec2.#{@region}.amazonaws.com"
      )

      # get the ami object
      # image = nil
      # @mutex.synchronize do
        # image = @ec2.images[ami]
      # end

      # get the ami object
      image = ec2.images[ami]

      # instance_store does not support t1.micro
      machine_type = nil
      if (image.root_device_type == :instance_store)
        machine_type = "m1.medium"
      else
        machine_type = "t1.micro"
      end

      # launch
      logger.info "-- An Instance for this AMI #{ami} is being launched..."
      # instance = nil
      # @mutex.synchronize do
        # instance = image.run_instance(:key_pair => @key_pair,
                                      # :security_groups => @group,
                                      # :instance_type => machine_type)
      # end

      instance = image.run_instance(:key_pair => @key_pair,
                                      :security_groups => @group,
                                      :instance_type => machine_type)

      logger.info "---- Please wait another moment, the instance for AMI #{ami} is now pending..."

      # sleep 3
      
      # some AMIs can even terminated immediately
      if (instance.status == :pending)
        sleep 1 until instance.status != :pending
      else
        logger.info "Something wrong with the Instance: #{instance.id} of the AMI: #{ami}"
        logger.info "The program can not launch the AMI: #{ami}"
        logger.info "This AMI: #{ami} is marked as BAD"
        
        # atomic update bad_amis
        @mutex.synchronize do
          @bad_amis << ami
        end
      end

      # after pending, some AMIs are terminated
      if (instance.status == :running)
        logger.info "------ Launched instance #{instance.id} for AMI #{ami}, status: #{instance.status}"
        
        #atomic update
        @mutex.synchronize do
          @ami_instance_map[ami] = instance
        end
      else
        logger.info "Something wrong with the Instance: #{instance.id} of the AMI: #{ami}"
        logger.info "The program can not launch the AMI: #{ami}"
        logger.info "This AMI: #{ami} is marked as BAD"
        
        # atomic update bad_amis
        @mutex.synchronize do
          @bad_amis << ami
        end
      end
    end
    
    thread
  end



  private
  # parse the info delivered by package manager
  # save in json
  def software_parser(file_name)
    software = Hash.new

    # read the file
    list = Hash.new
    File.open(file_name).each do |line|
      if (line.to_s.start_with? "ii")
        tmp = line.split("\s")

        str = ""
        for i in 3..(tmp.length-1) do
          str += tmp[i]
          str += " "
        end

        key = tmp[1]
        value = Hash["version" => tmp[2], "description" => str]
        list[key] = value
      end
    end

    software[:software] = list

    File.open("#{file_name}.json","w") do |f|
      f << JSON.pretty_generate(software)
    end
  end



  # delete old stuff of the last SSH connections
  private
  def delete_old_known_hosts
    if(File.exist? "#{ENV['HOME']}/.ssh/known_hosts")
      File.delete "#{ENV['HOME']}/.ssh/known_hosts"
    end
  end 



  # a dummy introspection
  # read all AMIs from region_owner_free_unknown_amis.txt
  # and write to output/known_amis.txt
  # assumption, all AMIs are introspected successfully
  private
  def dummyIntrospect
    File.open(Init::UNKNOWN_AMIS_FILE_PATH,"r").each do |line|
      File.open(Init::KNOWN_AMIS_FILE_PATH,"a") {|file| file << line}
    end
  end

end
