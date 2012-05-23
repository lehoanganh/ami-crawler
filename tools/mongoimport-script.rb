# @author: me[at]lehoanganh[dot]de

# used to import multiple json files and write each json in a single line

# require 'rubygems'
# require 'yajl'
require 'logger'

logger = Logger.new(STDOUT)
logger.info "Welcome!"
logger.info "The script will import multiple json file in the current directory"
logger.info "and write each json in a single line"

# JSON Parser
# parser = Yajl::Parser.new

current_dir = File.dirname __FILE__

# the file which contains multiple lines, each line is a json content
final_list = File.expand_path(current_dir + "/final_list.txt")

# already exist, than create a new one
if File.exist? final_list
  File.delete final_list
  File.open(final_list,"w") { }
end
f = File.open(final_list,'a')

# contains all file names in the current direct
entries = Dir.entries current_dir

# iterate
entries.each do |file_name|
  
  # . and .. are not interesting
  if file_name != "." && file_name != ".." && file_name.to_s.include?("json") && !File.zero?(file_name) && !File.read(file_name).include?("Ohai for now is not supported by the system")
    
    logger.info "Parsing #{file_name}..."
    
    # temporary string
    str = String.new
    
    # json file
    json = File.open(file_name,"r")
    
    # read the json file
    json.each {|line| str << line}
       
    # delete all new line characters
    str = str.gsub("\n","")
      
    # write into the final list
    f << str << "\n"
  end
end

logger.info "Saving in final_list.txt..."
logger.info "Done, bye!"
