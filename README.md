A Ruby script, used for introspecting which packages are installed in 
EC2 AMIs.

The script contains a "software" plugin to connect to Ohai and provides
for Ohai the corresponding information. The result from Ohai is a JSON file.

PREREQUISITES
- Ruby Interpreter
- Capistrano

USING
1. input/amis.txt
input the AMIs you want to introspect, each AMI in a line
2. input/config.yml
input the AWS credentials
3. execute "ruby ami_introspection.rb"
4. the output as JSON are saved in output folder. Each output is marked
with the introspected AMI
