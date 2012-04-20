# ====================================================================================================
# @author: Hoang Anh Le | me[at]lehoanganh[dot]de

# a Ruby script which does following task

# 1.read a file which contains a list of AMIs, each AMI in a line
# 2.instantiate each AMI via "aws-sdk for Ruby"
# 3.log into this newly created instance via "capistrano" and do following tasks
# 3.1.install "ruby" via apt-get
# 3.2.install "ohai" via ruby gems
# 3.3.upload "software.rb" plugin to the system
# 3.4.invoke "ohai" including this plugin, save the output into a json file
# 3.5.download this json file, mark it with the AMI name

# COPYLEFT: Some code lines below are borrowed from the original examples of AWS SDK for Ruby of Amazon
# =====================================================================================================

current_dir = File.dirname(__FILE__)
input_path = File.expand_path(current_dir + "/../input")
output_path = File.expand_path(current_dir + "/../output")

# RubyGems
require 'rubygems'

#YAML for Parsing the configuration file
require 'yaml'

# AWS SDK for Ruby
require 'aws-sdk'

# Capistrano
#require 'capistrano'

require 'net/http'
gem 'net-ssh', '~> 2.1.4'
require 'net/ssh'

# ==========================
# STEP 0: CHECK


puts ":::: AMI INTROSPECTION ::::"

puts "::: CHECK THE EXISTENCE OF AMIS.TXT"
ami_file = File.join("#{input_path}/amis.txt")

#amis.txt does not exist
unless File.exist?(ami_file)
  puts <<END
To run the AMI Introspection script, put your AMIs in input/amis.txt
Each line contains an AMI
END
  exit 1
end
puts "INPUT/AMIS.TXT OK!"

puts "::: CHECK THE EXISTENCE OF CONFIG.YML"
config_file = File.join("#{input_path}/config.yml")

# config.yml does not exist
unless File.exist?(config_file)
  puts <<END
To run the AMI Introspection script, put your EC2 credentials in input/config.yml as follows:

access_key_id: YOUR_ACCESS_KEY_ID
secret_access_key: YOUR_SECRET_ACCESS_KEY
END
  exit 1
end
puts "INPUT/CONFIG.YML OK"

#load config_file
config = YAML.load(File.read(config_file))

# not in the YAML format
unless config.kind_of?(Hash)
  puts <<END
config.yml is formatted incorrectly.  Please use the following format:

access_key_id: YOUR_ACCESS_KEY_ID
secret_access_key: YOUR_SECRET_ACCESS_KEY
END
  exit 1
end

# init EC2
puts "::: INITIALIZE AWS EC2"
AWS.config(config)
ec2 = AWS::EC2.new

# EC2 user
#TODO
#now, testing only with Ubuntu AMI of alestic.com, therefore the "user" for login is "ubuntu"
ec2_user = "ubuntu"
puts "::: THE USER FOR THE AMI IS: #{ec2_user}"

# prepare private key and set up a security group for using SSH via Capistrano later

#init
instance = key_pair = group = nil

key_pair_name = "AMI-Introspection"
group_name = "AMI-Introspection"

puts "::: THE KEY PAIR WILL BE USED IS: #{key_pair_name}"
puts "::: THE SECURITY GROUP WILL BE USED IS: #{group_name}"

puts "::: CHECK KEY PAIRS IN EC2"
ec2.key_pairs.each do |key_pair|
  if (key_pair.name == key_pair_name)
    puts "THE KEY PAIR: #{key_pair_name} IS ALREADY SET UP IN EC2 AND IT IS NOW BEING DELETED..."
    key_pair.delete
  end
end

# generate a new key pair
#key_pair = ec2.key_pairs.create("AMI-Introspection-#{Time.now.to_i}")
puts "::: THE NEW KEY PAIR #{key_pair_name} IS BEING GENERATED..."
key_pair = ec2.key_pairs.create("AMI-Introspection")
puts "Generated keypair #{key_pair.name}, fingerprint: #{key_pair.fingerprint}"

# save the private key
# just for the moment
private_key = key_pair.private_key
f = File.open(current_dir + "/private.pem","w")
f.write(private_key)
f.close()

puts "::: CHECK SECURITY GROUPS IN EC2"
ec2.security_groups.each do |group|
  if (group.name == group_name)
    puts "THE SECURITY GROUP: #{group.name} IS ALREADY SET UP IN EC2 AND IT IS NOW BEING DELETED..."
    group.delete
  end
end

# open SSH access
#group = ec2.security_groups.create("AMI-Introspection-#{Time.now.to_i}")
group = ec2.security_groups.create("AMI-Introspection")
group.authorize_ingress(:tcp, 22, "0.0.0.0/0")
puts "Using security group: #{group.name}"

#puts "Using SOFTWARE PLUGIN"
software_plugin = File.expand_path(current_dir + "/../plugins/software.rb")

puts ":::::::::::::::::::::::::::::::::::::"
# ==========================
# STEP 1: ITERATE THE AMI LIST
File.read(ami_file).each_line do |ami|

    puts "::: DEALING WITH AMI ID #{ami}"

    #STEP 2: LAUNCH EACH AMI
    image = ec2.images[ami.to_s]

    if (!image.exists?)
      puts "a BAD AMI, this AMI does NOT exist :( !"
    else
      puts "a GOOD AMI, let's LAUNCH it :) !"

      # launch the instance
      puts "Please wait, an instance for this AMI is being launched..."
      instance = image.run_instance(:key_pair => key_pair, :security_groups => group)

      puts "Please wait another moment, the instance is now pending..."
      sleep 1 until instance.status != :pending

      puts "OK :), launched instance #{instance.id}, status: #{instance.status}"
      exit 1 unless instance.status == :running

      #get the public IP
      public_ip = instance.ip_address
      puts "The newly created instance has public IP: #{public_ip}"

      #edit Capfile
      f_source = File.open("#{current_dir}/Capfile_template","r")
      f_dest = File.open("#{current_dir}/Capfile","w")
      str = ""
      f_source.each do |line|
        if (line.to_s.start_with?("role :ec2_instance, 'dummy'"))
          str += line.gsub("role :ec2_instance, 'dummy'","role :ec2_instance, \"#{public_ip}\"")
          str += "\n"
        elsif (line.to_s.start_with?("set :user, 'dummy'"))
          str += line.gsub("set :user, 'dummy'","set :user, \"#{ec2_user}\"")
          str += "\n"
        else
          str += line
          str += "\n"
        end
      end
      f_dest.write(str)
      f_source.close
      f_dest.close

      # STEP 3: LOG INTO EACH INSTANCE VIA CAPISTRANO
      # and do the magic :D
      begin

        #TODO:
        #not a good solution, Capistrano should have a mechanism for SSH connection timeout too
        #now, there is just a workaround
        Net::SSH.start(instance.ip_address, ec2_user, :key_data => private_key) do |ssh|

          system "cap -f #{current_dir}/Capfile do_magic"
          if (File.exist?("#{current_dir}/output.json"))
            system "mv #{current_dir}/output.json #{output_path}/output_#{ami}.json"
          end

        end

      rescue SystemCallError, Timeout::Error => e
        # port 22 might not be available immediately after the instance finishes launching
        sleep 1
        retry
      end

      puts "We have the JSON file that we need --> kill the instance #{instance.id}"
      instance.terminate
    end
end

# clean up
system "rm #{current_dir}/private.pem"
system "rm #{current_dir}/Capfile"
