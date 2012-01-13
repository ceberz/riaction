require 'spec_helper.rb'

describe "API response to get_goals" do
  before do
    @sample_response = [
        {
            "Key" => "easy_goal",
            "Description" => "Do something easy 5 times today and earn 100 points",
            "Name" => "Easy Goal",
            "Interval" => "Daily"
        },
        {
            "Key" => "hard_goal",
            "Description" => "Do something hard 10 times this week and earn 200 points",
            "Name" => "Hard Goal",
            "Interval" => "Daily"
        }
    ]
  end
  
  it "should not raise error on wrapping in an object" do
    lambda { @sample_response.map{|data| IActionable::Objects::Goal.new(data) } }.should_not raise_error
  end
  
  describe "when wrapped in an object" do
    before do
      @wrapped = @sample_response.map{|data| IActionable::Objects::Goal.new(data) }
    end
    
    it "should contain ar array of available goals" do
      @wrapped.should be_instance_of Array
      @wrapped.first.key.should == @sample_response[0]["Key"]
      @wrapped.first.description.should == @sample_response[0]["Description"]
      @wrapped.first.name.should == @sample_response[0]["Name"]
      @wrapped.first.interval.should == @sample_response[0]["Interval"]
      @wrapped.last.key.should == @sample_response[1]["Key"]
      @wrapped.last.description.should == @sample_response[1]["Description"]
      @wrapped.last.name.should == @sample_response[1]["Name"]
      @wrapped.last.interval.should == @sample_response[1]["Interval"]
    end

    it "should convert to a hash equal to the original" do
      hash_including(:array => @sample_response).should == {:array => @wrapped.map{|goal| goal.to_hash}}
    end
  end
end