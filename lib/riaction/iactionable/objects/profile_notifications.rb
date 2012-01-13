module IActionable
  module Objects
    class ProfileNotifications < IActionableObject
      attr_accessor :achievements
      attr_accessor :challenges
      attr_accessor :goals
      attr_accessor :levels
      attr_accessor :points
      
      def initialize(key_values={})
        @achievements = IActionable::Objects::ProfileAchievements.new(key_values.delete("Achievements"))
        @challenges = IActionable::Objects::ProfileChallenges.new(key_values.delete("Challenges"))
        @goals = IActionable::Objects::ProfileGoals.new(key_values.delete("Goals"))
        @levels = extract_many_as(key_values, "Levels", IActionable::Objects::Level)
        @points = extract_many_as(key_values, "Points", IActionable::Objects::ProfilePoints)
      end
      
      def to_hash
        {
          "Achievements" => @achievements.to_hash,
          "Challenges" => @challenges.to_hash,
          "Goals" => @goals.to_hash,
          "Levels" => @levels.map{|level| level.to_hash},
          "Points" => @points.map{|point| point.to_hash}
        }
      end
    end
  end
end