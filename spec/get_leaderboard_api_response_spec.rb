require 'spec_helper.rb'

describe "API response to get_leaderboard" do
  before do
    @sample_response = {
        "Leaderboard" => {
            "Key" => "weekly_leaderboard",
            "Name" => "Weekly Experience Points Leaderboard"
        },
        "PageCount" => 10,
        "PageNumber" => 1,
        "PointType" => {
            "Key" => "experience_points",
            "Name" => "Experience Points"
        },
        "Profiles" => [
            {
                "DisplayName" => "Jimmy Dean",
                "Identifiers" => [
                    {
                        "ID" => "100005",
                        "IDHash" => "d63c48a193f960380f0ac353eddc25d4",
                        "IDType" => "Facebook"
                    }
                ],
                "Rank" => 1,
                "Points" => 246
            },
            {
                "DisplayName" => "Jason Barnes",
                "Identifiers" => [
                    {
                        "ID" => "100010",
                        "IDHash" => "d3d33fb3e33963b58f681ed2e98d835c",
                        "IDType" => "Facebook"
                    },
                    {
                        "ID" => "email@dot.com",
                        "IDHash" => "66a1bd06edcc1a2d208953d441e1374e",
                        "IDType" => "Email"
                    }
                ],
                "Rank" => 2,
                "Points" => 216
            },
            {
                "DisplayName" => "Ben Burt",
                "Identifiers" => [
                    {
                        "ID" => "600004",
                        "IDHash" => "e567689d28abc93867955ff85324bd08",
                        "IDType" => "Facebook"
                    }
                ],
                "Rank" => 3,
                "Points" => 50
            }
        ],
        "TotalCount" => 50
    }
  end
  
  it "should not raise error on wrapping in an object" do
    lambda { IActionable::Objects::LeaderboardReport.new(@sample_response) }.should_not raise_error
  end
  
  describe "when wrapped in an object" do
    before do
      @wrapped = IActionable::Objects::LeaderboardReport.new(Marshal.load(Marshal.dump(@sample_response)))
    end
    
    it "should convert to a hash equal to the original" do
      hash_including(@sample_response).should == @wrapped.to_hash
    end
  end
end