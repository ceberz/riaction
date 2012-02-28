require "spec_helper.rb"

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
      before do
        User.class_eval do
          riaction :profile, :type => :player, :custom => :id
        end
        @user = User.riactionless{ User.create(:name => 'zortnac') }
      end
      
      it "should use the API wraper to create the profile with that identifer" do
        @api.should_receive(:create_profile).once.with('player', 'custom', @user.id.to_s, nil)
        ::Riaction::ProfileCreator.perform('User', @user.id)
      end
    end
    
    describe "when a class declares a single profile type with multiple identifers" do
      before do
        User.class_eval do
          riaction :profile, :type => :player, :custom => :id, :username => :name
        end
        @user = User.riactionless{ User.create(:name => 'zortnac') }
      end
      
      it "should use the API wrapper to create the profile with the first identifer given, then make additional calls to the API to add the extra identifiers" do
        @api.should_receive(:create_profile).once.ordered.with('player', 'custom', @user.id.to_s, nil)
        @api.should_receive(:add_profile_identifier).once.ordered.with('player', 'custom', @user.id.to_s, 'username', @user.name)
        ::Riaction::ProfileCreator.perform('User', @user.id)
      end
    end
    
    describe "when a class declares multiple profile types, each with a different number of identifers" do
      before do
        User.class_eval do
          riaction :profile, :type => :player, :custom => :id
          riaction :profile, :type => :npc, :custom => :id, :username => :name
        end
        @user = User.riactionless{ User.create(:name => 'zortnac') }
      end
      
      it "should use the API wrapper to create a profile for each type defined, each followed by the correct API calls for the extra identifiers" do
        @api.should_receive(:create_profile).once.ordered.with('player', 'custom', @user.id.to_s, nil)
        @api.should_receive(:create_profile).once.ordered.with('npc', 'custom', @user.id.to_s, nil)
        @api.should_receive(:add_profile_identifier).once.ordered.with('npc', 'custom', @user.id.to_s, 'username', @user.name)
        ::Riaction::ProfileCreator.perform('User', @user.id)
      end
    end
    
    describe "when a class declares an optional display name" do
      describe "as a method" do
        before do
          User.class_eval do
            riaction :profile, :type => :player, :custom => :id, :display_name => :name
          end
          @user = User.riactionless{ User.create(:name => 'zortnac') }
        end
        
        it "should use the API wraper to create the profile with that display name" do
          @api.should_receive(:create_profile).once.with('player', 'custom', @user.id.to_s, @user.name)
          ::Riaction::ProfileCreator.perform('User', @user.id)
        end
      end
      
      describe "as a proc" do
        before do
          User.class_eval do
            riaction :profile, :type => :player, :custom => :id, :display_name => Proc.new{|record| record.name}
          end
          @user = User.riactionless{ User.create(:name => 'zortnac') }
        end
        
        it "should use the API wraper to create the profile with that display name" do
          @api.should_receive(:create_profile).once.with('player', 'custom', @user.id.to_s, @user.name)
          ::Riaction::ProfileCreator.perform('User', @user.id)
        end
      end
    end
    
    describe "when the class does not actually define itself as a riaction profile" do
      before do
        @user = User.create(:name => 'zortnac')
      end
      
      it "should raise a Riaction runtime error" do
        lambda {::Riaction::ProfileCreator.perform('User', @user.id)}.should raise_error(::Riaction::RuntimeError)
      end
    end
    
    describe "when the call to IActionable, through API wrapper, fails" do
      before do
        @api.stub!(:create_profile).and_raise(IActionable::Error::Internal.new(""))
        User.class_eval do
          riaction :profile, :type => :player, :custom => :id, :username => :name
        end
        @user = User.riactionless{ User.create(:name => 'zortnac') }
      end
      
      it "should re-enqueue the job with an attempt count" do
        Resque.should_receive(:enqueue).once.with(Riaction::ProfileCreator, "User", @user.id, 1)
        ::Riaction::ProfileCreator.perform('User', @user.id, 0)
      end
    end
  
    describe "when the arguments passed to perform are all strings" do
      before do
        User.class_eval do
          riaction :profile, :type => :player, :custom => :id
        end
        @user = User.riactionless{ User.create(:name => 'zortnac') }
      end
      
      it "it should behave normally and without error" do
        @api.should_receive(:create_profile).once.with('player', 'custom', @user.id.to_s, nil)
        lambda {::Riaction::ProfileCreator.perform('User', @user.id.to_s)}.should_not raise_error
      end
    end
  end
  
  after do
    ActiveRecord::Base.connection.rollback_db_transaction
    ActiveRecord::Base.connection.decrement_open_transactions
  end
end