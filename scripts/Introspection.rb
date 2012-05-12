# @author: me[at]lehoanganh[dot]de

require 'rubygems'
require 'json'
gem 'json', '~> 1.7.1'
require 'yaml'
require 'aws-sdk'
require 'net/http'
gem 'net-ssh', '~> 2.1.4'
require 'net/ssh'
require 'thread'
require 'logger'

load "Init.rb"
include Init
include JSON

module Introspection

  public
  def introspect(logger)

    # load configuration
    config = YAML.load(File.open Init::CONFIGURATION_FILE_PATH)
    amis = Init::UNKNOWN_AMIS_FILE_PATH



    # Validation
    if (!File.exist? amis)
      logger.error "#{amis} does NOT EXIST !"
      exit 1
    elsif (File.zero? amis)
      logger.error "#{amis} contains NOTHING !"
      logger.error "That means, there are NOTHING to introspect"
      exit 1
    end




    # all already known AMIs in an array
    @known_amis_path = "#{Init::KNOWN_AMIS_FILE_PATH}"
    @known_amis = []
    File.open(@known_amis_path,"r").each {|line| @known_amis << line}



    # get the configuration parameters
    owner_id = config['owner_id'].to_s.strip
    region = config['region'].to_s.strip
    region_dir = "#{Init::OUTPUT_FOLDER_PATH}/regions/#{region}"
    access_key_id = config['access_key_id'].to_s.strip
    secret_access_key = config['secret_access_key'].to_s.strip

    key_pair_name = config['key_pair'].to_s.strip
    group_name = config['group'].to_s.strip

    # login users array
    login_users = config['login_users'].to_s.strip.split(",")





    # START INTROSPECTING
    ec2 = AWS::EC2.new(
        :access_key_id => "#{access_key_id}",
        :secret_access_key => "#{secret_access_key}"
    )
    logger.info "------------------------------------------"
    logger.info "The key pair will be used: #{key_pair_name}"
    logger.info "The security group will be used: #{group_name}"
    logger.info "------------------------------------------"

    # init
    key_pair = group = nil






    logger.info "Checking the key pair..."

    private_key_path = "#{Init::CURRENT_DIR}/#{key_pair_name}.pem"

    if(File.exist? private_key_path)
      logger.info "Deleting the old private key in client side..."
      system "rm #{private_key_path}"
    end
    if !(ec2.key_pairs[key_pair_name].nil?)
      logger.info "Deleting the old public key in server side..."
      ec2.key_pairs[key_pair_name].delete
    end
    logger.info "Creating a new key pair #{key_pair_name}"
    key_pair = ec2.key_pairs.create("#{key_pair_name}")

    # save the private key
    File.open(private_key_path, "w") { |f| f << key_pair.private_key }

    # only user can read/write
    system "chmod 600 #{private_key_path}"






    logger.info "Checking the security group..."

    # existing a security group already
    check = false
    ec2.security_groups.each do |gr|
      if (gr.name == "#{group_name}")
        check = true
        logger.info "Security group #{group_name} exists in EC2 Environment"
        logger.info "Retrieving the security group from EC2"
        group = gr
      end
    end

    # do not exist in EC2 => create a new one
    if (!check)
      logger.info "Create a new security group #{group_name}"
      group = ec2.security_groups.create("#{group_name}")
      group.authorize_ingress(:tcp, 22, "0.0.0.0/0")
    end







    # get all AMIs to an array
    checking_amis = []
    File.open(amis,"r").each {|ami| checking_amis << ami.to_s.strip}

    #delete old stuff of ssh
    logger.info "Delete old stuff of SSH from the last connections..."
    logger.info "If $HOME/.ssh/known_hosts exists, it will be deleted..."
    if(File.exist? "#{ENV['HOME']}/.ssh/known_hosts")
      File.delete "#{ENV['HOME']}/.ssh/known_hosts"
    end
    #system "if [ -e $HOME/.ssh/known_hosts ]; then rm $HOME/.ssh/known_hosts; fi"



    # multi threaded
    threads = []

    # mutex
    @mutex = Mutex.new



    # a hash map, ami => instance
    # key: ami is a string
    # value: instance is a object
    @ami_instance_map = Hash.new
    logger.info "-----------------------------------------"
    logger.info "Step 1: Launching ALL AMIs in the list..."
    logger.info "-----------------------------------------"
    checking_amis.each do |ami|
      thread = createThreadLaunch(ami, access_key_id, secret_access_key, key_pair, group)
      threads << thread
    end
    threads.each {|thread| thread.join}

    #a small pause
    logger.info "Please wait a little moment..."
    sleep 10

    # INTROSPECT each running instance
    logger.info "--------------------------------------"
    logger.info "Step 2: Introspecting EACH instance..."
    logger.info "--------------------------------------"
    threads = []
    checking_amis.each do |ami|
      #thread = createThreadIntrospect(ami, private_key_path, login_users, region_dir, owner_id)
      #threads << thread

      # get the corresponding instance for the selected ami
      logger.info "Introspecting the instance of AMI: #{ami}"
      instance = @ami_instance_map[ami]
      #instance = ec2.instances[instance_id]


      logger.info "----------------------------------------------------"
      logger.info "Try to introspect:"
      logger.info "AMI: #{ami}"
      logger.info "Its corresponding Instance: #{instance.id}"
      logger.info "----------------------------------------------------"

      private_key_file = File.open private_key_path
      instance_ip = instance.ip_address

      login_users.each do |user|
        user = user.to_s.strip

        logger.info "-------------------------------------------------------"
        logger.info "Try 5 times to make a SSH connection with user: #{user}"
        logger.info "-------------------------------------------------------"

        check = false
        counter = 0

        begin
          Net::SSH.start(instance_ip, user, :keys => [private_key_file]) do |ssh|

            logger.info "Connection for user: #{user} is OK"
            logger.info "Do Introspection now"

            logger.info "Uploading script..."
            system "scp -i #{private_key_path} introspect.sh #{user}@#{instance_ip}:/home/#{user}"

            logger.info "Running script..."
            # bug: ssh.exec! always hangs. So sad!!!
            #logger.info ssh.exec!("bash $HOME/introspect.sh")
            #ssh.exec!("bash $HOME/introspect.sh")
            system "ssh -i #{private_key_path} #{user}@#{instance_ip} 'bash $HOME/introspect.sh'"

            logger.info "Downloading results..."
            system "scp -i #{private_key_path} #{user}@#{instance_ip}:/home/#{user}/package_manager_info.txt #{region_dir}/#{owner_id}-#{ami}-package_manager_info"
            system "scp -i #{private_key_path} #{user}@#{instance_ip}:/home/#{user}/ohai_info.json #{region_dir}/#{owner_id}-#{ami}-ohai_info.json"

            logger.info "Parsing results..."
            softwareParser("#{region_dir}/#{owner_id}-#{ami}-package_manager_info")

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

            # sleep 2 second
            sleep 3

            # next try
            retry

          end

        end

        if check

          logger.info "We have the infos we want. Kill the instance #{instance.id}"
          instance.terminate

          logger.info "Updating #{ami} in [output/known_amis.txt]..."
          # prevent duplicate
          if(!@known_amis.include? ami)
            File.open("#{@known_amis_path}","a") {|file| file << ami.to_s.strip << "\n"}
          end

          break
        end

      end
    end
    #threads.each {|thread| thread.join}



    logger.info "-------------------"
    logger.info "Ended Introspection"
    logger.info "-------------------"

  end



  private
  def createThreadLaunch(ami, access_key_id, secret_access_key, key_pair, group)

    thread = Thread.new do
      logger = Logger.new(STDOUT)
      ec2 = AWS::EC2.new(
          :access_key_id => "#{access_key_id}",
          :secret_access_key => "#{secret_access_key}"
      )

      image = nil
      @mutex.synchronize do
        image = ec2.images[ami]
      end

      logger.info "::: An Instance for this AMI #{ami} is being launched..."
      instance = image.run_instance(:key_pair => key_pair,
                                      :security_groups => group,
                                      :instance_type => "t1.micro")

      logger.info "Please wait another moment, the instance for AMI #{ami} is now pending..."
      sleep 1 until instance.status != :pending

      exit 1 unless instance.status == :running
      logger.info "Launched instance #{instance.id} for AMI #{ami}, status: #{instance.status}"

      #atomic update
      @mutex.synchronize do
        @ami_instance_map[ami] = instance
      end

    end
    #thread.abort_on_exception = true
    return thread

  end



  #private
  #def createThreadIntrospect(ami, private_key_path, login_users, region_dir, owner_id)
  #  thread = Thread.new do
  #
  #    logger = Logger.new(STDOUT)
  #
  #    # get the corresponding instance for the selected ami
  #    logger.info "Introspecting the instance of AMI: #{ami}"
  #
  #    instance = nil
  #    @mutex.synchronize do
  #      instance = @ami_instance_map[ami]
  #    end
  #
  #
  #
  #    logger.info "----------------------------------------------------"
  #    logger.info "Try to introspect:"
  #    logger.info "AMI: #{ami}"
  #    logger.info "Its corresponding Instance: #{instance.id}"
  #    logger.info "----------------------------------------------------"
  #
  #    private_key_file = File.open private_key_path
  #    instance_ip = instance.ip_address
  #
  #    login_users.each do |user|
  #      user = user.to_s.strip
  #
  #      logger.info "-------------------------------------------------------"
  #      logger.info "Try 5 times to make a SSH connection with user: #{user}"
  #      logger.info "-------------------------------------------------------"
  #
  #      check = false
  #      counter = 0
  #
  #      begin
  #        Net::SSH.start(instance_ip, user, :keys => [private_key_file]) do |ssh|
  #
  #          logger.info "Connection for user: #{user} is OK"
  #          logger.info "Do Introspection now"
  #
  #          logger.info "Uploading script..."
  #          system "scp -i #{private_key_path} introspect.sh #{user}@#{instance_ip}:/home/#{user}"
  #
  #          logger.info "Running script..."
  #          # bug: ssh.exec! always hangs. So sad!!!
  #          #logger.info ssh.exec!("bash $HOME/introspect.sh")
  #          #ssh.exec!("bash $HOME/introspect.sh")
  #          system "ssh -i #{private_key_path} #{user}@#{instance_ip} 'bash $HOME/introspect.sh'"
  #
  #          logger.info "Downloading results..."
  #          system "scp -i #{private_key_path} #{user}@#{instance_ip}:/home/#{user}/package_manager_info.txt #{region_dir}/#{owner_id}-#{ami}-package_manager_info"
  #          system "scp -i #{private_key_path} #{user}@#{instance_ip}:/home/#{user}/ohai_info.json #{region_dir}/#{owner_id}-#{ami}-ohai_info.json"
  #
  #          logger.info "Parsing results..."
  #          softwareParser("#{region_dir}/#{owner_id}-#{ami}-package_manager_info")
  #
  #          check = true
  #
  #        end
  #
  #      rescue Errno::ECONNREFUSED,Net::SSH::AuthenticationFailed, SystemCallError, Timeout::Error => e
  #
  #        if ( counter == 5 )
  #
  #          logger.info "-----------------------------------------------------------------------------------"
  #          logger.info "5 times already to try to build a SSH connection to the instance with user: #{user}"
  #          logger.info "Not successful!!!"
  #          logger.info "Try the next login user"
  #          logger.info "-----------------------------------------------------------------------------------"
  #
  #        else
  #
  #          # increment counter
  #          counter += 1
  #          logger.info "Please wait for #{counter}. try..."
  #
  #          # sleep 2 second
  #          sleep 3
  #
  #          # next try
  #          retry
  #
  #        end
  #
  #      end
  #
  #      if check
  #
  #        logger.info "We have the infos we want. Kill the instance #{instance.id}"
  #        instance.terminate
  #
  #        logger.info "Updating #{ami} in [output/known_amis.txt]..."
  #        @mutex.synchronize do
  #          # prevent duplicate
  #          if(!@known_amis.include? ami)
  #            f = File.open("#{@known_amis_path}","a")
  #            f << ami.to_s.strip << "\n"
  #            f.close
  #          end
  #        end
  #
  #        break
  #
  #      end
  #
  #    end
  #  end
  #  #thread.abort_on_exception = true
  #  return thread
  #
  #end


  private
  # parse the info delivered by package manager
  # save in json
  def softwareParser(file_name)
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

    #delete the temp file
    #File.delete(file_name)

    software[:software] = list

    File.open("#{file_name}.json","w") do |f|
      f << JSON.pretty_generate(software)
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
