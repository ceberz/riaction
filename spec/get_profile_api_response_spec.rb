require 'spec_helper.rb'

describe "API response to get_profile" do
  before do
    @sample_response = {
        "DisplayName" => "Jason",
        "Identifiers" => [
            {
                "ID" => "jason@example.com",
                "IDHash" => "eba69e62f8bc92297b7a97659b5d6130",
                "IDType" => "Email"
            }
        ],
        "Points" => [
            {
                "Level" => {
                    "Current" => {
                        "LevelType" => {
                            "Key" => "player_experience_level",
                            "Name" => "Experience Level"
                        },
                        "Name" => "Noobie",
                        "Number" => 1,
                        "RequiredPoints" => 10
                    },
                    "Next" => {
                        "LevelType" => {
                            "Key" => "player_experience_level",
                            "Name" => "Experience Level"
                        },
                        "Name" => "Expert",
                        "Number" => 2,
                        "RequiredPoints" => 100
                    },
                },
                "PointType" => {
                    "Key" => "experience_points",
                    "Name" => "Experience Points"
                },
                "Points" => 12
            }
        ],
        "RecentAchievements" => [
            {
                "Key" => "i_love_stuff",
                "Description" => "Favorite 10 Items",
                "ImageURL" => "http://iactionable.blob.core.windows.net/achievementimages/9999",
                "Name" => "I love stuff!"
            }
        ]
    }
  end
  
  it "should not raise error on wrapping in an object" do
    lambda { IActionable::Objects::ProfileSummary.new(@sample_response) }.should_not raise_error
  end
  
  describe "when wrapped in an object" do
    before do
      @wrapped = IActionable::Objects::ProfileSummary.new(Marshal.load(Marshal.dump(@sample_response)))
    end
    
    it "should contain the display name" do
      @wrapped.display_name.should == @sample_response["DisplayName"]
    end
    
    it "should contain ar array of identifiers" do
      @wrapped.identifiers.should be_instance_of Array
      @wrapped.identifiers.first.id.should == @sample_response["Identifiers"][0]["ID"]
      @wrapped.identifiers.first.id_hash.should == @sample_response["Identifiers"][0]["IDHash"]
      @wrapped.identifiers.first.id_type.should == @sample_response["Identifiers"][0]["IDType"]
    end
    
    it "should contain an array of point summaries" do
      @wrapped.points.should be_instance_of Array
      @wrapped.points.first.points.should == @sample_response["Points"][0]["Points"]
      @wrapped.points.first.point_type.key.should == @sample_response["Points"][0]["PointType"]["Key"]
      @wrapped.points.first.point_type.name.should == @sample_response["Points"][0]["PointType"]["Name"]
      @wrapped.points.first.level.current.name.should == @sample_response["Points"][0]["Level"]["Current"]["Name"]
      @wrapped.points.first.level.current.number.should == @sample_response["Points"][0]["Level"]["Current"]["Number"]
      @wrapped.points.first.level.current.required_points.should == @sample_response["Points"][0]["Level"]["Current"]["RequiredPoints"]
      @wrapped.points.first.level.current.level_type.key.should == @sample_response["Points"][0]["Level"]["Current"]["LevelType"]["Key"]
      @wrapped.points.first.level.current.level_type.name.should == @sample_response["Points"][0]["Level"]["Current"]["LevelType"]["Name"]
      @wrapped.points.first.level.next.name.should == @sample_response["Points"][0]["Level"]["Next"]["Name"]
      @wrapped.points.first.level.next.number.should == @sample_response["Points"][0]["Level"]["Next"]["Number"]
      @wrapped.points.first.level.next.required_points.should == @sample_response["Points"][0]["Level"]["Next"]["RequiredPoints"]
      @wrapped.points.first.level.next.level_type.key.should == @sample_response["Points"][0]["Level"]["Next"]["LevelType"]["Key"]
      @wrapped.points.first.level.next.level_type.name.should == @sample_response["Points"][0]["Level"]["Next"]["LevelType"]["Name"]
    end
    
    it "should contain an array of recent achievements" do
      @wrapped.recent_achievements.should be_instance_of Array
      @wrapped.recent_achievements.first.key.should == @sample_response["RecentAchievements"][0]["Key"]
      @wrapped.recent_achievements.first.description.should == @sample_response["RecentAchievements"][0]["Description"]
      @wrapped.recent_achievements.first.image_url.should == @sample_response["RecentAchievements"][0]["ImageURL"]
      @wrapped.recent_achievements.first.name.should == @sample_response["RecentAchievements"][0]["Name"]
    end
    
    it "should convert to a hash equal to the original" do
      hash_including(@sample_response).should == @wrapped.to_hash
    end
  end
end