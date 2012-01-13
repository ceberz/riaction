require 'spec_helper.rb'

describe "API response to get_achievements" do
  before do
    @sample_response = [
        {
            "Key" => "opinionated_gold",
            "Description" => "Leave 25 comments.",
            "ImageURL" => "http://iactionable.blob.core.windows.net/achievementimages/33333",
            "Name" => "Opinionated - Gold"
        },
        {
            "Key" => "opinionated_silver",
            "Description" => "Make 10 comments.",
            "ImageURL" => "http://iactionable.blob.core.windows.net/achievementimages/44444",
            "Name" => "Opinionated - Silver"
        }
    ]
  end
  
  it "should not raise error on wrapping in an object" do
    lambda { @sample_response.map{|data| IActionable::Objects::Achievement.new(data) } }.should_not raise_error
  end
  
  describe "when wrapped in an object" do
    before do
      @wrapped = @sample_response.map{|data| IActionable::Objects::Achievement.new(data) }
    end
    
    it "should contain ar array of available achievements" do
      @wrapped.should be_instance_of Array
      @wrapped.first.key.should == @sample_response[0]["Key"]
      @wrapped.first.description.should == @sample_response[0]["Description"]
      @wrapped.first.image_url.should == @sample_response[0]["ImageURL"]
      @wrapped.first.name.should == @sample_response[0]["Name"]
      @wrapped.last.key.should == @sample_response[1]["Key"]
      @wrapped.last.description.should == @sample_response[1]["Description"]
      @wrapped.last.image_url.should == @sample_response[1]["ImageURL"]
      @wrapped.last.name.should == @sample_response[1]["Name"]
    end

    it "should convert to a hash equal to the original" do
      hash_including(:array => @sample_response).should == {:array => @wrapped.map{|achievement| achievement.to_hash}}
    end
  end
end