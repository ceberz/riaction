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
      attr_accessor :recent_achievements # not always present
      attr_accessor :rank # not always present
      
      def initialize(key_values={})
        @identifiers = extract_many_as(key_values, "Identifiers", IActionable::Objects::Identifier)
        @points = extract_many_as(key_values, "Points", IActionable::Objects::ProfilePoints)
        @recent_achievements = extract_many_as(key_values, "RecentAchievements", IActionable::Objects::Achievement)
        
        super(key_values)
      end      
      
      def to_hash
        hash = {
          "DisplayName" => @display_name,
          "Identifiers" => @identifiers.map{|identifier| identifier.to_hash}
        }
        unless @points.nil?
          hash["Points"] = @points.kind_of?(Array) ? @points.map{|point| point.to_hash} : @points
        end
        hash["RecentAchievements"] = @recent_achievements.map{|recent_achievement| recent_achievement.to_hash} unless @recent_achievements.empty?
        hash["Rank"] = @rank unless @rank.nil?
        hash
      end
    end
  end
end