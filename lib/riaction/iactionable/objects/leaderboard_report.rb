require 'riaction/iactionable/objects/i_actionable_object.rb'
require 'riaction/iactionable/objects/leaderboard.rb'


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
    end
  end
end