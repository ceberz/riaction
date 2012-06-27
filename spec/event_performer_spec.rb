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

describe "sending an event to IActionable from the name of a riaction class and an ID to locate the instance" do
  before do
    ActiveRecord::Base.connection.increment_open_transactions
    ActiveRecord::Base.connection.begin_db_transaction
    
    @api = mock("mocked IActionable API")
    @api.stub!(:get_profile_summary)
    IActionable::Api.stub!(:new).and_return(@api)
    Resque.stub(:enqueue).and_return true
    
    User.reset_riaction if User.riactionary?
    Comment.reset_riaction if Comment.riactionary?

    # multiple test runs are building up the callbacks
    Comment.class_eval do
      reset_callbacks :create
      reset_callbacks :update
      reset_callbacks :destroy
    end
  end

  describe ::Riaction::EventPerformer do
    before do
      User.class_eval do
        riaction :profile, :type => :player, :custom => :id
        riaction :profile, :type => :npc, :username => :name, :custom => :id
      end
      @user = User.riactionless{ User.create(:name => 'zortnac') }
    end
    
    describe "and where an event is defined with parameters" do
      before do
        Comment.class_eval do
          riaction :event, :name => :make_a_comment, :trigger => :create, :profile => :user, :profile_type => :npc, :params => {:foo => 'bar'}
        end
        
        @comment = Comment.riactionless{ Comment.create(:user_id => @user.id, :content => 'this is a comment') }
      end
      
      it "should create the event through the API wrapper with the correct parameters" do
        @api.should_receive(:log_event).once.with(@comment.riaction_event_params[:make_a_comment][:profile][:type], 
                                                  @comment.riaction_event_params[:make_a_comment][:profile][:id_type],
                                                  @comment.riaction_event_params[:make_a_comment][:profile][:id],
                                                  :make_a_comment, 
                                                  @comment.riaction_event_params[:make_a_comment][:params])
        ::Riaction::EventPerformer.perform(:make_a_comment, 'Comment', @comment.id)
      end
    end
    
    describe "and where an event is defined without parameters" do
      before do
        Comment.class_eval do
          riaction :event, :name => :make_a_comment, :trigger => :create, :profile => :user, :profile_type => :player
        end
        
        @comment = Comment.riactionless{ Comment.create(:user_id => @user.id, :content => 'this is a comment') }
      end
      
      it "should create the event through the API wrapper with no parameters" do
        @api.should_receive(:log_event).once.with(@comment.riaction_event_params[:make_a_comment][:profile][:type], 
                                                  @comment.riaction_event_params[:make_a_comment][:profile][:id_type],
                                                  @comment.riaction_event_params[:make_a_comment][:profile][:id],
                                                  :make_a_comment, 
                                                  {})
        ::Riaction::EventPerformer.perform(:make_a_comment, 'Comment', @comment.id)
      end
    end
    
    describe "when fetching the event params raises a" do
      before do
        Comment.class_eval do
          riaction :event, :name => :make_a_comment, :trigger => :create, :profile => :user, :profile_type => :npc, :params => {:foo => 'bar'}
        end
        
        @comment = Comment.riactionless{ Comment.create(:user_id => @user.id, :content => 'this is a comment') }
      end
      
      describe "RuntimeError" do
        before do
          @comment.stub!(:riaction_event_params).and_raise(::Riaction::RuntimeError)
          Comment.stub!(:find_by_id).and_return(@comment)
        end
        
        it "should not try to create the event" do
          @api.should_not_receive(:log_event)
          begin
            ::Riaction::EventPerformer.perform(:make_a_comment, 'Comment', @comment.id)
          rescue Exception => e
          end
        end
        
        it "should raise a RuntimeError" do
          lambda { ::Riaction::EventPerformer.perform(:make_a_comment, 'Comment', @comment.id) }.should raise_error(::Riaction::RuntimeError)
        end
      end
      
      describe "ConfigurationError" do
        before do
          @comment.stub!(:riaction_event_params).and_raise(::Riaction::ConfigurationError)
          Comment.stub!(:find_by_id).and_return(@comment)
        end
        
        it "should not try to create the event" do
          @api.should_not_receive(:log_event)
          begin
            ::Riaction::EventPerformer.perform(:make_a_comment, 'Comment', @comment.id)
          rescue Exception => e
          end
        end
        
        it "should raise a ConfigurationError" do
          lambda { ::Riaction::EventPerformer.perform(:make_a_comment, 'Comment', @comment.id) }.should raise_error(::Riaction::ConfigurationError)
        end
      end
    end
    
    describe "when the class does not actually define any riaction events" do
      before do
        Comment.reset_riaction if Comment.riactionary?
        # multiple test runs are building up the callbacks
        Comment.class_eval do
          reset_callbacks :create
          reset_callbacks :update
          reset_callbacks :destroy
        end
        @comment = Comment.create(:user_id => @user.id, :content => 'this is a comment')
      end
      
      it "should not try to create the event" do
        @api.should_not_receive(:log_event)
        begin
          ::Riaction::EventPerformer.perform(:make_a_comment, 'Comment', @comment.id)
        rescue Exception => e
        end
      end
      
      it "should raise a ConfigurationError" do
        lambda { ::Riaction::EventPerformer.perform(:make_a_comment, 'Comment', @comment.id) }.should raise_error(::Riaction::ConfigurationError)
      end
    end
    
    describe "when the class does not actually define the event specified" do
      before do
        Comment.class_eval do
          riaction :event, :name => :make_a_comment, :trigger => :create, :profile => :user, :profile_type => :npc, :params => {:foo => 'bar'}
        end
        
        @comment = Comment.riactionless{ Comment.create(:user_id => @user.id, :content => 'this is a comment') }
      end
      
      it "should not try to create the event" do
        @api.should_not_receive(:log_event)
        begin
          ::Riaction::EventPerformer.perform(:bogus, 'Comment', @comment.id)
        rescue Exception => e
        end
      end
      
      it "should raise a ConfigurationError" do
        lambda { ::Riaction::EventPerformer.perform(:bogus, 'Comment', @comment.id) }.should raise_error(::Riaction::ConfigurationError)
      end
    end
    
    describe "when an event that the class defines is missing from the instance (due here to an invalid profile)" do
      before do
        Comment.class_eval do
          riaction :event, :name => :make_a_comment, :trigger => :create, :profile => :user, :profile_type => :npc, :params => {:foo => 'bar'}
        end
        
        # creating the comment wihtout a user will lead to a missing profile for the event
        @comment = Comment.riactionless{ Comment.create(:content => 'this is a comment') }
      end
      
      it "should not try to create the event" do
        @api.should_not_receive(:log_event)
        begin
          ::Riaction::EventPerformer.perform(:make_a_comment, 'Comment', @comment.id)
        rescue Exception => e
        end
      end
      
      it "should raise a ConfigurationError" do
        lambda { ::Riaction::EventPerformer.perform(:make_a_comment, 'Comment', @comment.id) }.should raise_error(::Riaction::ConfigurationError)
      end
    end
    
    describe "when the object specified is missing" do
      before do
        Comment.class_eval do
          riaction :event, :name => :make_a_comment, :trigger => :create, :profile => :user, :profile_type => :npc, :params => {:foo => 'bar'}
        end
        
        @comment = Comment.riactionless{ Comment.create(:user_id => @user.id, :content => 'this is a comment') }
        @comment.destroy
      end
      
      it "should not try to create the event" do
        @api.should_not_receive(:log_event)
        begin
          ::Riaction::EventPerformer.perform(:make_a_comment, 'Comment', @comment.id)
        rescue Exception => e
        end
      end
      
      it "should not raise an error" do
        lambda { ::Riaction::EventPerformer.perform(:make_a_comment, 'Comment', @comment.id) }.should_not raise_error
      end
    end
    
    describe "when the call to IActionable, through API wrapper, fails" do
      before do
        @exception = IActionable::Error::Internal.new("")
        @api.stub!(:log_event).and_raise(@exception)
        Comment.class_eval do
          riaction :event, :name => :make_a_comment, :trigger => :create, :profile => :user, :profile_type => :npc, :params => {:foo => 'bar'}
        end
        @comment = Comment.riactionless{ Comment.create(:user_id => @user.id, :content => 'this is a comment') }
      end
      
      it "should handle the failure passing the exception, event name, class name, and model id" do
        ::Riaction::EventPerformer.should_receive(:handle_api_failure).once.with(@exception, :make_a_comment, 'Comment', @comment.id)
        ::Riaction::EventPerformer.perform(:make_a_comment, 'Comment', @comment.id)
      end
      
      describe "and the default behavior of the failure handler is in place" do
        it "should re-raise the exception" do
          lambda{::Riaction::EventPerformer.perform(:make_a_comment, 'Comment', @comment.id)}.should raise_error(@exception)
        end
      end
      
      describe "and custom behavior of the failure handler is in place" do
        before do
          ::Riaction::EventPerformer.handle_api_failure_with do |exception, event_name, class_name, id|
            5.times do 
              exception.inspect
            end
          end
        end
        
        it "should perform the custom behavior" do
          @exception.should_receive(:inspect).exactly(5).times
          ::Riaction::EventPerformer.perform(:make_a_comment, 'Comment', @comment.id)
        end
      end
    end
    
    describe "when the call to IActionable, through API wrapper, times out" do
      before do
        @api.stub!(:log_event).and_raise(Timeout::Error)
        Comment.class_eval do
          riaction :event, :name => :make_a_comment, :trigger => :create, :profile => :user, :profile_type => :npc, :params => {:foo => 'bar'}
        end
        @comment = Comment.riactionless{ Comment.create(:user_id => @user.id, :content => 'this is a comment') }
      end
      
      it "should re-enqueue the job with an attempt count" do
        Resque.should_receive(:enqueue).once.with(Riaction::EventPerformer, :make_a_comment, 'Comment', @comment.id, 1)
        ::Riaction::EventPerformer.perform(:make_a_comment, 'Comment', @comment.id)
      end
    end
    
    describe "when the call to IActionable, through API wrapper, times out with a faraday-wrapped timeout" do
      before do
        @api.stub!(:log_event).and_raise(Faraday::Error::TimeoutError.new(""))
        Comment.class_eval do
          riaction :event, :name => :make_a_comment, :trigger => :create, :profile => :user, :profile_type => :npc, :params => {:foo => 'bar'}
        end
        @comment = Comment.riactionless{ Comment.create(:user_id => @user.id, :content => 'this is a comment') }
      end
      
      it "should re-enqueue the job with an attempt count" do
        Resque.should_receive(:enqueue).once.with(Riaction::EventPerformer, :make_a_comment, 'Comment', @comment.id, 1)
        ::Riaction::EventPerformer.perform(:make_a_comment, 'Comment', @comment.id)
      end
    end
  
    describe "when the arguments passed to perform() are all strings" do
      before do
        Comment.class_eval do
          riaction :event, :name => :make_a_comment, :trigger => :create, :profile => :user, :profile_type => :npc
        end
        
        @comment = Comment.riactionless{ Comment.create(:user_id => @user.id, :content => 'this is a comment') }
      end
      
      it "should behave correctly and without error" do
        @api.should_receive(:log_event).once.with(@comment.riaction_event_params[:make_a_comment][:profile][:type], 
                                                  @comment.riaction_event_params[:make_a_comment][:profile][:id_type],
                                                  @comment.riaction_event_params[:make_a_comment][:profile][:id],
                                                  :make_a_comment, 
                                                  {})
        lambda {::Riaction::EventPerformer.perform('make_a_comment', 'Comment', @comment.id.to_s)}.should_not raise_error
      end
    end
  end
  
  after do
    ActiveRecord::Base.connection.rollback_db_transaction
    ActiveRecord::Base.connection.decrement_open_transactions
  end
end