require "spec_helper.rb"

ActiveRecord::Base.connection.execute("DROP TABLE IF EXISTS 'users'")
ActiveRecord::Base.connection.create_table(:users) do |t|
  t.string :username
  t.string :email
  t.timestamps
end

class User < ActiveRecord::Base
  extend Riaction::Riaction::ClassMethods
  
  has_many :comments, :dependent => :destroy
end

describe "automatic profile creation from riaction definitions:" do
  before do
    ActiveRecord::Base.connection.increment_open_transactions
    ActiveRecord::Base.connection.begin_db_transaction
    
    @api = mock("mocked IActionable API")
    IActionable::Api.stub!(:new).and_return(@api)
    Resque.stub(:enqueue).and_return true
    
    User.reset_riaction if User.riactionary?
  end

  describe ::Riaction::ProfileCreator do
    describe "when a class declares a single profile type with a single identifer" do
    end
    
    describe "when a class declares a single profile type with multiple identifers" do
    end
    
    describe "when a class declares multiple profile types, with a different number of identifers" do
    end
  end
  
  after do
    ActiveRecord::Base.connection.rollback_db_transaction
    ActiveRecord::Base.connection.decrement_open_transactions
  end
end

# describe "when a single profile type is defined with a single identifier" do
#   before do
#     User.class_eval do
#       riaction :profile, :type => :player, :custom => :id
#     end
#   end
#   
#   it "should create the profile through the API with the correct paremeters" do
#   end
# end
# 
# describe "when a single profile type is defined with multiple identifiers" do
#   before do
#     User.class_eval do
#       riaction :profile, :type => :player, :custom => :id, :username => :username
#     end
#   end
#   
#   it "should create the profile through the API with the correct paremeters, and then call the API to add additional identifiers" do
#   end
# end
# 
# describe "when multiple profile types are defined" do
# end
# it "should " do
# end