require 'spec_helper.rb'

describe "API response to get_profile_points" do
  before do
    @sample_response = {
        "Level" => {
            "Current" =>
            {
                "Name" => "Beginner",
                "Number" => 1,
                "RequiredPoints" => 200,
                "LevelType" =>
                {
                    "Key" => "player_experience_level",
                    "Name" => "Experience Level"
                },
            },
            "Next" =>
            {
                "Name" => "Member",
                "Number" => 2,
                "RequiredPoints" => 300,
                "LevelType" =>
                {
                    "Key" => "player_experience_level",
                    "Name" => "Experience Level"
                },
            }
         },
        "PointType" => {
            "Key" => "experience_points",
            "Name" => "Experience Points"
        },
        "Points" => 200
    }
  end
  
  it "should not raise error on wrapping in an object" do
    lambda { IActionable::Objects::ProfilePoints.new(@sample_response) }.should_not raise_error
  end
  
  describe "when wrapped in an object" do
    before do
      @wrapped = IActionable::Objects::ProfilePoints.new(Marshal.load(Marshal.dump(@sample_response)))
    end
    
    it "should contain all the correct fields for a profile point summary" do
      @wrapped.points.should == @sample_response["Points"]
      @wrapped.point_type.key.should == @sample_response["PointType"]["Key"]
      @wrapped.point_type.name.should == @sample_response["PointType"]["Name"]
      @wrapped.level.current.name.should == @sample_response["Level"]["Current"]["Name"]
      @wrapped.level.current.number.should == @sample_response["Level"]["Current"]["Number"]
      @wrapped.level.current.required_points.should == @sample_response["Level"]["Current"]["RequiredPoints"]
      @wrapped.level.current.level_type.key.should == @sample_response["Level"]["Current"]["LevelType"]["Key"]
      @wrapped.level.current.level_type.name.should == @sample_response["Level"]["Current"]["LevelType"]["Name"]
      @wrapped.level.next.name.should == @sample_response["Level"]["Next"]["Name"]
      @wrapped.level.next.number.should == @sample_response["Level"]["Next"]["Number"]
      @wrapped.level.next.required_points.should == @sample_response["Level"]["Next"]["RequiredPoints"]
      @wrapped.level.next.level_type.key.should == @sample_response["Level"]["Next"]["LevelType"]["Key"]
      @wrapped.level.next.level_type.name.should == @sample_response["Level"]["Next"]["LevelType"]["Name"]
    end
    
    it "should convert to a hash equal to the original" do
      hash_including(@sample_response).should == @wrapped.to_hash
    end
  end
end