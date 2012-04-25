load "Filter.rb"
load "Introspection.rb"
include Filter
include Introspection

current_dir = File.dirname(__FILE__)
input_path = File.expand_path(current_dir + "/../input")
output_path = File.expand_path(current_dir + "/../output")

# all AMIs
amis = "#{input_path}/amis.txt"
known_amis = "#{output_path}/known_amis.txt"

free_amis = "#{input_path}/free_amis.txt"
free_unknown_amis = "#{input_path}/free_unknown_amis.txt"
free_unknown_os_amis = "#{input_path}/free_unknown_os_amis.txt"
os = "ubuntu"

# invoke FREE Filter to get only FREE AMIs -> #{input_path}/free_amis.txt
puts "------------------------------------------------------"
puts ":::::: FREE filter is now being used to get FREE AMIs"
puts "------------------------------------------------------"
getFreeAmis(amis)

# invoke UNKNOWN Filter to get only UNKNOWN AMIs -> #{input_path}/free_unknown_amis.txt
puts "------------------------------------------------------"
puts ":::::: UNKNOWN filter is now being used to get FREE and UNKNOWN AMIs"
puts "------------------------------------------------------"
getUnknownAmis(free_amis,known_amis)

# invoke OS Filter to get only AMIs with a SPECIFIC OS -> #{input_path}/free_unknown_os.txt
puts "------------------------------------------------------"
puts ":::::: OS filter is now being used to get FREE and UNKNOWN AMIs with a SPECIFIC OS"
puts "------------------------------------------------------"
getSpecificOSAmis(free_unknown_amis,os)

# FINALLY, call Introspection --> #{output_path}/known_amis.txt and JSON files
puts "------------------------------------------------------"
puts ":::::: Call Introspection"
puts "------------------------------------------------------"
introspection(free_unknown_os_amis)