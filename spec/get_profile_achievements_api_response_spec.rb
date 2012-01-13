require 'spec_helper.rb'

describe "API response to get_profile_achievements" do
  before do
    @sample_response = {
        "Available" => [
            {
                "Key" => "super_user",
                "Description" => "Post 35 Photos and make 50 Comments",
                "ImageURL" => "http://iactionable.blob.core.windows.net/achievementimages/99999",
                "Name" => "Super User",
                "Progress" => [
                    {
                        "ConditionMetDate" => nil,
                        "CurrentValue" => 12,
                        "Description" => "Post 35 Photos",
                        "RequiredValue" => "35"
                    },
                    {
                        "ConditionMetDate" => nil,
                        "CurrentValue" => 6,
                        "Description" => "Make 50 Comments",
                        "RequiredValue" => "50"
                    }
                ]
            }
        ],
        "Completed" => [
            {
                "Key" => "you_can_talk",
                "Description" => "Post a Comment on any blog post.",
                "ImageURL" => "http://iactionable.blob.core.windows.net/achievementimages/99998",
                "Name" => "You can talk!",
                "Progress" => [
                    {
                        "ConditionMetDate" => "/Date(1275706032317-0600)/",
                        "CurrentValue" => 1,
                        "Description" => "Make 1 Comment",
                        "RequiredValue" => "1"
                    }
                ],
                "AwardDate" => "/Date(1275706032317-0600)/"
            }
        ]
    }
  end
  
  it "should not raise error on wrapping in an object" do
    lambda { IActionable::Objects::ProfileAchievements.new(@sample_response) }.should_not raise_error
  end
  
  describe "when wrapped in an object" do
    before do
      @wrapped = IActionable::Objects::ProfileAchievements.new(Marshal.load(Marshal.dump(@sample_response)))
    end
    
    it "should contain ar array of available achievements" do
      @wrapped.available.should be_instance_of Array
      @wrapped.available.first.key.should == @sample_response["Available"][0]["Key"]
      @wrapped.available.first.description.should == @sample_response["Available"][0]["Description"]
      @wrapped.available.first.image_url.should == @sample_response["Available"][0]["ImageURL"]
      @wrapped.available.first.name.should == @sample_response["Available"][0]["Name"]
      @wrapped.available.first.award_date.should be_nil
    end
    
    it "should contain an array of progresses within each available achievement" do
      @wrapped.available.first.progress.should be_instance_of Array
      @wrapped.available.first.progress.first.condition_met_date.should be_nil
      @wrapped.available.first.progress.first.current_value.should == @sample_response["Available"][0]["Progress"][0]["CurrentValue"]
      @wrapped.available.first.progress.first.description.should == @sample_response["Available"][0]["Progress"][0]["Description"]
      @wrapped.available.first.progress.first.required_value.should == @sample_response["Available"][0]["Progress"][0]["RequiredValue"]      
      @wrapped.available.first.progress.last.condition_met_date.should be_nil
      @wrapped.available.first.progress.last.current_value.should == @sample_response["Available"][0]["Progress"][1]["CurrentValue"]
      @wrapped.available.first.progress.last.description.should == @sample_response["Available"][0]["Progress"][1]["Description"]
      @wrapped.available.first.progress.last.required_value.should == @sample_response["Available"][0]["Progress"][1]["RequiredValue"]
    end
    
    it "should contain ar array of completed achievements" do
      @wrapped.completed.should be_instance_of Array
      @wrapped.completed.first.key.should == @sample_response["Completed"][0]["Key"]
      @wrapped.completed.first.description.should == @sample_response["Completed"][0]["Description"]
      @wrapped.completed.first.image_url.should == @sample_response["Completed"][0]["ImageURL"]
      @wrapped.completed.first.name.should == @sample_response["Completed"][0]["Name"]
      @wrapped.completed.first.award_date.should_not be_nil
    end
    
    it "should contain an array of progresses within each completed achievement" do
      @wrapped.completed.first.progress.should be_instance_of Array
      @wrapped.completed.first.progress.first.condition_met_date.should_not be_nil
      @wrapped.completed.first.progress.first.current_value.should == @sample_response["Completed"][0]["Progress"][0]["CurrentValue"]
      @wrapped.completed.first.progress.first.description.should == @sample_response["Completed"][0]["Progress"][0]["Description"]
      @wrapped.completed.first.progress.first.required_value.should == @sample_response["Completed"][0]["Progress"][0]["RequiredValue"]      
    end
    
    it "should convert to a hash equal to the original" do
      hash_including(@sample_response).should == @wrapped.to_hash
    end
  end
end