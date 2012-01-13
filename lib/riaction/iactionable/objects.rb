module IActionable
  module Objects
  end
end

require 'riaction/iactionable/objects/i_actionable_object.rb'
require 'riaction/iactionable/objects/progress.rb'
require 'riaction/iactionable/objects/awardable.rb'

IActionable::Objects::IActionableObject.send(:include, IActionable::Objects::Awardable)

require 'riaction/iactionable/objects/achievement.rb'
require 'riaction/iactionable/objects/challenge.rb'
require 'riaction/iactionable/objects/goal.rb'
require 'riaction/iactionable/objects/identifier.rb'
require 'riaction/iactionable/objects/leaderboard.rb'
require 'riaction/iactionable/objects/leaderboard_report.rb'
require 'riaction/iactionable/objects/level_type.rb'
require 'riaction/iactionable/objects/level.rb'
require 'riaction/iactionable/objects/point_type.rb'
require 'riaction/iactionable/objects/profile_level.rb'
require 'riaction/iactionable/objects/profile_points.rb'
require 'riaction/iactionable/objects/profile_summary.rb'
require 'riaction/iactionable/objects/profile_achievements.rb'
require 'riaction/iactionable/objects/profile_challenges.rb'
require 'riaction/iactionable/objects/profile_goals.rb'
require 'riaction/iactionable/objects/profile_notifications.rb'
