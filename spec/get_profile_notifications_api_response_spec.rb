require 'spec_helper.rb'

describe "API response to get_profile_notifications" do
  before do
    @sample_response = {
        "Achievements" => {
            "Available" => [ ],
            "Completed" => [
                {
                    "Description" => "Achieve the impossible",
                    "ImageURL" => "http://iactionable.blob.core.windows.net/achievementimages/99999",
                    "Key" => "mission_impossible",
                    "Name" => "Mission Impossible"
                }
            ]
        },
        "Challenges" => {
            "Available" => [ ],
            "Completed" => [
                {
                    "Description" => "Do something extraordinary",
                    "Key" => "super_challenge",
                    "Name" => "Super Challenge"
                }
            ]
        },
        "Goals" => {
            "Available" => [ ],
            "Completed" => [
                {
                    "Description" => "Complete an awesome goal",
                    "Key" => "awesome_goal",
                    "Name" => "Awesome Goal"
                }
            ]
        },
        "Levels" => [
                {
                    "LevelType" => {
                        "Key" => "player_experience_points",
                        "Name" => "Player Experience Points"
                    },
                    "Name" => "Noobie",
                    "Number" => 2,
                    "RequiredPoints" => 10
                }
            ],
        "Points" => [
                {
                    "PointType" => {
                        "Key" => "experience_points",
                        "Name" => "Experience Points"
                    },
                    "Points" => 20,
                    "Reason" => "Achieve the impossible"
                }
            ]
        }
  end
  
  it "should not raise error on wrapping in an object" do
    lambda { IActionable::Objects::ProfileNotifications.new(@sample_response) }.should_not raise_error
  end
  
  describe "when wrapped in an object" do
    before do
      @wrapped = IActionable::Objects::ProfileNotifications.new(Marshal.load(Marshal.dump(@sample_response)))
    end
    
    
    it "should convert to a hash equal to the original" do
      hash_including(@sample_response).should == @wrapped.to_hash
    end
  end
end