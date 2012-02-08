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

ActiveRecord::Base.connection.execute("DROP TABLE IF EXISTS 'sessions'")
ActiveRecord::Base.connection.create_table(:sessions) do |t|
  t.belongs_to :user
end

class Session < ActiveRecord::Base
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

    # multiple test runs are building up the callbacks
    Comment.class_eval do
      reset_callbacks :create
      reset_callbacks :update
      reset_callbacks :destroy
    end
  end
  
  describe "basic class methods" do
    it "should say if a class is not using riaction" do
      Session.riactionary?.should be_false
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
        riaction :profile, :type => :player, :custom => :id, :username => :name
      end
      user = User.riactionless{ User.create(:name => 'zortnac') }
      hash_including({
        :player => {
          :custom => user.id, 
          :username => user.name}
        }).should == user.riaction_profile_keys
    end
    
    describe "with a method name as an identifier value" do
      before do
        User.class_eval do
          riaction :profile, :type => :player, :custom => :id
        end
      end
      
      it "should return the correct data for that identifier" do
        user = User.riactionless{ User.create(:name => 'zortnac') }
        user.riaction_profile_keys[:player][:custom].should == user.id
      end
    end
    
    describe "with a proc as an identifier value" do
      before do
        User.class_eval do
          riaction :profile, :type => :player, :custom => Proc.new {|record| record.name}
        end
      end
      
      it "should return the correct data for that identifier type" do
        user = User.riactionless{ User.create(:name => 'zortnac') }
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
      
      it "should report that it defines at least one profile" do
        User.riaction_profile?.should be_true
      end
      
      it "should report that a single profile is defined" do
        User.riaction_profile_types_defined.should == 1
      end
      
      describe "the methods mapping to the IActionable API calls" do
        before do
          @user = User.riactionless{ User.create(:name => 'zortnac') }
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
          riaction :profile, :type => :npc, :username => :name, :custom => :id
        end
      end
      
      it "should report that the correct number of multiple profiles are defined" do
        User.riaction_profile_types_defined.should == 2
      end
      
      it "should store all of them correctly, just as a single one is stored correctly" do
        user = User.riactionless{ User.create(:name => 'zortnac') }
        hash_including({
          :player => {
            :custom => user.id
          },
          :npc => {
            :username => user.name, 
            :custom => user.id
          }
        }).should == user.riaction_profile_keys
      end
      
      it "should raise an error when trying to set a profile that isn't defined" do
        lambda {User.create(:name => 'zortnac').riaction_set_profile(:bogus)}.should raise_error(Riaction::RuntimeError)
      end
      
      describe "the methods mapping to the IActionable API calls" do
        before do
          @user = User.riactionless{ User.create(:name => 'zortnac') }
          @mock_response = mock("mock API response").as_null_object
        end
        
        describe "when called without specifying which profile type to use" do
          it "should load a profile through the API with the correct parameters, using the first profile type defined in the class" do
            @api.should_receive(:get_profile_summary).once.with("player", "custom", @user.id.to_s, 10).and_return(@mock_response)
            @user.riaction_profile_summary(10).should == @mock_response
          end

          it  "should load profile achievments through the API with the correct parameters, using the first profile type defined in the class" do
            @api.should_receive(:get_profile_achievements).once.with("player", "custom", @user.id.to_s, nil).and_return(@mock_response)
            @user.riaction_profile_achievements.should == @mock_response
          end

          it  "should load profile challenges through the API with the correct parameters, using the first profile type defined in the class" do
            @api.should_receive(:get_profile_challenges).once.with("player", "custom", @user.id.to_s, nil).and_return(@mock_response)
            @user.riaction_profile_challenges.should == @mock_response
          end

          it  "should load profile goals through the API with the correct parameters, using the first profile type defined in the class" do
            @api.should_receive(:get_profile_goals).once.with("player", "custom", @user.id.to_s, nil).and_return(@mock_response)
            @user.riaction_profile_goals.should == @mock_response
          end

          it "should load profile notifications through the API with the correct parameters, using the first profile type defined in the class" do
            @api.should_receive(:get_profile_notifications).once.with("player", "custom", @user.id.to_s).and_return(@mock_response)
            @user.riaction_profile_notifications.should == @mock_response
          end
        end

        describe "when called after specifying which profile type to use" do
          before do
            @user.riaction_set_profile(:npc)
          end
          
          it "should load a profile through the API with the correct parameters" do
            @api.should_receive(:get_profile_summary).once.with("npc", "username", @user.name, 10).and_return(@mock_response)
            @user.riaction_profile_summary(10).should == @mock_response
          end

          it  "should load profile achievments through the API with the correct parameters" do
            @api.should_receive(:get_profile_achievements).once.with("npc", "username", @user.name, nil).and_return(@mock_response)
            @user.riaction_profile_achievements.should == @mock_response
          end

          it  "should load profile challenges through the API with the correct parameters" do
            @api.should_receive(:get_profile_challenges).once.with("npc", "username", @user.name, nil).and_return(@mock_response)
            @user.riaction_profile_challenges.should == @mock_response
          end

          it  "should load profile goals through the API with the correct parameters" do
            @api.should_receive(:get_profile_goals).once.with("npc", "username", @user.name, nil).and_return(@mock_response)
            @user.riaction_profile_goals.should == @mock_response
          end

          it "should load profile notifications through the API with the correct parameters" do
            @api.should_receive(:get_profile_notifications).once.with("npc", "username", @user.name).and_return(@mock_response)
            @user.riaction_profile_notifications.should == @mock_response
          end
        end
      end
    end

    describe "and being invoked upon a record's creation" do
      before do
        User.class_eval do
          riaction :profile, :type => :player, :custom => :id
        end
      end
      
      it "should enqueue a task to create a profile for the correct record" do
        Resque.should_receive(:enqueue).once.with(Riaction::ProfileCreator, "User", instance_of(Fixnum))
        User.create(:name => 'zortnac')
      end
    end
    
    describe "and being disabled for a block of code" do
      before do
        User.class_eval do
          riaction :profile, :type => :player, :custom => :id
        end
      end
      
      it "should not enqueue a task to create a profile when the record is created" do
        Resque.should_not_receive(:enqueue)
        
        User.riactionless do 
          user = User.create(:name => 'zortnac')
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
        User.create(:name => 'zortnac')
      end
    end
  end
  
  describe "defining an IA event on an AR class" do
    before do
      User.class_eval do
        riaction :profile, :type => :player, :custom => :id
        riaction :profile, :type => :npc, :username => :name, :custom => :id
      end
      @user = User.riactionless{ User.create(:name => 'zortnac') }
    end
    
    it "should store the event name and options and make them available as key/values through an instance method" do
      Comment.class_eval do
        riaction :event, :name => :make_a_comment, :trigger => :create, :profile => :user, :profile_type => :npc, :params => {:foo => 'bar'}
      end
      comment = Comment.riactionless{ Comment.create(:user_id => @user.id, :content => 'this is a comment') }
      hash_including({
        :make_a_comment => {
          :profile => {
            :type => :npc,
            :id_type => :username,
            :id => @user.name
          },
          :params => {:foo => 'bar'} 
        }
      }).should == comment.riaction_event_params
    end
    
    describe "where multiple events are defined" do
      before do
        Comment.class_eval do
          riaction :event, :name => :make_a_comment, :trigger => :create, :profile => :user, :profile_type => :npc, :params => {:foo => 'bar'}
          riaction :event, :name => :like_a_comment, :trigger => :like, :profile => :user, :profile_type => :player, :params => {:apple => 'pi'}
        end
        
        @comment = Comment.riactionless{ Comment.create(:user_id => @user.id, :content => 'this is a comment') }
      end
      
      describe "with the same event name" do
        before do
          Comment.class_eval do
            riaction :event, :name => :make_a_comment, :trigger => :create, :profile => :user, :profile_type => :player, :params => {:are => 'different'}
          end
        end
      end
      
      it "should store the event name and options and make them available as key/valyes through an instance method" do
        hash_including({
          :make_a_comment => {
            :profile => {
              :type => :npc,
              :id_type => :username,
              :id => @user.name
            },
            :params => {:foo => 'bar'} 
          },
          :like_a_comment => {
            :profile => {
              :type => :player,
              :id_type => :custom,
              :id => @user.id
            },
            :params => {:apple => 'pi'}
          }
        }).should == @comment.riaction_event_params
      end
      
      it "should return the number of events defined" do
        Comment.riaction_events_defined.should == 2
      end
    end
    
    describe "and the triggering of an event" do
      describe "when caused by the CRUD action 'create'" do
        before do
          Comment.class_eval do
            riaction :event, :name => :make_a_comment, :trigger => :create, :profile => :user
          end
        end
        
        it "should try to enqueue the event when the record is created" do
          Resque.should_receive(:enqueue).once.with(Riaction::EventPerformer, :make_a_comment, "Comment", instance_of(Fixnum))
          Comment.create(:content => "this is a comment")
        end
        
        it "should try to enqueue the event only when the record is created" do
          Resque.should_receive(:enqueue).once.with(Riaction::EventPerformer, :make_a_comment, "Comment", instance_of(Fixnum))
          comment = Comment.create(:content => "this is a comment")
          comment.content = "updated content"
          comment.save
          comment.destroy
        end
      end
      
      describe "when caused by the CRUD action 'update'" do
        before do
          Comment.class_eval do
            riaction :event, :name => :make_a_comment, :trigger => :update, :profile => :user
          end
          @comment = Comment.riactionless{ Comment.create(:content => "this is a comment") }
        end
        
        it "should try to enqueue the event when the record is updated" do
          Resque.should_receive(:enqueue).once.with(Riaction::EventPerformer, :make_a_comment, "Comment", @comment.id)
          @comment.content = "updated content"
          @comment.save
        end
        
        it "should try to enqueue the event only when the record is updated" do
          Resque.should_receive(:enqueue).once.with(Riaction::EventPerformer, :make_a_comment, "Comment", instance_of(Fixnum))
          comment = Comment.create(:content => "this is a comment")
          comment.content = "updated content"
          comment.save
          comment.destroy
        end
      end
      
      describe "when caused by the CRUD action 'destroy'" do
        before do
          Comment.class_eval do
            riaction :event, :name => :make_a_comment, :trigger => :destroy, :profile => :user
          end
          @comment = Comment.riactionless{ Comment.create(:content => "this is a comment") }
        end
        
        it "should try to enqueue the event when the record is destroyed" do
          Resque.should_receive(:enqueue).once.with(Riaction::EventPerformer, :make_a_comment, "Comment", @comment.id)
          @comment.destroy
        end
        
        it "should try to enqueue the event only when the record is destroyed" do
          Resque.should_receive(:enqueue).once.with(Riaction::EventPerformer, :make_a_comment, "Comment", instance_of(Fixnum))
          comment = Comment.create(:content => "this is a comment")
          comment.content = "updated content"
          comment.save
          comment.destroy
        end
      end
      
      describe "when caused by a non-crud action" do
        before do
          Comment.class_eval do
            riaction :event, :name => :make_a_comment, :trigger => :make_comment, :profile => :user
          end
          @comment = Comment.riactionless{ Comment.create(:content => "this is a comment") }
        end
        
        it "should try to enqueue the event when the provided trigger method is called" do
          Resque.should_receive(:enqueue).once.with(Riaction::EventPerformer, :make_a_comment, "Comment", @comment.id)
          @comment.trigger_make_comment!
        end
        
        it "should try to enqueue the event only when the provided trigger method is called" do
          Resque.should_receive(:enqueue).once.with(Riaction::EventPerformer, :make_a_comment, "Comment", instance_of(Fixnum))
          comment = Comment.create(:content => "this is a comment")
          comment.trigger_make_comment!
          comment.content = "updated content"
          comment.save
          comment.destroy
        end
      end
      
      describe "with a guard in place" do
        describe "being a method that returns true" do
          describe "when caused by the CRUD action 'create'" do
            before do
              Comment.class_eval do
                riaction :event, :name => :make_a_comment, :trigger => :create, :profile => :user, :if => :record_event?
                
                def record_event?
                  true
                end
              end
            end

            it "should try to enqueue the event when the record is created" do
              Resque.should_receive(:enqueue).once.with(Riaction::EventPerformer, :make_a_comment, "Comment", instance_of(Fixnum))
              Comment.create(:content => "this is a comment")
            end
          end
          
          describe "when caused by the CRUD action 'update'" do
            before do
              Comment.class_eval do
                riaction :event, :name => :make_a_comment, :trigger => :update, :profile => :user, :if => :record_event?
                
                def record_event?
                  true
                end
              end
              @comment = Comment.riactionless{ Comment.create(:content => "this is a comment") }
            end

            it "should try to enqueue the event when the record is updated" do
              Resque.should_receive(:enqueue).once.with(Riaction::EventPerformer, :make_a_comment, "Comment", @comment.id)
              @comment.content = "updated content"
              @comment.save
            end
          end

          describe "when caused by the CRUD action 'destroy'" do
            before do
              Comment.class_eval do
                riaction :event, :name => :make_a_comment, :trigger => :destroy, :profile => :user, :if => :record_event?
                
                def record_event?
                  true
                end
              end
              @comment = Comment.riactionless{ Comment.create(:content => "this is a comment") }
            end

            it "should try to enqueue the event when the record is destroyed" do
              Resque.should_receive(:enqueue).once.with(Riaction::EventPerformer, :make_a_comment, "Comment", @comment.id)
              @comment.destroy
            end
          end

          describe "when caused by a non-crud action" do
            before do
              Comment.class_eval do
                riaction :event, :name => :make_a_comment, :trigger => :make_comment, :profile => :user, :if => :record_event?
                
                def record_event?
                  true
                end
              end
              @comment = Comment.riactionless{ Comment.create(:content => "this is a comment") }
            end

            it "should try to enqueue the event when the provided trigger method is called" do
              Resque.should_receive(:enqueue).once.with(Riaction::EventPerformer, :make_a_comment, "Comment", @comment.id)
              @comment.trigger_make_comment!
            end
          end
        end
        
        describe "being a proc that returns false" do
          describe "when caused by the CRUD action 'create'" do
            before do
              Comment.class_eval do
                riaction :event, :name => :make_a_comment, :trigger => :create, :profile => :user, :if => Proc.new{ |record| false }
              end
            end

            it "should not try to enqueue the event when the record is created" do
              Resque.should_not_receive(:enqueue)
              Comment.create(:content => "this is a comment")
            end
          end
          
          describe "when caused by the CRUD action 'update'" do
            before do
              Comment.class_eval do
                riaction :event, :name => :make_a_comment, :trigger => :update, :profile => :user, :if => Proc.new{ |record| false }
              end
              @comment = Comment.riactionless{ Comment.create(:content => "this is a comment") }
            end

            it "should not try to enqueue the event when the record is updated" do
              Resque.should_not_receive(:enqueue)
              @comment.content = "updated content"
              @comment.save
            end
          end

          describe "when caused by the CRUD action 'destroy'" do
            before do
              Comment.class_eval do
                riaction :event, :name => :make_a_comment, :trigger => :destroy, :profile => :user, :if => Proc.new{ |record| false }
              end
              @comment = Comment.riactionless{ Comment.create(:content => "this is a comment") }
            end

            it "should not try to enqueue the event when the record is destroyed" do
              Resque.should_not_receive(:enqueue)
              @comment.destroy
            end
          end

          describe "when caused by a non-crud action" do
            before do
              Comment.class_eval do
                riaction :event, :name => :make_a_comment, :trigger => :make_comment, :profile => :user, :if => Proc.new{ |record| false }
              end
              @comment = Comment.riactionless{ Comment.create(:content => "this is a comment") }
            end

            it "should not try to enqueue the event when the provided trigger method is called" do
              Resque.should_not_receive(:enqueue)
              @comment.trigger_make_comment!
            end
          end
        end
      end
    end
    
    describe "and the riaction profile object associated with the event" do
      describe "when missing from the declaration entirely" do
        it "should raise a configuration error" do
          lambda {
            Comment.class_eval do
              riaction :event, :name => :make_a_comment, :trigger => :create
            end
          }.should raise_error(Riaction::ConfigurationError)
        end
      end
      
      describe "when given as the same object generating the event" do
        before do
          Comment.class_eval do
            riaction :profile, :type => :comment_player, :custom => :id
            riaction :event, :name => :make_a_comment, :trigger => :create, :profile => :self
          end
          @comment = Comment.riactionless{ Comment.create(:content => "this is a comment") }
        end
        
        it "should use that same object as the profile" do
          hash_including({
            :make_a_comment => {
              :profile => {
                :type => :comment_player,
                :id_type => :custom,
                :id => @comment.id
              },
              :params => {} 
            }
          }).should == @comment.riaction_event_params
        end
      end
      
      describe "when given as a method name" do
        before do
          Comment.class_eval do
            riaction :event, :name => :make_a_comment, :trigger => :create, :profile => :user
          end
          @comment = Comment.riactionless{ Comment.create(:user_id => @user.id, :content => 'this is a comment') }
        end
        
        it "should use object returned by that method" do
          hash_including({
            :make_a_comment => {
              :profile => {
                :type => :player,
                :id_type => :custom,
                :id => @user.id
              },
              :params => {} 
            }
          }).should == @comment.riaction_event_params
        end
      end
      
      describe "when given as a proc" do
        before do
          Comment.class_eval do
            riaction :event, :name => :make_a_comment, :trigger => :create, :profile => Proc.new{|record| record.user}
          end
          @comment = Comment.riactionless{ Comment.create(:user_id => @user.id, :content => 'this is a comment') }
        end
        
        it "should use the object returned by that proc" do
          hash_including({
            :make_a_comment => {
              :profile => {
                :type => :player,
                :id_type => :custom,
                :id => @user.id
              },
              :params => {} 
            }
          }).should == @comment.riaction_event_params
        end
      end
      
      describe "when the object given as a profile is not a valid riaction profile" do
        before do
          Comment.class_eval do
            riaction :event, :name => :make_a_comment, :trigger => :create, :profile => :self #comment does not declare itself as a profile in this case
          end
          @comment = Comment.riactionless{ Comment.create(:user_id => @user.id, :content => 'this is a comment') }
        end
        
        it "should raise a configuration error" do
          lambda{ @comment.riaction_event_params }.should raise_error(Riaction::ConfigurationError)
        end
      end
      
      describe "when the object given as a profile cannot be found" do
        before do
          Comment.class_eval do
            riaction :event, :name => :make_a_comment, :trigger => :create, :profile => :user
          end
          @comment = Comment.riactionless{ Comment.create(:content => 'this is a comment') }
        end
        
        it "should raise a runtime error" do
          lambda{ @comment.riaction_event_params }.should raise_error(Riaction::RuntimeError)
        end
      end
      
      describe "when the object given as a profile defines more than one profile type" do
        describe "and the event class does not specify which" do
          before do
            Comment.class_eval do
              riaction :event, :name => :make_a_comment, :trigger => :create, :profile => :user
            end
            @comment = Comment.riactionless{ Comment.create(:user_id => @user.id, :content => 'this is a comment') }
          end
          
          it "should use the default type for that profile class (the first defined in the class)" do
            hash_including({
              :make_a_comment => {
                :profile => {
                  :type => :player,
                  :id_type => :custom,
                  :id => @user.id
                },
                :params => {}
              }
            }).should == @comment.riaction_event_params
          end
        end
        
        describe "and the event class specifies which type" do
          before do
            Comment.class_eval do
              riaction :event, :name => :make_a_comment, :trigger => :create, :profile => :user, :profile_type => :npc
            end
            @comment = Comment.riactionless{ Comment.create(:user_id => @user.id, :content => 'this is a comment') }
          end
          
          it "should use the type specified" do
            hash_including({
              :make_a_comment => {
                :profile => {
                  :type => :npc,
                  :id_type => :username,
                  :id => @user.name
                },
                :params => {} 
              }
            }).should == @comment.riaction_event_params
          end
        end
        
        describe "and the event specifies a type that does not exist" do
          before do
            Comment.class_eval do
              riaction :event, :name => :make_a_comment, :trigger => :create, :profile => :user, :profile_type => :bogus
            end
            @comment = Comment.riactionless{ Comment.create(:user_id => @user.id, :content => 'this is a comment') }
          end

          it "should raise a configuration error" do
            lambda{ @comment.riaction_event_params }.should raise_error(Riaction::ConfigurationError)
          end
        end
      end
    end

    describe "and the params provided for an event" do
      describe "when given as a method" do
        before do
          Comment.class_eval do
            riaction :event, :name => :make_a_comment, :trigger => :create, :profile => :user, :params => :params_for_event
            
            def params_for_event
              {:apple => 'pi', :pumpkin => 'pi'}
            end
          end
          @comment = Comment.riactionless{ Comment.create(:user_id => @user.id, :content => 'this is a comment') }
        end
        
        it "should use the value returned by that method" do
          hash_including({
            :make_a_comment => {
              :profile => {
                :type => :player,
                :id_type => :custom,
                :id => @user.id
              },
              :params => @comment.params_for_event
            }
          }).should == @comment.riaction_event_params
        end
      end
      
      describe "when given as a proc" do
        before do
          Comment.class_eval do
            riaction :event, :name => :make_a_comment, :trigger => :create, :profile => :user, :params => Proc.new{|record| {:apple => 'pi', :pumpkin => 'pi'} }
          end
          @comment = Comment.riactionless{ Comment.create(:user_id => @user.id, :content => 'this is a comment') }
        end
        
        it "should use the value returned by that proc" do
          hash_including({
            :make_a_comment => {
              :profile => {
                :type => :player,
                :id_type => :custom,
                :id => @user.id
              },
              :params => {:apple => 'pi', :pumpkin => 'pi'}
            }
          }).should == @comment.riaction_event_params
        end
      end
      
      describe "when given as a simple hash" do
        before do
          Comment.class_eval do
            riaction :event, :name => :make_a_comment, :trigger => :create, :profile => :user, :params => {:apple => 'pi', :pumpkin => 'pi'}
          end
          @comment = Comment.riactionless{ Comment.create(:user_id => @user.id, :content => 'this is a comment') }
        end
        
        it "should use that same hash" do
          hash_including({
            :make_a_comment => {
              :profile => {
                :type => :player,
                :id_type => :custom,
                :id => @user.id
              },
              :params => {:apple => 'pi', :pumpkin => 'pi'}
            }
          }).should == @comment.riaction_event_params
        end
      end
      
      describe "when given as hash where some values are methods" do
        before do
          Comment.class_eval do
            riaction :event, :name => :make_a_comment, :trigger => :create, :profile => :user, :params => {:apple => 'pi', :drink => :wine}
            
            def wine
              'ruby port'
            end
          end
          @comment = Comment.riactionless{ Comment.create(:user_id => @user.id, :content => 'this is a comment') }
        end
        
        it "should use that same hash, with the methods' values in place" do
          hash_including({
            :make_a_comment => {
              :profile => {
                :type => :player,
                :id_type => :custom,
                :id => @user.id
              },
              :params => {:apple => 'pi', :drink => @comment.wine}
            }
          }).should == @comment.riaction_event_params
        end
      end
    end
    
    describe "and being disabled for a block of code" do
      before do
        Comment.class_eval do
          riaction :event, :name => :make_a_comment, :trigger => :create, :profile => :user
          riaction :event, :name => :like_a_comment, :trigger => :like, :profile => :user
        end
        @comment = Comment.riactionless{ Comment.create(:content => "this is a comment") }
      end
      
      it "should not enqueue a task to send the event when it would normally be triggered by a CRUD action" do
        Resque.should_not_receive(:enqueue)
        Comment.riactionless { Comment.create(:content => "this is a comment") }
      end
      
      it "should not enqueue a task to send the event when it would normally be triggered by a custom action" do
        Resque.should_not_receive(:enqueue)
        Comment.riactionless { @comment.trigger_like! }
      end

      it "should return the value of the block" do
          42.should == Comment.riactionless { 42 }
      end

      it "should reset even if an error is raised within the block" do
        Resque.should_receive(:enqueue).once.with(Riaction::EventPerformer, :like_a_comment, "Comment", instance_of(Fixnum))
        begin 
          Comment.riactionless do 
            raise Exception.new
          end
        rescue Exception => e
        end
        @comment.trigger_like!
      end
    end
  end
  
  after do
    ActiveRecord::Base.connection.rollback_db_transaction
    ActiveRecord::Base.connection.decrement_open_transactions
  end
end