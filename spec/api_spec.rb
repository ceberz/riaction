require 'spec_helper.rb'

describe IActionable::Api do
  before do
    @mock_settings = mock("mock settings")
    @mock_connection = mock("connection")
    @mock_response = mock("mock response")
    @mock_response_item = mock("mock response item")
    @mock_object = mock("mock object")
    
    IActionable::Connection.stub!(:new).and_return(@mock_connection)
    IActionable::Settings.stub!(:new).and_return(@mock_settings)
    
    @mock_response.stub!(:map).and_yield(@mock_response_item).and_return(@mock_response)
    @mock_response.stub!(:[]).and_return(@mock_response)
    
    IActionable::Api.init_settings(nil)
    
    @api = IActionable::Api.new
    @profile_type = "user"
    @id_type = "custom"
    @id = 42
  end
  
  describe "initialization" do
    it "should initialize the connection with the previously initialized settings" do
      IActionable::Settings.should_receive(:new).once.with({:foo => "bar"})
      IActionable::Connection.should_receive(:new).once.with(@mock_settings)
      IActionable::Api.init_settings({:foo => "bar"})
      IActionable::Api.new
    end
    
    describe "without having been pre-initialized with settings" do
      before do
        IActionable::Api.class_variable_set(:@@settings, nil)
      end
      
      it "should raise a config error" do
        lambda { IActionable::Api.new }.should raise_error(IActionable::ConfigError)
      end
    end
  end
  
  describe "event creation" do
    before do
      @event_key = "some_event"
      @mock_event_attrs = mock("mock event attrs")
    end
    
    it "should make the correct IActionable API all" do
      @mock_connection.should_receive(:request).once.ordered.and_return(@mock_connection)
      @mock_connection.should_receive(:with_app_key).and_return(@mock_connection)
      @mock_connection.should_receive(:with_api_key).and_return(@mock_connection)
      @mock_connection.should_receive(:to).with("/#{@profile_type}/#{@id_type}/#{@id}/events/#{@event_key}").and_return(@mock_connection)
      @mock_connection.should_receive(:with_params).with(@mock_event_attrs).and_return(@mock_connection)
      @mock_connection.should_receive(:post).and_return(@mock_response)
      @api.log_event(@profile_type, @id_type, @id, @event_key, @mock_event_attrs).should == @mock_response
    end
  end
  
  describe "profile" do
    before do
      @mock_connection.should_receive(:request).once.ordered.and_return(@mock_connection)
      @mock_connection.should_receive(:with_app_key).and_return(@mock_connection)
    end
    
    describe "fetching" do
      before do
        @mock_connection.should_receive(:to).with("/#{@profile_type}/#{@id_type}/#{@id}").and_return(@mock_connection)
        @mock_connection.should_receive(:get).and_return(@mock_response)
        IActionable::Objects::ProfileSummary.stub!(:new)
      end
      
      describe "with achivement count" do
        before do
          @achievement_count = 10
        end
        
        it "should be the correct IActionable API call" do
          @mock_connection.should_receive(:with_params).with({:achievementCount => @achievement_count}).and_return(@mock_connection)
          @api.get_profile_summary(@profile_type, @id_type, @id, @achievement_count)
        end
      end
      
      describe "without achievement count" do
        it "should be the correct IActionable API call" do
          @mock_connection.should_not_receive(:with_params)
          @api.get_profile_summary(@profile_type, @id_type, @id, nil)
        end
      end
      
      it "should return the response as a ProfileSummary object" do
        IActionable::Objects::ProfileSummary.should_receive(:new).once.with(@mock_response)
        @api.get_profile_summary(@profile_type, @id_type, @id, nil)
      end
    end
    
    describe "creation" do
      before do
        @mock_connection.should_receive(:with_api_key).and_return(@mock_connection)
        @mock_connection.should_receive(:to).with("/#{@profile_type}/#{@id_type}/#{@id}").and_return(@mock_connection)
        @mock_connection.should_receive(:post).and_return(@mock_response)
      end
      
      describe "with optional display name" do
        before do
          @display_name = "zortnac"
        end
        
        it "should be the correct IActionable API call" do
          @mock_connection.should_receive(:with_params).with({:displayName => @display_name}).and_return(@mock_connection)
          @api.create_profile(@profile_type, @id_type, @id, @display_name).should == @mock_response
        end
      end
      
      describe "without optional display name" do
        it "should be the correct IActionable API call" do
          @mock_connection.should_not_receive(:with_params)
          @api.create_profile(@profile_type, @id_type, @id, nil).should == @mock_response
        end
      end
    end
    
    describe "updating" do
      it "should make the correct IActionable API all" do
        new_type = "email"
        new_id = 2
        @mock_connection.should_receive(:with_api_key).and_return(@mock_connection)
        @mock_connection.should_receive(:to).with("/#{@profile_type}/#{@id_type}/#{@id}/identifiers/#{new_type}/#{new_id}").and_return(@mock_connection)
        @mock_connection.should_receive(:post).and_return(@mock_response)
        @api.add_profile_identifier(@profile_type, @id_type, @id, new_type, new_id).should == @mock_response
      end
    end
  end
  
  describe "profile points" do
    before do
      @mock_connection.should_receive(:request).once.ordered.and_return(@mock_connection)
      @mock_connection.should_receive(:with_app_key).and_return(@mock_connection)
      @point_type = "experience_points"
      IActionable::Objects::ProfilePoints.stub!(:new).and_return(@mock_response)
    end
    
    describe "fetching" do
      it "should make the correct IActionable API all" do
        @mock_connection.should_receive(:to).with("/#{@profile_type}/#{@id_type}/#{@id}/points/#{@point_type}").and_return(@mock_connection)
        @mock_connection.should_receive(:get).and_return(@mock_response)
        @api.get_profile_points(@profile_type, @id_type, @id, @point_type)
      end
      
      it "should return the response as a ProfileSummary object" do
        @mock_connection.stub!(:to).and_return(@mock_connection)
        @mock_connection.stub!(:get).and_return(@mock_response)
        IActionable::Objects::ProfilePoints.should_receive(:new).once.with(@mock_response).and_return(@mock_response)
        @api.get_profile_points(@profile_type, @id_type, @id, @point_type).should == @mock_response
      end
    end
    
    describe "updating" do
      before do
        @amount = 100
        @mock_connection.should_receive(:with_api_key).and_return(@mock_connection)
        @mock_connection.should_receive(:to).with("/#{@profile_type}/#{@id_type}/#{@id}/points/#{@point_type}").and_return(@mock_connection)
        @mock_connection.should_receive(:with_params).with(hash_including(:value => @amount)).and_return(@mock_connection)
        @mock_connection.should_receive(:post).and_return(@mock_response)
      end
      
      describe "with optional reason" do
        it "should make the correct IActionable API all" do
          reason = "some reason"
          @mock_connection.should_receive(:with_params).with(hash_including(:description => reason)).and_return(@mock_connection)
          @api.update_profile_points(@profile_type, @id_type, @id, @point_type, @amount, reason)
        end
      end
      
      describe "without optional reason" do
        it "should make the correct IActionable API all" do
          reason = "some reason"
          @mock_connection.should_not_receive(:with_params).with(hash_including(:description => reason))
          @api.update_profile_points(@profile_type, @id_type, @id, @point_type, @amount, nil)
        end
      end
      
      it "should return the response as a ProfileSummary object" do
        IActionable::Objects::ProfilePoints.should_receive(:new).once.with(@mock_response).and_return(@mock_response)
        @api.update_profile_points(@profile_type, @id_type, @id, @point_type, @amount, nil).should == @mock_response
      end
    end
  end
  
  [ [:achievements, IActionable::Objects::ProfileAchievements, IActionable::Objects::Achievement],
    [:challenges, IActionable::Objects::ProfileChallenges, IActionable::Objects::Challenge],
    [:goals, IActionable::Objects::ProfileGoals, IActionable::Objects::Goal]].each do |type|
    describe "loading all #{type} for a profile" do
      before do 
        type[1].stub!(:new).and_return(@mock_object)
        @mock_connection.should_receive(:request).once.ordered.and_return(@mock_connection)
        @mock_connection.should_receive(:with_app_key).and_return(@mock_connection)
        @mock_connection.should_receive(:get).and_return(@mock_response)
      end
      
      describe "filtered by available" do
        it "should make the correct IActionable API all" do
          @mock_connection.should_receive(:to).once.with("/#{@profile_type}/#{@id_type}/#{@id}/#{type[0]}/Available").and_return(@mock_connection)
          @api.send("get_profile_#{type[0]}", @profile_type, @id_type, @id, :available)
        end
        
        it "should return as the proper object type" do
          @mock_connection.stub!(:to).and_return(@mock_connection)
          type[1].should_receive(:new).once.with(@mock_response).and_return(@mock_object)
          @api.send("get_profile_#{type[0]}", @profile_type, @id_type, @id, :available).should == @mock_object
        end
      end
      
      describe "filtered by complete" do
        it "should make the correct IActionable API all" do
          @mock_connection.should_receive(:to).once.with("/#{@profile_type}/#{@id_type}/#{@id}/#{type[0]}/Completed").and_return(@mock_connection)
          @api.send("get_profile_#{type[0]}", @profile_type, @id_type, @id, :completed)
        end
        
        it "should return as the proper object type" do
          @mock_connection.stub!(:to).and_return(@mock_connection)
          type[1].should_receive(:new).once.with(@mock_response).and_return(@mock_object)
          @api.send("get_profile_#{type[0]}", @profile_type, @id_type, @id, :completed).should == @mock_object
        end
      end
      
      describe "unfiltered" do
        it "should make the correct IActionable API all" do
          @mock_connection.should_receive(:to).once.with("/#{@profile_type}/#{@id_type}/#{@id}/#{type[0]}").and_return(@mock_connection)
          @api.send("get_profile_#{type[0]}", @profile_type, @id_type, @id, nil)
        end
        
        it "should return as the proper object type" do
          @mock_connection.stub!(:to).and_return(@mock_connection)
          type[1].should_receive(:new).once.with(@mock_response).and_return(@mock_object)
          @api.send("get_profile_#{type[0]}", @profile_type, @id_type, @id, nil).should == @mock_object
        end
      end
    end
    
    describe "loading all #{type[0]} outside of a profile context" do
      before do
        type[2].stub!(:new).and_return(@mock_object)
        @mock_connection.should_receive(:request).once.ordered.and_return(@mock_connection)
        @mock_connection.should_receive(:with_app_key).and_return(@mock_connection)
        @mock_connection.should_receive(:get).and_return(@mock_response)
      end
      
      it "should make the correct IActionable API all" do
        @mock_connection.should_receive(:to).once.with("/#{type[0]}").and_return(@mock_connection)
        @api.send("get_#{type[0]}")
      end
      
      it "should return as the proper object type" do
        @mock_connection.stub!(:to).and_return(@mock_connection)
        type[2].should_receive(:new).once.with(@mock_response_item).and_return(@mock_object)
        @api.send("get_#{type[0]}").should == @mock_response
      end
    end
  end
  
  describe "leaderboards" do
    before do
      @point_type = "experience_points"
      @leaderboard = "top_players"
      @page_number = 3 
      @page_count = 9
      @mock_connection.should_receive(:request).once.ordered.and_return(@mock_connection)
      @mock_connection.should_receive(:with_app_key).and_return(@mock_connection)
      IActionable::Objects::LeaderboardReport.stub!(:new).and_return(@mock_response)
    end
    
    describe "fetching" do
      it "should make the correct IActionable API all" do
        @mock_connection.should_receive(:to).with("/#{@profile_type}/leaderboards/points/#{@point_type}/#{@leaderboard}").and_return(@mock_connection)
        @mock_connection.should_receive(:with_params).with(hash_including(:pageNumber => @page_number)).and_return(@mock_connection)
        @mock_connection.should_receive(:with_params).with(hash_including(:pageCount => @page_count)).and_return(@mock_connection)
        @mock_connection.should_receive(:with_params).with(hash_including(:id => @id)).and_return(@mock_connection)
        @mock_connection.should_receive(:with_params).with(hash_including(:idType => @id_type)).and_return(@mock_connection)
        @mock_connection.should_receive(:get).and_return(@mock_response)
        @api.get_leaderboard(@profile_type, @point_type, @leaderboard, @page_number, @page_count, @id, @id_type)
      end
      
      it "should return the response as a LeaderboardReport object" do
        @mock_connection.stub!(:to).and_return(@mock_connection)
        @mock_connection.stub!(:with_params).and_return(@mock_connection)
        @mock_connection.stub!(:get).and_return(@mock_response)
        IActionable::Objects::LeaderboardReport.should_receive(:new).once.with(@mock_response).and_return(@mock_response)
        @api.get_leaderboard(@profile_type, @point_type, @leaderboard, nil, nil, nil, nil).should == @mock_response
      end
    end
  end
  
  describe "notifications" do
    it "should make the correct IActionable API all" do
      IActionable::Objects::ProfileNotifications.stub!(:new)
      @mock_connection.should_receive(:request).once.ordered.and_return(@mock_connection)
      @mock_connection.should_receive(:with_app_key).and_return(@mock_connection)
      @mock_connection.should_receive(:to).with("/#{@profile_type}/#{@id_type}/#{@id}/notifications").and_return(@mock_connection)
      @mock_connection.should_receive(:get).and_return(@mock_response)
      @api.get_profile_notifications(@profile_type, @id_type, @id)
    end
    
    it "should return with the corect object" do
      @mock_connection.stub!(:request).and_return(@mock_connection)
      @mock_connection.stub!(:with_app_key).and_return(@mock_connection)
      @mock_connection.stub!(:to).and_return(@mock_connection)
      @mock_connection.stub!(:get).and_return(@mock_response)
      IActionable::Objects::ProfileNotifications.should_receive(:new).once.with(@mock_response).and_return(@mock_response)
      @api.get_profile_notifications(@profile_type, @id_type, @id).should == @mock_response
    end
  end
end