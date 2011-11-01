require 'riaction/iactionable/objects/i_actionable_object.rb'
require 'riaction/iactionable/objects/identifier.rb'
require 'riaction/iactionable/objects/profile_points.rb'
require 'riaction/iactionable/objects/achievement.rb'

module IActionable
  module Objects
    class ProfileSummary < IActionableObject
      attr_accessor :display_name
      attr_accessor :identifiers
      attr_accessor :points
      attr_accessor :recent_achievements
      attr_accessor :rank
      
      def initialize(key_values={})
        @identifiers = extract_many_as(key_values, "Identifiers", IActionable::Objects::Identifier)
        @points = extract_many_as(key_values, "Points", IActionable::Objects::ProfilePoints)
        @recent_achievements = extract_many_as(key_values, "RecentAchievements", IActionable::Objects::Achievement)
        
        super(key_values)
      end      
    end
  end
end