require 'riaction/iactionable/connection.rb'
require 'riaction/iactionable/settings.rb'
require 'riaction/iactionable/objects.rb'

module IActionable
  
  class Api
    attr :connection
    @@settings = nil
  
    def initialize
      if @@settings
        @connection = IActionable::Connection.new(@@settings)
      else
        raise IActionable::ConfigError.new("IActionable::Api cannot be initialized without credentials being set in IActionable::Api.init_settings()")
      end
    end
  
    def self.init_settings(values)
      @@settings = IActionable::Settings.new(values)
    rescue IActionable::ConfigError => e
      raise e
    end
  
    def self.settings
      @@settings
    end
  
    # =================
    # = Event Logging =
    # =================
  
    def log_event(profile_type, id_type, id, event_key, event_attrs = {})
      response = @connection.request.with_app_key.with_api_key.to("/#{profile_type}/#{id_type}/#{id}/events/#{event_key}").with_params(event_attrs).post
    end
  
    # =====================
    # = Profile API calls =
    # =====================
  
    def get_profile_summary(profile_type, id_type, id, achievement_count = nil)
      request = @connection.request.with_app_key.to("/#{profile_type}/#{id_type}/#{id}")
      request.with_params(:achievementCount => achievement_count) unless achievement_count.blank?
      response = request.get
      IActionable::Objects::ProfileSummary.new(response)
    end
  
    def create_profile(profile_type, id_type, id, display_name = nil)
      request = @connection.request.with_app_key.with_api_key.to("/#{profile_type}/#{id_type}/#{id}")
      request.with_params(:displayName => display_name) unless display_name.blank?
      request.post
    end
    alias_method :update_profile, :create_profile
  
    def add_profile_identifier(profile_type, id_type, id, alt_id_type, alt_id)
      @connection.request.with_app_key.with_api_key.to("/#{profile_type}/#{id_type}/#{id}/identifiers/#{alt_id_type}/#{alt_id}").post
    end
  
    # ====================
    # = Points API calls =
    # ====================
  
    def get_profile_points(profile_type, id_type, id, point_type)
      response = @connection.request.with_app_key.to("/#{profile_type}/#{id_type}/#{id}/points/#{point_type}").get
      IActionable::Objects::ProfilePoints.new(response)
    end
  
    def update_profile_points(profile_type, id_type, id, point_type, amount, reason = nil)
      request = @connection.request.with_app_key.with_api_key.to("/#{profile_type}/#{id_type}/#{id}/points/#{point_type}").with_params(:value => amount)
      request.with_params(:description => reason) unless reason.blank?
      response = request.post
      IActionable::Objects::ProfilePoints.new(response)
    end
  
    # =========================
    # = Achievement API calls =
    # =========================
  
    def get_profile_achievements(profile_type, id_type, id, filter_type = nil)
      request = @connection.request.with_app_key
      case filter_type
      when :completed
        request.to("/#{profile_type}/#{id_type}/#{id}/achievements/Completed")
        response = request.get
        response.map{|achievement_json| IActionable::Objects::Achievement.new(achievement_json)}
      when :available
        request.to("/#{profile_type}/#{id_type}/#{id}/achievements/Available")
        response = request.get
        response.map{|achievement_json| IActionable::Objects::Achievement.new(achievement_json)}
      else
        request.to("/#{profile_type}/#{id_type}/#{id}/achievements")
        response = request.get
        {
          :available => response["Available"].map{|achievement_json| IActionable::Objects::Achievement.new(achievement_json)},
          :completed => response["Completed"].map{|achievement_json| IActionable::Objects::Achievement.new(achievement_json)}
        }
      end
    end
  
    def get_achievements()
      response = @connection.request.with_app_key.to("/achievements").get
      response.map{|achievement_json| IActionable::Objects::Achievement.new(achievement_json)}
    rescue NoMethodError => e
      []
    end
  
    # ========================
    # = Challenges API calls =
    # ========================
  
    def get_profile_challenges(profile_type, id_type, id, filter_type = nil)
      request = @connection.request.with_app_key
      case filter_type
      when :completed
        request.to("/#{profile_type}/#{id_type}/#{id}/challenges/Completed")
        response = request.get
        response.map{|challenge_json| IActionable::Objects::Challenge.new(challenge_json)}
      when :available
        request.to("/#{profile_type}/#{id_type}/#{id}/challenges/Available")
        response = request.get
        response.map{|challenge_json| IActionable::Objects::Challenge.new(challenge_json)}
      else
        request.to("/#{profile_type}/#{id_type}/#{id}/challenges")
        response = request.get
        {
          :available => response["Available"].map{|challenge_json| IActionable::Objects::Challenge.new(challenge_json)},
          :completed => response["Completed"].map{|challenge_json| IActionable::Objects::Challenge.new(challenge_json)}
        }
      end
    end
  
    def get_challenges()
      response = @connection.request.with_app_key.to("/challenges").get
      response.map{|challenge_json| IActionable::Objects::Challenge.new(challenge_json)}
    rescue NoMethodError => e
      []
    end
  
    # ===================
    # = Goals API calls =
    # ===================
  
    def get_profile_goals(profile_type, id_type, id, filter_type = nil)
      request = @connection.request.with_app_key
      case filter_type
      when :completed
        request.to("/#{profile_type}/#{id_type}/#{id}/goals/Completed")
        response = request.get
        response.map{|goal_json| IActionable::Objects::Goal.new(goal_json)}
      when :available
        request.to("/#{profile_type}/#{id_type}/#{id}/goals/Available")
        response = request.get
        response.map{|goal_json| IActionable::Objects::Goal.new(goal_json)}
      else
        request.to("/#{profile_type}/#{id_type}/#{id}/goals")
        response = request.get
        {
          :available => response["Available"].map{|goal_json| IActionable::Objects::Goal.new(goal_json)},
          :completed => response["Completed"].map{|goal_json| IActionable::Objects::Goal.new(goal_json)}
        }
      end
    end
  
    def get_goals()
      response = @connection.request.with_app_key.to("/goals").get
      response.map{|goal_json| IActionable::Objects::Goal.new(goal_json)}
    rescue NoMethodError => e
      []
    end
  
    # =========================
    # = Leaderboard API calls =
    # =========================
  
    def get_leaderboard(profile_type, point_type, leaderboard, page_number=nil, page_count=nil, id=nil, id_type=nil)
      request = @connection.request.with_app_key.to("/#{profile_type}/leaderboards/points/#{point_type}/#{leaderboard}")
      request.with_params(:pageNumber => page_number) unless page_number.blank?
      request.with_params(:pageCount => page_count) unless page_count.blank?
      request.with_params(:id => id) unless id.blank? || id_type.blank?
      request.with_params(:idType => id_type) unless id.blank? || id_type.blank?
      response = request.get
      IActionable::Objects::LeaderboardReport.new(response)
    end
  
    # ===================================
    # = Profile Notifications API calls =
    # ===================================
  
    def get_profile_notifications(profile_type, id_type, id)
      response = @connection.request.with_app_key.to("/#{profile_type}/#{id_type}/#{id}/notifications").get
      {
        :achievements => {
          :available => response["Achievements"]["Available"].map{|a| IActionable::Objects::Achievement.new(a)},
          :completed => response["Achievements"]["Completed"].map{|a| IActionable::Objects::Achievement.new(a)}
        },
        :challenges => {
          :available => response["Challenges"]["Available"].map{|c| IActionable::Objects::Challenge.new(c)},
          :completed => response["Challenges"]["Completed"].map{|c| IActionable::Objects::Challenge.new(c)}
        },
        :goals => {
          :available => response["Goals"]["Available"].map{|g| IActionable::Objects::Goal.new(g)},
          :completed => response["Goals"]["Completed"].map{|g| IActionable::Objects::Goal.new(g)}
        },
        :levels => response["Levels"].map{|l| IActionable::Objects::Level.new(l)},
        :points => response["Points"].map{|p| IActionable::Objects::ProfilePoints.new(p)}
      }
    end
  end
end