require "active_record"
require 'riaction'

root = File.expand_path(File.join(File.dirname(__FILE__), '..'))


ActiveRecord::Base.establish_connection(
  :adapter => "sqlite3",
  :database => "#{root}/db/riaction.db"
)
