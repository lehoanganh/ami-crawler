Some Ruby scripts, used for introspecting which packages are installed in 
EC2 AMIs.

Filter script ist responsible to filter AMIs from AWS EC2 with following filter mechanisms 
- Region
- Owner ID
- Free
- Unknown

Introspection script takes the AMI list delivered by Filter, and introspect die AMIs by doing following tasks
- launch AMIs
- set up Ruby and RubyGems on machines
- install Ohai
- upload via scp the "software" plugin
- let ohai running with software plugin to gather information about the installed packages in the machine
- download the results as JSON files

PREREQUISITES
- Ruby Interpreter
- EC2 API Tools
- Gem logger
- Gem aws-sdk
- Gem yaml

USAGE
1. Input: 
[input/configuration.yml]
- AWS Credentials (for using AWS SDK Ruby to perform requests to EC2)
- X509 Certificates (for using EC2 API Tools to perform request to EC2).
Set up in .bashrc
See https://help.ubuntu.com/community/EC2StartersGuide
- Region (e.g. us-east-1, us-west-1, etc..)
- Owner ID
- Login user
- Key pair
- Security Group
2. Use Filter
ruby Run_Filter.rb 
3. Output:
[output/intermediate]: the lists that contains AMIs after filter

4. Use Introspection
ruby Run_Introspection.rb
5. Output:
[output/regions/....]: the JSON files are located in the corresponding folder

DISTRO SUPPORT
- Now only Debian based Distros are supported, e.g. Ubuntu 8.04 and newer.
- Other Distros with RPM based are not supported
