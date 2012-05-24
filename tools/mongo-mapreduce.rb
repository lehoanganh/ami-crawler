# @author: me[at]lehoanganh[dot]de

# used to count how many amis have the particular software package
# using map reduce function of mongoDB
# official doc: http://www.mongodb.org/display/DOCS/MapReduce

require 'mongo'

db_name = "dummy"
coll_name = "dummy"

# welcome
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

# get the database
db = con.db("#{db_name}")

# get the collection
coll = db.collection("#{coll_name}")

# debug
puts coll.find_one
