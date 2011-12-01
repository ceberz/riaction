require 'riaction/iactionable/api'
require "active_support"
require "active_record"
require 'riaction/event_performer'
require 'riaction/profile_creator'
require 'riaction/profile_creation_callback'
require 'riaction/crud_event_callback'

module Riaction
  
  class NoEventDefined < StandardError; end
  class NoProfileDefined < StandardError; end

  module Riaction
    PROFILE_CLASSES = []
    EVENT_LOGGING_CLASSES = []
    
    def riaction(object_type, opts)
      if object_type == :profile
        unless riaction_profile?
          (PROFILE_CLASSES << self.to_s).uniq!
          define_profile(opts.delete(:type), opts)
          include Riaction::ProfileInstanceMethods
          send :after_create, ::Riaction::ProfileCreationCallback.new
        end
      elsif object_type == :event
        unless riaction_defines_events?
          make_events_definable
        end
        unless riaction_defines_event?(opts[:name])
          (EVENT_LOGGING_CLASSES << self.to_s).uniq!
          define_event(opts[:name], opts[:trigger], opts[:profile], opts[:params], opts[:if])
          include Riaction::EventInstanceMethods
        end
      end
    end
    
    def make_events_definable
      class << self
        def riaction_events
          @riaction_events ||= {}
        end
      
        def riaction_defines_events? 
          true
        end
      end
    end
    
    def define_event(name, trigger, profile, params = {}, guard = nil)
      trigger = name unless trigger
    
      # store the event
      riaction_events.store(name, {:trigger => trigger, :profile => profile, :params => params, :guard => guard})
    
      # Create the callback or the means to trigger it
      if ::Riaction::Constants.crud_actions.include? trigger
        send "after_#{trigger}".to_sym, ::Riaction::CrudEventCallback.new(name)
      
        define_method("trigger_#{name}!") do
          if self.riaction_log_event?(name)
            Resque.enqueue(::Riaction::EventPerformer, name, self.class.base_class.to_s, self.id)
          end
        end
      else
        define_method("trigger_#{trigger}!") do
          if self.riaction_log_event?(name)
            Resque.enqueue(::Riaction::EventPerformer, name, self.class.base_class.to_s, self.id)
          end
        end
      end
    end
  
    def define_profile(type, fields)
      class << self
        def riaction_profiles
          @riaction_profiles ||= {}
        end
      
        def riaction_profile?
          true
        end
      end
    
      # store the profile
      riaction_profiles.store(type, fields)
    end
  
    def riaction_profile?
      false
    end
  
    def riaction_defines_events?
      false
    end
  
    def riaction_defines_event?(event_name)
      if riaction_defines_events?
        riaction_events[event_name].present?
      else
        false
      end
    end
    # end

    module EventInstanceMethods
      def riaction_event(event_name)
        event = self.class.riaction_events.fetch(event_name.to_sym)
        profile = riaction_event_profile(event[:profile])
        
        unless profile.class.respond_to?(:riaction_profile?) && profile.class.riaction_profile?
          raise TypeError.new("Object defined for #{self.class} on event #{event_name} as a profile must itself declare riaction(:profile ...)")
        end
        
        params = riaction_event_params(event[:params])
        
        raise TypeError.new("Params defined for #{self.class} on event #{event_name} must be a hash") unless params.kind_of? Hash
      
        {
          :key => event_name.to_sym,
          :profile => profile,
          :params => params
        }
      rescue KeyError => e
        raise NoEventDefined.new("no such event #{event_name} defined on #{self.class}")
      end
    
      def riaction_log_event?(event_name)
        event = self.class.riaction_events.fetch(event_name.to_sym)
        guard = event[:guard]
      
        case guard
        when NilClass
          true
        when Symbol
          self.send guard
        when Proc
          guard.call self
        else 
          true
        end
      rescue KeyError => e
        raise NoEventDefined.new("no such event #{event_name} defined on #{self.class}")
      end
    
      private
    
      def riaction_event_profile(profile)
        if profile == :self
          self
        elsif profile.kind_of? Symbol
          self.send(profile)
        elsif profile.kind_of? Proc
          profile.call
        else
          nil
        end
      rescue Exception => e
        raise
      end
    
      def riaction_event_params(params)
        if params.kind_of? Symbol
          self.send(params)
        elsif params.kind_of? Proc
          params.call
        elsif params.kind_of? Hash
          resolved_params = {}
          params.each_pair do |key, value|
            resolved_params[key] = self.respond_to?(value) ? self.send(value) : value
          end
          resolved_params
        else
          {}
        end
      rescue Exception => e
        raise
      end
    end

    module ProfileInstanceMethods
      def riaction_profile_keys(profile_type=nil, id_type=nil)
        if self.class.riaction_profiles.size > 0
          if profile_type && self.class.riaction_profiles.has_key?(profile_type)
            ids = self.class.riaction_profiles.fetch(profile_type)
          else
            profile_type = self.class.riaction_profiles.first[0]
            ids = self.class.riaction_profiles.first[1]
          end
      
          if id_type && ids.has_key?(id_type)
            {:profile_type => profile_type.to_s, :id_type => id_type.to_s, :id => self.send(ids.fetch(id_type)).to_s}
          else
            {:profile_type => profile_type.to_s, :id_type => ids.first[0].to_s, :id => self.send(ids.first[1]).to_s}
          end
        else
          {}
        end
      rescue KeyError, NoMethodError => e
        {}
      end
    
      #################
      #  API wrappers #
      #################
    
      def riaction_profile_summary(achievement_count=nil)
        keys = riaction_profile_keys
        unless keys.empty?
          @iactionable_api ||= IActionable::Api.new
          @iactionable_api.get_profile_summary(keys[:profile_type], keys[:id_type], keys[:id], achievement_count)
        else
          raise NoProfileDefined.new("Class #{self.class} does not adequately define itself as an IActionable profile")
        end
      rescue IActionable::Error::BadRequest => e
        nil
      end
    
      def riaction_create_profile
        keys = riaction_profile_keys
        unless keys.empty?
          existing = riaction_profile_summary
          unless existing
            @iactionable_api ||= IActionable::Api.new
            @iactionable_api.create_profile(keys[:profile_type], keys[:id_type], keys[:id])
          else
            existing
          end
        else
          raise NoProfileDefined.new("Class #{self.class} does not adequately define itself as an IActionable profile")
        end
      end
    
      def riaction_update_profile(new_id_type)
        old_keys = riaction_profile_keys
        new_keys = riaction_profile_keys(old_keys[:profile_type], new_id_type)
        unless old_keys.empty? || new_keys.empty?
          @iactionable_api ||= IActionable::Api.new
          @iactionable_api.add_profile_identifier(old_keys[:profile_type], old_keys[:id_type], old_keys[:id], new_keys[:id_type], new_keys[:id])
        else
          raise NoProfileDefined.new("Class #{self.class} does not adequately define itself as an IActionable profile")
        end
      end
    
      def riaction_profile_achievements(filter_type=nil)
        keys = riaction_profile_keys
        unless keys.empty?
          @iactionable_api ||= IActionable::Api.new
          @iactionable_api.get_profile_achievements(keys[:profile_type], keys[:id_type], keys[:id], filter_type)
        else
          raise NoProfileDefined.new("Class #{self.class} does not adequately define itself as an IActionable profile")
        end
      rescue IActionable::Error::BadRequest => e
        nil
      end
    
      def riaction_profile_challenges(filter_type=nil)
        keys = riaction_profile_keys
        unless keys.empty?
          @iactionable_api ||= IActionable::Api.new
          @iactionable_api.get_profile_challenges(keys[:profile_type], keys[:id_type], keys[:id], filter_type)
        else
          raise NoProfileDefined.new("Class #{self.class} does not adequately define itself as an IActionable profile")
        end
      rescue IActionable::Error::BadRequest => e
        nil
      end
    
      def riaction_profile_goals(filter_type=nil)
        keys = riaction_profile_keys
        unless keys.empty?
          @iactionable_api ||= IActionable::Api.new
          @iactionable_api.get_profile_goals(keys[:profile_type], keys[:id_type], keys[:id], filter_type)
        else
          raise NoProfileDefined.new("Class #{self.class} does not adequately define itself as an IActionable profile")
        end
      rescue IActionable::Error::BadRequest => e
        nil
      end
    
      def riaction_profile_notifications
        keys = riaction_profile_keys
        unless keys.empty?
          @iactionable_api ||= IActionable::Api.new
          @iactionable_api.get_profile_notifications(keys[:profile_type], keys[:id_type], keys[:id])
        else
          raise NoProfileDefined.new("Class #{self.class} does not adequately define itself as an IActionable profile")
        end
      rescue IActionable::Error::BadRequest => e
        nil
      end
    end
  end
end

ActiveRecord::Base.extend ::Riaction::Riaction