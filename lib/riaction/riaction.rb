require "riaction/config"
require "active_support"

#there has to be a more elegant way to do this? Push to bundler?
if Riaction::Config.new().orm == :active_record
  require "active_record"
end

require 'riaction/event_performer'
require 'riaction/profile_creator'
require 'riaction/profile_creation_callback'
require 'riaction/crud_event_callback'

module Riaction
  class RuntimeError < StandardError; end
  class ConfigurationError < StandardError; end
  class NoEventDefined < StandardError; end
  class NoProfileDefined < StandardError; end

  module Riaction
    PROFILE_CLASSES = []
    EVENT_CLASSES = []

    module ClassMethods
      def riaction(type, opts)
        establish_riactionary_class unless riactionary?
        if type == :profile
          establish_riactionary_profile_class unless riaction_profile?
          add_or_update_riaction_profile(opts.delete(:type), opts)
        elsif type == :event
          establish_riactionary_event_class unless riaction_events?
          add_or_update_riaction_event(opts.delete(:name), opts)
        elsif type == :option || type == :options
          opts.each_pair do |option, value|
            if ::Riaction::Constants.riaction_options.has_key?(option)
              # merge hashes, replace all else;
              if riaction_options[option].is_a? Hash
                riaction_options[option].merge! value
              else
                riaction_options[option] = value
              end
            end
          end
        end
      end

      # Patches a class to turn it into a riactionary class, providing some default checks and attributes
      def establish_riactionary_class
        class << self

          # returns true if a class has riaction setup
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

          def riaction_options
            @riaction_options ||= ::Riaction::Constants.riaction_options
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
            riaction_options.merge!(::Riaction::Constants.riaction_options)
            @riaction_use_profile = nil
          end

          def add_or_update_riaction_profile(type, opts)
            display_name = opts.delete(:display_name) || nil
            riaction_check_type(:display_name, display_name, [Symbol, Proc, NilClass])
            unless opts.keys.any?{|type| ::Riaction::Constants.supported_identifier_types.include?(type)}
              raise ConfigurationError.new("#{self.to_s} defining a riaction profile must use supported IActionable types: #{::Riaction::Constants.supported_identifier_types.map(&:to_s).join(", ")}")
            end
            riaction_profile_keys.store(type, {
              :display_name => display_name,
              :identifiers => opts
            })
            @riaction_use_profile ||= type
          end

          def add_or_update_riaction_event(name, opts)
            # set values
            trigger = opts.delete(:trigger) || :create
            profile = opts.delete(:profile)
            profile_type = opts.delete(:profile_type)
            params = opts.delete(:params) || {}
            guard = opts.delete(:if) || opts.delete(:guard) || true
            # check for required types and presence
            if profile.nil?
              raise ConfigurationError.new("#{self.to_s} defining a riaction event must provide a profile")
            end
            riaction_check_type(:trigger, trigger, [Symbol])
            riaction_check_type(:profile, profile, [Symbol, Proc])
            riaction_check_type(:profile_type, profile_type, [Symbol, NilClass])
            riaction_check_type(:params, params, [Symbol, Proc, Hash])
            riaction_check_type(:guard, guard, [Symbol, Proc, TrueClass])
            # store our event data
            riaction_events.store(name, {
              :trigger => trigger,
              :profile => profile,
              :profile_type => profile_type,
              :params => params,
              :guard => guard
            })
            # create necessary callbacks and instance methods for triggers
            if ::Riaction::Constants.crud_actions.include? trigger
              send "after_#{trigger}".to_sym, ::Riaction::CrudEventCallback.new(name)
            else
              define_method("trigger_#{trigger}!") do
                if self.riaction_log_event?(name) && !self.class.riactionless?
                  Resque.enqueue(::Riaction::EventPerformer, name, self.class.base_class.to_s, self.id)
                end
              end
            end
          end

          def riaction_profile_types_defined
            riaction_profile_keys.size
          end

          def riaction_events_defined
            riaction_events.size
          end

          def riaction_check_type(name, value, allowed_types)
            unless allowed_types.any?{|type| value.is_a?(type)}
              raise ConfigurationError.new("value given for #{name} must be of types: #{allowed_types.map(&:to_s).join(', ')}")
            end
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

        after_create ::Riaction::ProfileCreationCallback.new
      end

      def establish_riactionary_event_class
        (::Riaction::Riaction::EVENT_CLASSES << self.to_s).uniq!

        class << self
          def riaction_events?
            true
          end

          def riaction_defines_event?(event_name)
            riaction_events.has_key? event_name
          end
        end

        include ::Riaction::Riaction::Event::InstanceMethods
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
          if poly == :self
            self
          else
            self.send poly
          end
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

        def riaction_profile_display_name
          riaction_resolve_param self.class.riaction_profile_keys.fetch(riaction_use_profile)[:display_name]
        rescue KeyError => e
          raise RuntimeError.new("#{self.to_s} does not define a profile type #{riaction_use_profile}")
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

        def riaction_use_profile
          @riaction_use_profile || self.class.riaction_use_profile
        end
      end
    end

    module Event
      module InstanceMethods
        def riaction_event_params
          resolved_hash = {}
          self.class.riaction_events.each_pair do |event_name, args|
            resolved_profile = riaction_resolve_param(args[:profile])
            if  resolved_profile.nil? ||
                !resolved_profile.kind_of?(ActiveRecord::Base) ||
                !resolved_profile.class.riactionary? ||
                !resolved_profile.class.riaction_profile? ||
                resolved_profile.class.riaction_profile_types_defined == 0
              next
            else
              resolved_hash[event_name] = {}
            end
            profile_keys = resolved_profile.riaction_profile_keys
            unless args[:profile_type].nil?
              if profile_keys[args[:profile_type]].nil?
                raise ConfigurationError.new("#{resolved_profile.class} does not define profile type #{args[:profile_type]} (see event #{event_name} on #{self.class})")
              else
                resolved_hash[event_name][:profile] = {
                  :type => args[:profile_type],
                  :id_type => profile_keys[args[:profile_type]].first.first,
                  :id => profile_keys[args[:profile_type]].first.last
                }
              end
            else
              resolved_hash[event_name][:profile] = {
                :type => profile_keys.first.first,
                :id_type => profile_keys.first.last.first.first,
                :id => profile_keys.first.last.first.last
              }
            end
            resolved_hash[event_name][:params] = riaction_resolve_param(args[:params]).merge(riaction_resolve_param(self.class.riaction_options[:default_event_params]))
          end
          resolved_hash
        end

        def riaction_log_event?(name)
          riaction_resolve_param self.class.riaction_events.fetch(name)[:guard]
        rescue KeyError
          raise ConfigurationError.new("#{self.class} does not define an event named '#{name}'")
        end
      end
    end
  end
end