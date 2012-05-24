# @author: me[at]lehoanganh[dot]de

# used to count how many amis have the particular software package
# using map reduce function of mongoDB
# official doc: http://www.mongodb.org/display/DOCS/MapReduce

require 'mongo'
require 'logger'
require 'json'

db_name = "dummy"
coll_name = "dummy"
software = "dummy"

# welcome
logger = Logger.new(STDOUT)
logger.info "-----------------------------------------------------------------------------------"
logger.info "Welcome!"
logger.info "You're using now scripts for mongoDB, developed by AIFB, KIT"
logger.info "--- The search script will count how many JSONs have the given key ---"
logger.info "Trace the logger to get the information you want to know!"
logger.info "-----------------------------------------------------------------------------------"

# create a connection to the mongoDB server on localhost
con = Mongo::Connection.new("localhost")

# get the database name
logger.info "Input your database name:"
db_name = gets # read input
db_name = db_name.chomp # delete the last enter character

# get the collection name
logger.info "Input your collection in the database above:"
coll_name = gets
coll_name = coll_name.chomp

# get the software name you want to search
logger.info "Input the software you want to search:"
software = gets
software = software.chomp

# get the database
db = con.db("#{db_name}")

# get the collection
coll = db.collection("#{coll_name}")

software_array = coll.find("software" => {"$exists" => "true"}).to_a
puts software_array.size
# puts software_array[0]

puts "JSON"
json = software_array[0].to_json
puts json
# sum = 0
# array.each do |json|
  # puts "=========================================== JSON: "
  # puts json
# end

# map-reduce
# written in java script dialect

# map
# key is software, just dummy text
# value is installed softwares
map = "function() { emit(wget, this.software);}"

# reduce
# # key is just software
# # values are installed softwares
# reduce = "function(key,values) {"+
  # "var sum = 0; " +
  # "values.forEach(function(pair){ " +
    # " sum += 1; " +
  # "}); " +
  # "return {sums: sum}; " +
# "};"
# 
# result = coll.mapreduce(map, reduce, :out => "result")
# 
# result.find.to_a.size



















































