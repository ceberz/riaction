require 'spec_helper.rb'

describe Riaction do
  class RiactionTestBase
    include ActiveSupport::Callbacks
    include Riaction
    define_callbacks :after_create, :after_update, :after_destroy
    
    def self.base_class
      self
    end
    
    def initialize
      run_callbacks(:after_create)
    end
    
    def update
      run_callbacks(:after_update)
    end
    
    def destroy
      run_callbacks(:after_destroy)
    end
    
    def id
      42
    end
  end
  
  before do
    @api = mock("mocked IActionable API")
    IActionable::Api.stub!(:new).and_return(@api)
    Resque.stub!(:enqueue)
  end
  
  describe "logging events" do
    class MyClass < RiactionTestBase
      riaction :profile, :type => :user, :custom => :id
      riaction :event, :name => :create_profile, :trigger => :create, :profile => :self, :params => {:foo => "bar"}
    end
    
    class BadClass < RiactionTestBase
    end
    
    before do
      @instance = MyClass.new
      MyClass.stub!(:find_by_id!).and_return(@instance)
      @bad_instance = BadClass.new
      BadClass.stub!(:find_by_id!).and_return(@bad_instance)
    end
    
    describe "when the profile generating the event exists" do
      before do
        @api.stub!(:get_profile_summary).and_return(true)
      end
      
      it "should send the event with parameters based on the details provided in the class" do
        @api.should_receive(:log_event).once.with("user", "custom", @instance.id.to_s, :create_profile, {:foo => "bar"})
        Riaction::EventPerformer.perform(:create_profile, "MyClass", @instance.id)
      end
    end
    
    describe "when the profile generating the event does not exist" do
      before do
        @api.stub!(:get_profile_summary).and_raise(IActionable::Error::BadRequest.new(nil))
      end
      
      it "should create the profile and then send the event with parameters based on the details provided in the class" do
        @api.should_receive(:create_profile).once.ordered.with("user", "custom", @instance.id.to_s)
        @api.should_receive(:log_event).once.ordered.with("user", "custom", @instance.id.to_s, :create_profile, {:foo => "bar"})
        Riaction::EventPerformer.perform(:create_profile, "MyClass", @instance.id)
      end
    end
    
    describe "when the class does not define the named event" do
      it "should not attempt to log the event, and raise an error" do
        @api.should_not_receive(:log_event)
        lambda { Riaction::EventPerformer.perform(:bad_event_name, "MyClass", @instance.id) }.should raise_error(Riaction::NoEventDefined)
      end
    end
    
    describe "when the class does not define the named event or any other riaction property" do
      it "should not attempt to log the event, and raise an error" do
        @api.should_not_receive(:log_event)
        lambda { Riaction::EventPerformer.perform(:create_profile, "BadClass", @bad_instance.id) }.should raise_error(Riaction::NoEventDefined)
      end
    end
  end
  
  describe "profile generation" do
    class MyClass < RiactionTestBase
      riaction :profile, :type => :user, :custom => :id
    end
    
    class BadClass < RiactionTestBase
    end
    
    describe "with a class that defines itself as an iactionable profile" do
      before do
        @instance = MyClass.new
        MyClass.stub!(:find_by_id!).and_return(@instance)
      end
      
      it "should create the profile with parameters based on the details provided in the class" do
        @api.should_receive(:create_profile).once.ordered.with("user", "custom", @instance.id.to_s)
        Riaction::ProfileCreator.perform("MyClass", @instance.id)
      end
    end
    
    describe "with a class that does not define itself as an iactionable profile" do
      before do
        @instance = BadClass.new
        BadClass.stub!(:find_by_id!).and_return(@instance)
      end
      
      it "should not attempt to create the profile, and raise an error" do
        @api.should_not_receive(:create_profile)
        lambda { Riaction::ProfileCreator.perform("BadClass", @instance.id) }.should raise_error(Riaction::NoProfileDefined)
      end
    end
  end
  
  describe "event triggering" do
    class EventDrivingClass < RiactionTestBase
      def initialize
        super
      end
      
      riaction :event, :name => :creation_event, :trigger => :create, :profile => :self
      riaction :event, :name => :updating_event, :trigger => :update, :profile => :self
      riaction :event, :name => :destruction_event, :trigger => :destroy, :profile => :self
      riaction :event, :name => :custom_event, :trigger => :custom, :profile => :self
      
      def id
        42
      end
    end
    
    before do
      @event_driver_instance = EventDrivingClass.new
    end
    
    describe "from an after-create callback" do
      it "should log the event using the profile and paramters specified in the class" do
        Resque.should_receive(:enqueue).once.with(Riaction::EventPerformer, :creation_event, "EventDrivingClass", @event_driver_instance.id)
        EventDrivingClass.new
      end
    end
    
    describe "from an after-update callback" do
      it "should log the event using the profile and paramters specified in the class" do
        Resque.should_receive(:enqueue).once.with(Riaction::EventPerformer, :updating_event, "EventDrivingClass", @event_driver_instance.id)
        @event_driver_instance.update
      end
    end
    
    describe "from an after-destroy callback" do
      it "should log the event using the profile and paramters specified in the class" do
        Resque.should_receive(:enqueue).once.with(Riaction::EventPerformer, :destruction_event, "EventDrivingClass", @event_driver_instance.id)
        @event_driver_instance.destroy
      end
    end
    
    describe "from a custom trigger" do
      it "should log the event using the profile and paramters specified in the class" do
        Resque.should_receive(:enqueue).once.with(Riaction::EventPerformer, :custom_event, "EventDrivingClass", @event_driver_instance.id)
        @event_driver_instance.trigger_custom!
      end
    end
  end
  
  describe "profile" do
    class ProfileClass < RiactionTestBase
      def initialize
        super
      end
      
      riaction :profile, :type => :user, :custom => :id
      
      def id
        42
      end
    end
    
    describe "creation triggering" do
      it "should create the profile based on the parameters given in the class, when an instance of that class is created" do
        Resque.should_receive(:enqueue).once.with(Riaction::ProfileCreator, "ProfileClass", 42)
        ProfileClass.new
      end
    end
    
    describe "instance methods" do
      before do
        @instance = ProfileClass.new
        @mock_response = mock("mock response")
      end
      
      describe "for loading a profile summary" do
        it "should make the correct call to the API with the parameters given in the class, and the values provided by the instance" do
          @api.should_receive(:get_profile_summary).once.with("user", "custom", @instance.id.to_s, 10).and_return(@mock_response)
          @instance.riaction_profile_summary(:user, 10).should == @mock_response
        end
      end
      
      describe "for creating a profile" do
        it "should make the correct call to the API with the parameters given in the class, and the values provided by the instance" do
          @api.stub!(:get_profile_summary).and_return(nil)
          @api.should_receive(:create_profile).once.with("user", "custom", @instance.id.to_s).and_return(@mock_response)
          @instance.riaction_create_profile(:user).should == @mock_response
        end
      end
      
      describe "for loading profile achievments" do
        it "should make the correct call to the API with the parameters given in the class, and the values provided by the instance" do
          @api.should_receive(:get_profile_achievements).once.with("user", "custom", @instance.id.to_s, nil).and_return(@mock_response)
          @instance.riaction_profile_achievements.should == @mock_response
        end
      end
      
      describe "for loading profile challenges" do
        it "should make the correct call to the API with the parameters given in the class, and the values provided by the instance" do
          @api.should_receive(:get_profile_challenges).once.with("user", "custom", @instance.id.to_s, nil).and_return(@mock_response)
          @instance.riaction_profile_challenges.should == @mock_response
        end
      end
      
      describe "for loading profile goals" do
        it "should make the correct call to the API with the parameters given in the class, and the values provided by the instance" do
          @api.should_receive(:get_profile_goals).once.with("user", "custom", @instance.id.to_s, nil).and_return(@mock_response)
          @instance.riaction_profile_goals.should == @mock_response
        end
      end
      
      describe "for loading profile notifications" do
        it "should make the correct call to the API with the parameters given in the class, and the values provided by the instance" do
          @api.should_receive(:get_profile_notifications).once.with("user", "custom", @instance.id.to_s).and_return(@mock_response)
          @instance.riaction_profile_notifications.should == @mock_response
        end
      end
    end
  end
end