module IActionable
  module Objects
    class LeaderboardReport < IActionableObject
      attr_accessor :page_count
      attr_accessor :page_number
      attr_accessor :total_count
      attr_accessor :leaderboard
      attr_accessor :point_type
      attr_accessor :profiles
      
      def initialize(key_values={})
        @leaderboard = IActionable::Objects::PointType.new(key_values.delete("Leaderboard"))
        @point_type = IActionable::Objects::PointType.new(key_values.delete("PointType"))
        @profiles = extract_many_as(key_values, "Profiles", IActionable::Objects::ProfileSummary)
        super(key_values)
      end
      
      def to_hash
        {
          "PageCount" => @page_count,
          "PageNumber" => @page_number,
          "TotalCount" => @total_count,
          "Leaderboard" => @leaderboard.to_hash,
          "PointType" => @point_type.to_hash,
          "Profiles" => @profiles.map{|profile| profile.to_hash}
        }
      end
    end
  end
end