require 'spec_helper.rb'

ActiveRecord::Base.connection.execute("DROP TABLE IF EXISTS 'users'")
ActiveRecord::Base.connection.create_table(:users) do |t|
  t.string :name
  t.string :email
  t.timestamps
end

class User < ActiveRecord::Base
  extend Riaction::Riaction::ClassMethods
  
  has_many :comments, :dependent => :destroy
end

ActiveRecord::Base.connection.execute("DROP TABLE IF EXISTS 'comments'")
ActiveRecord::Base.connection.create_table(:comments) do |t|
  t.belongs_to :user
  t.string :content
end

class Comment < ActiveRecord::Base
  extend Riaction::Riaction::ClassMethods
  
  belongs_to :user
end


describe "Custom matchers for riaction" do
  before do
    User.reset_riaction if User.riactionary?
    Comment.reset_riaction if Comment.riactionary?

    # multiple test runs are building up the callbacks
    Comment.class_eval do
      reset_callbacks :create
      reset_callbacks :update
      reset_callbacks :destroy
    end
  end
  
  describe "profile objects" do
    before do
      User.class_eval do
        riaction :profile, :type => :player, :custom => :id
      end
    end
    
    describe "at the class level" do
      it "should raise an ExpectationNotMetError when asserting that the class defines a profile type that isn't actually defined" do
        lambda {User.should define_riaction_profile(:bogus)}.should raise_error(RSpec::Expectations::ExpectationNotMetError)
      end
      
      it "should not raise an ExpectationNotMetError when asserting that the class defines a profile type that is actually defined" do
        lambda {User.should define_riaction_profile(:player)}.should_not raise_error(RSpec::Expectations::ExpectationNotMetError)
      end
      
      it "should raise an ExpectationNotMetError when asserting that the class uses an identifier that it doesn't define" do
        lambda {User.should define_riaction_profile(:player).identified_by(:bogus => :bogus)}.should raise_error(RSpec::Expectations::ExpectationNotMetError)
      end
      
      it "should not raise an ExpectationNotMetError when asserting that the class uses an identifier that is correctlty defined" do
        lambda {User.should define_riaction_profile(:player).identified_by(:custom => :id)}.should_not raise_error(RSpec::Expectations::ExpectationNotMetError)
      end
    end
    
    describe "at the instance level" do
      before do
        @user = User.riactionless{ User.create(:name => 'zortnac') }
      end
      
      it "should raise an ExpectationNotMetError when asserting that the instance should deliver the correct identifiers and it does not" do
        lambda {@user.should identify_with_riaction_as(:player, :custom => 'bogus')}.should raise_error(RSpec::Expectations::ExpectationNotMetError)
      end
      
      it "should not raise an ExpectationNotMetError when asserting that the instance should deliver the correct identifiers and it does" do
        lambda {@user.should identify_with_riaction_as(:player, :custom => @user.id)}.should_not raise_error(RSpec::Expectations::ExpectationNotMetError)
      end
    end
  end
  
  describe "event objects" do
    before do 
      User.class_eval do
        riaction :profile, :type => :player, :custom => :id
      end
      
      Comment.class_eval do
        riaction :event, :name => :make_a_comment, :trigger => :create, :profile => :user, :params => {:comment => :content}
      end
    end
    
    describe "at the class level" do
      it "should raise an ExpectationNotMetError when incorrectly asserting that the class defines an event" do
        lambda {Comment.should define_riaction_event(:bogus)}.should raise_error(RSpec::Expectations::ExpectationNotMetError)
      end
      
      it "should not raise an ExpectationNotMetError when correctly asserting that the class defines an event" do
        lambda {Comment.should define_riaction_event(:make_a_comment)}.should_not raise_error(RSpec::Expectations::ExpectationNotMetError)
      end
      
      it "should raise an ExpectationNotMetError when incorrectly asserting that the class defines the event on a specific action" do
        lambda {Comment.should define_riaction_event(:make_a_comment).triggered_on(:bogus)}.should raise_error(RSpec::Expectations::ExpectationNotMetError)
      end
      
      it "should not raise an ExpectationNotMetError when correctly asserting that the class defines the event on a specific action" do
        lambda {Comment.should define_riaction_event(:make_a_comment).triggered_on(:create)}.should_not raise_error(RSpec::Expectations::ExpectationNotMetError)
      end
    end
    
    describe "at the instance level" do
      before do
        @user = User.riactionless{ User.create(:name => 'zortnac') }
        @comment = Comment.riactionless{ Comment.create(:user => @user, :content => "this is a comment") }
      end
      
      it "should raise an ExpectationNotMetError when incorrectly asserting that the instance uses the desired riaction profile" do
        lambda {@comment.should log_riaction_event_with_profile(:make_a_comment, :player, :custom, -1)}.should raise_error(RSpec::Expectations::ExpectationNotMetError)
      end
      
      it "should raise an ExpectationNotMetError when correctly asserting that the instance uses the desired riaction profile" do
        lambda {@comment.should log_riaction_event_with_profile(:make_a_comment, :player, :custom, @user.id)}.should_not raise_error(RSpec::Expectations::ExpectationNotMetError)
      end
      
      it "should raise an ExpectationNotMetError when incorrectly asserting that the instance uses the desired params" do
        lambda {@comment.should log_riaction_event_with_params(:make_a_comment, {:comment => "bogus"})}.should raise_error(RSpec::Expectations::ExpectationNotMetError)
      end
      
      it "should raise an ExpectationNotMetError when correctly asserting that the instance uses the desired params" do
        lambda {@comment.should log_riaction_event_with_params(:make_a_comment, {:comment => @comment.content})}.should_not raise_error(RSpec::Expectations::ExpectationNotMetError)
      end
    end
  end
end