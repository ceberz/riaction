require "active_support"
require "active_record"
require 'riaction/event_performer'
require 'riaction/profile_creator'
require 'riaction/profile_creation_callback'
require 'riaction/crud_event_callback'

module Riaction
  def self.supported_identifier_types
    [:email,:username,:custom,:facebook,:twitter]
  end
  
  class RuntimeError < StandardError; end
  class ConfigurationError < StandardError; end
  class NoEventDefined < StandardError; end
  class NoProfileDefined < StandardError; end
  
  module Riaction
    PROFILE_CLASSES = []
    EVENT_LOGGING_CLASSES = []
    
    module ClassMethods
      def riaction(object_type, opts)
        establish_riactionary_class unless riactionary?
        if object_type == :profile
          establish_riactionary_profile_class unless riaction_profile?
          add_or_update_riaction_profile(opts.delete(:type), opts)
        end
      end

      def establish_riactionary_class
        class << self
          def riactionary?
            true
          end
          
          def riactionless?
            @riactionless ||= false
          end
          
          def riaction_profile_keys
            @riaction_profile_keys ||= {}
          end
          
          def riaction_events
            @riaction_events ||= {}
          end
          
          def riaction_use_profile
            @riaction_use_profile ||= nil
          end
          
          def riactionless(&block)
            if block_given?
              @riactionless = true
              begin
                block_value = yield
              ensure
                @riactionless = false
              end
            end
          end
          
          def reset_riaction
            riaction_profile_keys.clear
            riaction_events.clear
            @riaction_use_profile = nil
          end
          
          def add_or_update_riaction_profile(type, opts)
            display_name_option = opts.delete(:display_name)
            unless opts.keys.any?{|type| ::Riaction.supported_identifier_types.include?(type)}
              raise ConfigurationError.new("#{self.to_s} defining a riaction profile must use supported IActionable types: #{::Riaction.supported_identifier_types.map(&:to_s).join(", ")}")
            end
            riaction_profile_keys.store(type, {
              :display_name => display_name_option,
              :identifiers => opts
            })
            @riaction_use_profile = type
          end
          
          def riaction_profile_types_defined
            riaction_profile_keys.size
          end
        end
        
        include ::Riaction::Riaction::InstanceMethods
      end

      def establish_riactionary_profile_class
        (::Riaction::Riaction::PROFILE_CLASSES << self.to_s).uniq!

        class << self
          def riaction_profile?
            true
          end
        end

        include ::Riaction::Riaction::Profile::InstanceMethods

        after_create ::Riaction::ProfileCreationCallback.new({})
      end

      def riactionary?
        false
      end
      
      def riaction_profile?
        false
      end
      
      def riaction_events?
        false
      end
    end
    
    module InstanceMethods
      def riaction_resolve_param(poly)
        case poly
        when Symbol
          self.send poly
        when Proc
          poly.yield self
        when Hash
          resolved_hash = {}
          poly.each_pair do |key, value|
            resolved_hash[key] = self.respond_to?(value) ? self.send(value) : value
          end
          resolved_hash
        else 
          poly
        end
      end
    end
    
    module Profile
      module InstanceMethods
        def riaction_profile_keys
          resolved_hash = {}
          self.class.riaction_profile_keys.each_pair do |profile_type, opts|
            resolved_hash[profile_type] = {}
            opts.fetch(:identifiers, {}).each_pair do |identifier_type, value|
              resolved_hash[profile_type][identifier_type] = riaction_resolve_param(value)
            end
          end
          resolved_hash
        end
        
        def riaction_set_profile(type)
          raise RuntimeError.new("#{self.to_s} does not define a profile type #{type}") unless riaction_profile_keys.has_key?(type)
          @riaction_use_profile = type
          self
        end
        
        #################
        #  API wrappers #
        #################

        def riaction_profile_summary(achievement_count=nil)
          @iactionable_api ||= IActionable::Api.new
          keys = riaction_profile_keys.fetch(riaction_use_profile)
          @iactionable_api.get_profile_summary(riaction_use_profile.to_s, keys.first[0].to_s, keys.first[1].to_s, achievement_count)
        rescue KeyError => e
          raise RuntimeError.new("#{self.to_s} does not define a profile type #{riaction_use_profile}")
        rescue IActionable::Error::BadRequest => e
          nil
        end

        def riaction_profile_achievements(filter_type=nil)
          @iactionable_api ||= IActionable::Api.new
          keys = riaction_profile_keys.fetch(riaction_use_profile)
          @iactionable_api.get_profile_achievements(riaction_use_profile.to_s, keys.first[0].to_s, keys.first[1].to_s, filter_type)
        rescue KeyError => e
          raise RuntimeError.new("#{self.to_s} does not define a profile type #{riaction_use_profile}")
        rescue IActionable::Error::BadRequest => e
          nil
        end

        def riaction_profile_challenges(filter_type=nil)
          @iactionable_api ||= IActionable::Api.new
          keys = riaction_profile_keys.fetch(riaction_use_profile)
          @iactionable_api.get_profile_challenges(riaction_use_profile.to_s, keys.first[0].to_s, keys.first[1].to_s, filter_type)
        rescue KeyError => e
          raise RuntimeError.new("#{self.to_s} does not define a profile type #{riaction_use_profile}")
        rescue IActionable::Error::BadRequest => e
          nil
        end

        def riaction_profile_goals(filter_type=nil)
          @iactionable_api ||= IActionable::Api.new
          keys = riaction_profile_keys.fetch(riaction_use_profile)
          @iactionable_api.get_profile_goals(riaction_use_profile.to_s, keys.first[0].to_s, keys.first[1].to_s, filter_type)
        rescue KeyError => e
          raise RuntimeError.new("#{self.to_s} does not define a profile type #{riaction_use_profile}")
        rescue IActionable::Error::BadRequest => e
          nil
        end

        def riaction_profile_notifications
          @iactionable_api ||= IActionable::Api.new
          keys = riaction_profile_keys.fetch(riaction_use_profile)
          @iactionable_api.get_profile_notifications(riaction_use_profile.to_s, keys.first[0].to_s, keys.first[1].to_s)
        rescue KeyError => e
          raise RuntimeError.new("#{self.to_s} does not define a profile type #{riaction_use_profile}")
        rescue IActionable::Error::BadRequest => e
          nil
        end

        def riaction_profile_points(point_type)
          @iactionable_api ||= IActionable::Api.new
          keys = riaction_profile_keys.fetch(riaction_use_profile)
          @iactionable_api.get_profile_points(riaction_use_profile.to_s, keys.first[0].to_s, keys.first[1].to_s, point_type)
        rescue KeyError => e
          raise RuntimeError.new("#{self.to_s} does not define a profile type #{riaction_use_profile}")
        rescue IActionable::Error::BadRequest => e
          nil
        end

        def riaction_update_profile_points(point_type, amount, reason="")
          @iactionable_api ||= IActionable::Api.new
          keys = riaction_profile_keys.fetch(riaction_use_profile)
          @iactionable_api.update_profile_points(riaction_use_profile.to_s, keys.first[0].to_s, keys.first[1].to_s, point_type, amount, reason)
        rescue KeyError => e
          raise RuntimeError.new("#{self.to_s} does not define a profile type #{riaction_use_profile}")
        rescue IActionable::Error::BadRequest => e
          nil
        end
        
        private
        
        def riaction_profile_display_name
          riaction_resolve_param self.class.riaction_profile_keys.fetch(@riaction_use_profile)[:display_name]
        rescue KeyError => e
          raise RuntimeError.new("#{self.to_s} does not define a profile type #{riaction_use_profile}")
        end
        
        def riaction_use_profile
          @riaction_use_profile || self.class.riaction_use_profile
        end
      end
    end
    
    # def make_events_definable
    #   class << self
    #     def riaction_events
    #       @riaction_events ||= {}
    #     end
    #   
    #     def riaction_defines_events? 
    #       true
    #     end
    #   end
    # end
    
    # def define_event(name, trigger, profile, params = {}, guard = nil)
    #   trigger = name unless trigger
    # 
    #   # store the event
    #   riaction_events.store(name, {:trigger => trigger, :profile => profile, :params => params, :guard => guard})
    # 
    #   # Create the callback or the means to trigger it
    #   if ::Riaction::Constants.crud_actions.include? trigger
    #     send "after_#{trigger}".to_sym, ::Riaction::CrudEventCallback.new(name)
    #   
    #     define_method("trigger_#{name}!") do
    #       if self.riaction_log_event?(name)
    #         Resque.enqueue(::Riaction::EventPerformer, name, self.class.base_class.to_s, self.id)
    #       end
    #     end
    #   else
    #     define_method("trigger_#{trigger}!") do
    #       if self.riaction_log_event?(name)
    #         Resque.enqueue(::Riaction::EventPerformer, name, self.class.base_class.to_s, self.id)
    #       end
    #     end
    #   end
    # end
  
    # def define_profile(type, fields)
    #   class << self
    #     def riaction_profiles
    #       @riaction_profiles ||= {}
    #     end
    #   
    #     def riaction_profile?
    #       true
    #     end
    #   end
    #   
    #   # store the profile
    #   riaction_profiles.store(type, {:display_name_method => fields.delete(:display_name), :identifiers => fields})
    # end
  
    # def riaction_profile?
    #   false
    # end
    #   
    # def riaction_defines_events?
    #   false
    # end
    #   
    # def riaction_defines_event?(event_name)
    #   if riaction_defines_events?
    #     riaction_events[event_name].present?
    #   else
    #     false
    #   end
    # end
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
  end
end