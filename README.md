A Ruby script, used for introspecting which packages are installed in 
EC2 AMIs.

The script contains a "software" plugin to connect to Ohai and provides
for Ohai the corresponding information. The result from Ohai is a JSON file.

PREREQUISITES
- Ruby Interpreter
- Capistrano

USING
- input/amis.txt
input the AMIs you want to introspect, each AMI in a line
- input/config.yml
input the AWS credentials
- execute "ruby ami_introspection.rb"
- the outputs as JSON files are saved in output folder. Each output is marked
with the introspected AMI
