require 'rubygems'
require 'yaml'
require 'aws-sdk'


module Introspection

  public
  def introspect(logger, config, amis)

    if (!File.exist? amis)
      logger.error "#{amis} does NOT EXIST !"
      exit 1
    elsif (File.zero? amis)
      logger.error "#{amis} contains NOTHING !"
      logger.error "That means, there are NOTHING to introspect"
      exit 1
    end

    # all already known AMIs in an array
    known_amis_path = "#{@output_path}/known_amis.txt"
    @known_amis = []
    File.open(known_amis_path,"r").each {|line| @known_amis << line}

    # get the important paths
    initIntrospection

    # get the configuration parameters
    region = config['region'].to_s.strip
    @region_dir = "#{@output_path}/regions/#{region}"
    @access_key_id = config['access_key_id'].to_s.strip
    @secret_access_key = config['secret_access_key'].to_s.strip
    @login_user = config['login_user'].to_s.strip
    key_pair_name = config['key_pair'].to_s.strip
    group_name = config['group'].to_s.strip

    # START INTROSPECTING
    @ec2 = AWS::EC2.new(
        :access_key_id => "#{@access_key_id}",
        :secret_access_key => "#{@secret_access_key}"
    )
    logger.info "------------------------------------------"
    logger.info "The key pair will be used: #{key_pair_name}"
    logger.info "The security group will be used: #{group_name}"
    logger.info "------------------------------------------"

    # init
    @key_pair = @group = nil

    logger.info "Checking the key pair..."

    @private_key_path = "#{@current_dir}/#{key_pair_name}.pem"


    if(File.exist? @private_key_path)
      logger.info "Deleting the old private key in client side..."
      system "rm #{@private_key_path}"
    end
    if !(@ec2.key_pairs[key_pair_name].nil?)
      logger.info "Deleting the old public key in server side..."
      @ec2.key_pairs[key_pair_name].delete
    end
    logger.info "Creating a new key pair #{key_pair_name}"
    @key_pair = @ec2.key_pairs.create("#{key_pair_name}")

    # save the private key
    private_key = @key_pair.private_key
    File.open(@private_key_path, "w") { |f| f << private_key }

    # only user can read/write
    system "chmod 600 #{@private_key_path}"

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

    # get all AMIs to an array
    checking_amis = []
    File.open(amis,"r").each {|ami| checking_amis << ami.to_s.strip}

    #delete old stuff of ssh
    system "if [ -e $HOME/.ssh/known_hosts ]; then rm $HOME/.ssh/known_hosts; fi"

    # multi threaded
    threads = []

    checking_amis.each do |ami|
      #thread = createThread(logger,ami)
      #threads << thread
      help(logger, ami.to_s.strip)

    end
    #threads.each {|thread| thread.join}

    logger.info "Ended Introspection"

  end




  private
  def help(logger, ami)
    image = @ec2.images[ami.to_s.strip]

    logger.info "Please wait, an instance for this AMI is being launched..."
    instance = image.run_instance(:key_pair => @key_pair, :security_groups => @group)

    logger.info "Please wait another moment, the instance is now pending..."
    sleep 1 until instance.status != :pending

    logger.info "OK :), launched instance #{instance.id}, status: #{instance.status}"
    exit 1 unless instance.status == :running

    public_ip = instance.ip_address
    logger.info "The newly created instance has public IP: #{public_ip}"

    private_key = File.expand_path(@private_key_path)

    logger.info "Using #{private_key} to log in the newly created instance"
    logger.info "Login user: #{@login_user}"

    logger.info "Pinging the machine..."
    system "while ! ssh -o StrictHostKeyChecking=no -i #{private_key} #{@login_user}@#{public_ip} true; do echo -n .; sleep .5; done"

    logger.info "Uploading script..."
    system "scp -i #{private_key} bootstrap.sh #{@login_user}@#{public_ip}:/home/#{@login_user}"

    logger.info "Running the bootstrap script..."
    system "ssh -i #{private_key} #{@login_user}@#{public_ip} 'sudo bash bootstrap.sh'"

    logger.info "Make a home for software plugins"
    system "ssh -i #{private_key} #{@login_user}@#{public_ip} 'mkdir -p $HOME/plugins'"

    logger.info "Upload software plugin..."
    system "scp -i #{private_key} software.rb #{@login_user}@#{public_ip}:/home/#{@login_user}/plugins"

    logger.info "Run Ohi-o :)..."
    system "ssh -i #{private_key} #{@login_user}@#{public_ip} 'ohai -d $HOME/plugins > $HOME/output.json'"

    logger.info "Download json file..."
    system "scp -i #{private_key} #{@login_user}@#{public_ip}:/home/#{@login_user}/output.json #{@region_dir}/#{ami}.json"

    logger.info "We have the JSON file that we need --> kill the instance #{instance.id}"
    instance.terminate

    logger.info "Updating #{ami} in [output/known_amis.txt]..."
    File.open("#{@output_path}/known_amis.txt","a") {|file| file << ami.to_s.strip << "\n"}
  end





  private
  def createThread(logger, ami)

    thread = Thread.new do

      ec2 = AWS::EC2.new(
          :access_key_id => "#{@access_key_id}",
          :secret_access_key => "#{@secret_access_key}"
      )

      image = ec2.images[ami.to_s.strip]

      logger.info "Please wait, an instance for this AMI is being launched..."
      instance = image.run_instance(:key_pair => @key_pair, :security_groups => @group)

      logger.info "Please wait another moment, the instance is now pending..."
      sleep 1 until instance.status != :pending

      logger.info "OK :), launched instance #{instance.id}, status: #{instance.status}"
      exit 1 unless instance.status == :running

      public_ip = instance.ip_address
      logger.info "The newly created instance has public IP: #{public_ip}"

      private_key = File.expand_path(@private_key_path)

      logger.info "Using #{private_key} to log in the newly created instance"
      logger.info "Login user: #{@login_user}"

      logger.info "Pinging the machine..."
      system "while ! ssh -o StrictHostKeyChecking=no -i #{private_key} #{@login_user}@#{public_ip} true; do echo -n .; sleep .5; done"

      logger.info "Uploading script..."
      system "scp -i #{private_key} bootstrap.sh #{@login_user}@#{public_ip}:/home/#{@login_user}"

      logger.info "Running the bootstrap script..."
      system "ssh -i #{private_key} #{@login_user}@#{public_ip} 'sudo bash bootstrap.sh'"

      logger.info "Make a home for software plugins"
      system "ssh -i #{private_key} #{@login_user}@#{public_ip} 'mkdir -p $HOME/plugins'"

      logger.info "Upload software plugin..."
      system "scp -i #{private_key} software.rb #{@login_user}@#{public_ip}:/home/#{@login_user}/plugins"

      logger.info "Run Ohi-o :)..."
      system "ssh -i #{private_key} #{@login_user}@#{public_ip} 'ohai -d $HOME/plugins > $HOME/output.json'"

      logger.info "Download json file..."
      system "scp -i #{private_key} #{@login_user}@#{public_ip}:/home/#{@login_user}/output.json #{@region_dir}/#{ami}.json"

      logger.info "We have the JSON file that we need --> kill the instance #{instance.id}"
      instance.terminate

      logger.info "Updating #{ami} in [output/known_amis.txt]..."

      # prevent duplicate
      if(!@known_amis.include? ami)
        File.open("#{@output_path}/known_amis.txt","a") {|file| file << ami.to_s.strip << "\n"}
      end
    end

    return thread
  end


  private
  def initIntrospection
    @current_dir = File.dirname(__FILE__)
    @input_path = File.expand_path(@current_dir + "/../input")
    @output_path = File.expand_path(@current_dir + "/../output")
  end

end