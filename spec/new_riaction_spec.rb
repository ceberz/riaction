require 'spec_helper.rb'

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

ActiveRecord::Base.connection.execute("DROP TABLE IF EXISTS 'comments'")
ActiveRecord::Base.connection.create_table(:comments) do |t|
  t.belongs_to :user
  t.string :content
end

class Comment < ActiveRecord::Base
  extend Riaction::Riaction::ClassMethods
  
  belongs_to :user
end

describe "Riaction" do
  before do
    ActiveRecord::Base.connection.increment_open_transactions
    ActiveRecord::Base.connection.begin_db_transaction
    
    @api = mock("mocked IActionable API")
    IActionable::Api.stub!(:new).and_return(@api)
    Resque.stub(:enqueue).and_return true
    
    User.reset_riaction if User.riactionary?
    Comment.reset_riaction if Comment.riactionary?
  end
  
  describe "basic class methods" do
    it "should say if a class is not using riaction" do
      User.riactionary?.should be_false
    end
    
    it "should say if a class is using riaction" do
      User.class_eval do
        riaction :profile, :type => :player, :custom => :id
      end
      User.riactionary?.should be_true
    end
  end
  
  describe "defining an IA profile on an AR class" do
    it "should store the type and identifiers and make them available as key/values through an instance method" do
      User.class_eval do
        riaction :profile, :type => :player, :custom => :id, :username => :username
      end
      user = User.create(:username => 'zortnac')
      hash_including({:player => {:custom => user.id, :username => user.username}}).should == user.riaction_profile_keys
    end
    
    describe "with a method name as an identifier value" do
      before do
        User.class_eval do
          riaction :profile, :type => :player, :custom => :id
        end
      end
      
      it "should return the correct data for that identifier" do
        user = User.create(:username => 'zortnac')
        user.riaction_profile_keys[:player][:custom].should == user.id
      end
    end
    
    describe "with a proc as an identifier value" do
      before do
        User.class_eval do
          riaction :profile, :type => :player, :custom => Proc.new {|record| record.username}
        end
      end
      
      it "should return the correct data for that identifier type" do
        user = User.create(:username => 'zortnac')
        user.riaction_profile_keys[:player][:custom].should == 'zortnac'
      end
    end
    
    describe "with an unsupported identifier type" do
      it "should raise a configuration error" do
        lambda {
          User.class_eval do
            riaction :profile, :type => :player, :unsupported_type => :id
          end
        }.should raise_error(Riaction::ConfigurationError)
      end
    end
    
    describe "when a class defines a single profile" do
      before do
        User.class_eval do
          riaction :profile, :type => :player, :custom => :id
        end
      end
      
      it "should report that a single profile is defined" do
        User.riaction_profile_types_defined.should == 1
      end
      
      describe "the methods mapping to the IActionable API calls" do
        before do
          @user = User.create(:username => 'zortnac')
          @mock_response = mock("mock API response").as_null_object
        end

        it "should load a profile through the API with the correct parameters" do
          @api.should_receive(:get_profile_summary).once.with("player", "custom", @user.id.to_s, 10).and_return(@mock_response)
          @user.riaction_profile_summary(10).should == @mock_response
        end
        
        it  "should load profile achievments through the API with the correct parameters" do
          @api.should_receive(:get_profile_achievements).once.with("player", "custom", @user.id.to_s, nil).and_return(@mock_response)
          @user.riaction_profile_achievements.should == @mock_response
        end
        
        it  "should load profile challenges through the API with the correct parameters" do
          @api.should_receive(:get_profile_challenges).once.with("player", "custom", @user.id.to_s, nil).and_return(@mock_response)
          @user.riaction_profile_challenges.should == @mock_response
        end
        
        it  "should load profile goals through the API with the correct parameters" do
          @api.should_receive(:get_profile_goals).once.with("player", "custom", @user.id.to_s, nil).and_return(@mock_response)
          @user.riaction_profile_goals.should == @mock_response
        end

        it "should load profile notifications through the API with the correct parameters" do
          @api.should_receive(:get_profile_notifications).once.with("player", "custom", @user.id.to_s).and_return(@mock_response)
          @user.riaction_profile_notifications.should == @mock_response
        end
      end
    end
    
    describe "when a class defines multiple profiles" do
      before do
        User.class_eval do
          riaction :profile, :type => :player, :custom => :id
          riaction :profile, :type => :npc, :username => :username, :custom => :id
        end
      end
      
      it "should report that the correct number of multiple profiles are defined" do
        User.riaction_profile_types_defined.should == 2
      end
      
      it "should store all of them correctly, just as a single one is stored correctly" do
        user = User.create(:username => 'zortnac')
        hash_including({
          :player => {:custom => user.id},
          :npc => {:username => user.username, :custom => user.id}
        }).should == user.riaction_profile_keys
      end
      
      it "should raise an error when trying to set a profile that isn't defined" do
        lambda {User.create(:username => 'zortnac').riaction_set_profile(:bogus)}.should raise_error(Riaction::RuntimeError)
      end
      
      describe "the methods mapping to the IActionable API calls" do
        before do
          @user = User.create(:username => 'zortnac')
          @mock_response = mock("mock API response").as_null_object
        end
        
        describe "when called without specifying which profile type to use" do
          it "should load a profile through the API with the correct parameters, using the last profile type defined in the class" do
            @api.should_receive(:get_profile_summary).once.with("npc", "username", @user.username, 10).and_return(@mock_response)
            @user.riaction_profile_summary(10).should == @mock_response
          end

          it  "should load profile achievments through the API with the correct parameters, using the last profile type defined in the class" do
            @api.should_receive(:get_profile_achievements).once.with("npc", "username", @user.username, nil).and_return(@mock_response)
            @user.riaction_profile_achievements.should == @mock_response
          end

          it  "should load profile challenges through the API with the correct parameters, using the last profile type defined in the class" do
            @api.should_receive(:get_profile_challenges).once.with("npc", "username", @user.username, nil).and_return(@mock_response)
            @user.riaction_profile_challenges.should == @mock_response
          end

          it  "should load profile goals through the API with the correct parameters, using the last profile type defined in the class" do
            @api.should_receive(:get_profile_goals).once.with("npc", "username", @user.username, nil).and_return(@mock_response)
            @user.riaction_profile_goals.should == @mock_response
          end

          it "should load profile notifications through the API with the correct parameters, using the last profile type defined in the class" do
            @api.should_receive(:get_profile_notifications).once.with("npc", "username", @user.username).and_return(@mock_response)
            @user.riaction_profile_notifications.should == @mock_response
          end
        end

        describe "when called after specifying which profile type to use" do
          before do
            @user.riaction_set_profile(:player)
          end
          
          it "should load a profile through the API with the correct parameters" do
            @api.should_receive(:get_profile_summary).once.with("player", "custom", @user.id.to_s, 10).and_return(@mock_response)
            @user.riaction_profile_summary(10).should == @mock_response
          end

          it  "should load profile achievments through the API with the correct parameters" do
            @api.should_receive(:get_profile_achievements).once.with("player", "custom", @user.id.to_s, nil).and_return(@mock_response)
            @user.riaction_profile_achievements.should == @mock_response
          end

          it  "should load profile challenges through the API with the correct parameters" do
            @api.should_receive(:get_profile_challenges).once.with("player", "custom", @user.id.to_s, nil).and_return(@mock_response)
            @user.riaction_profile_challenges.should == @mock_response
          end

          it  "should load profile goals through the API with the correct parameters" do
            @api.should_receive(:get_profile_goals).once.with("player", "custom", @user.id.to_s, nil).and_return(@mock_response)
            @user.riaction_profile_goals.should == @mock_response
          end

          it "should load profile notifications through the API with the correct parameters" do
            @api.should_receive(:get_profile_notifications).once.with("player", "custom", @user.id.to_s).and_return(@mock_response)
            @user.riaction_profile_notifications.should == @mock_response
          end
        end
      end
    end

    describe "and being invoked upon a record's creation" do
      it "should enqueue a task to create a profile for the correct record" do
        Resque.should_receive(:enqueue).once.with(Riaction::ProfileCreator, "User", instance_of(Fixnum))
        User.create(:username => 'zortnac')
      end
    end
    
    describe "and being disabled for a block of code" do
      it "should not enqueue a task to create a profile when the record is created" do
        Resque.should_not_receive(:enqueue)
        
        User.riactionless do 
          user = User.create(:username => 'zortnac')
        end
      end

      it "should return the value of the block" do
          42.should == User.riactionless { 42 }
      end

      it "should reset even if an error is raised within the block" do
        Resque.should_receive(:enqueue).once.with(Riaction::ProfileCreator, "User", instance_of(Fixnum))
        begin 
          User.riactionless do 
            raise Exception.new
          end
        rescue Exception => e
        end
        User.create(:username => 'zortnac')
      end
    end
  end
  
  describe "being used to define an IA event on an AR class" do
    
  end
  
  after do
    ActiveRecord::Base.connection.rollback_db_transaction
    ActiveRecord::Base.connection.decrement_open_transactions
  end
end