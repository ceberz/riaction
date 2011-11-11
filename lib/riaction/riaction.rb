require 'riaction/iactionable/api.rb'

require "active_support"
require "active_record"
require "resque"

module Riaction
  PROFILE_CLASSES = []
  EVENT_LOGGING_CLASSES = []
  
  class NoEventDefined < StandardError; end
  class NoProfileDefined < StandardError; end
  
  def self.included(base)
    base.extend(ClassMethods)  
  end
  
  def self.crud_actions
    Set.new [:create, :update, :destroy]
  end
  
  def self.retry_attempts_for_internal_error
    3
  end
  
  class ProfileCreator
    @queue = :riaction_profile_creator
    
    def self.perform(klass_name, id, attempt=0)
      if klass_name.constantize.riaction_profile?      
        iactionable_api = IActionable::Api.new
        profile_object = klass_name.constantize.find_by_id!(id)
        profile_keys = profile_object.riaction_profile_keys
        iactionable_api.create_profile(profile_keys[:profile_type], profile_keys[:id_type], profile_keys[:id])
      else
        raise NoProfileDefined.new
      end
    rescue ActiveRecord::RecordNotFound => e
      # event_object no longer exists; no means to recover
    rescue IActionable::Error::BadRequest => e
      # This should only be thrown if the profile type names specified in the model don't match what's on IActionable's dashboard 
      raise e
    rescue IActionable::Error::Internal => e
      # upon an intenal error from IActionable, retry some set number of times by requeueing the task through Resque 
      # after the max number of attempts, re-raise
      if attempt < Riaction.retry_attempts_for_internal_error
        Resque.enqueue(Riaction::ProfileCreator, klass_name, id, attempt+1)
      else
        raise e
      end
    end
  end
  
  class EventPerformer
    @queue = :riaction_event_logger
    
    def self.perform(event_name, klass_name, id, attempt=0)
      iactionable_api = IActionable::Api.new
      
      event_object = klass_name.constantize.find_by_id!(id)
      event_details = event_object.riaction_event(event_name)
      profile_keys = event_details[:profile].riaction_profile_keys
      
      # assert the profile exists, and if not, create it
      unless  begin
                !!iactionable_api.get_profile_summary(profile_keys[:profile_type], profile_keys[:id_type], profile_keys[:id])
              rescue IActionable::Error::BadRequest => e
                false
              end
        iactionable_api.create_profile(profile_keys[:profile_type], profile_keys[:id_type], profile_keys[:id])
      end
      
      # Log the event
      iactionable_api.log_event(profile_keys[:profile_type], profile_keys[:id_type], profile_keys[:id], event_details[:key], event_details[:params])
    rescue ActiveRecord::RecordNotFound => e
      # event_object no longer exists; no means to recover
    rescue IActionable::Error::BadRequest => e
      # Log event should never throw this as of IActionable API v3
    rescue NoMethodError => e
      raise NoEventDefined.new
    rescue IActionable::Error::Internal => e
      # upon an intenal error from IActionable, retry some set number of times by requeueing the task through Resque 
      # after the max number of attempts, re-raise
      if attempt < Riaction.retry_attempts_for_internal_error
        Resque.enqueue(Riaction::EventPerformer, event_name, klass_name, id, attempt+1)
      else
        raise e
      end
    end
  end
  
  class CrudEventCallback
    def initialize(event_name)
      @event_name = event_name
    end
    
    def after_create(record)
      if record.riaction_log_event?(@event_name)
        Resque.enqueue(Riaction::EventPerformer, @event_name, record.class.base_class.to_s, record.id)
      end
    end                                 
                                        
    def after_update(record)            
      if record.riaction_log_event?(@event_name)
        Resque.enqueue(Riaction::EventPerformer, @event_name, record.class.base_class.to_s, record.id)
      end
    end
    
    def after_destroy(record)
      if record.riaction_log_event?(@event_name)
        Resque.enqueue(Riaction::EventPerformer, @event_name, record.class.base_class.to_s, record.id)
      end
    end
  end
  
  class ProfileCreationCallback
    def after_create(record)
      Resque.enqueue(Riaction::ProfileCreator, record.class.base_class.to_s, record.id)
    end                                 
  end
  
  module ClassMethods
    def riaction(object_type, opts)
      if object_type == :profile
        (PROFILE_CLASSES << self).uniq!
        define_profile(opts.delete(:type), opts)
        include Riaction::ProfileInstanceMethods unless instance_methods.include? :riaction_profile
        send "after_create".to_sym, Riaction::ProfileCreationCallback.new
      elsif object_type == :event
        (EVENT_LOGGING_CLASSES << self).uniq!
        define_event(opts[:name], opts[:trigger], opts[:profile], opts[:params], opts[:if])
        include Riaction::EventInstanceMethods unless instance_methods.include? :riaction_event
      end
    end
    
    def define_event(name, trigger, profile, params = {}, guard = nil)
      class << self
        def riaction_events
          class_variable_defined?(:@@riaction_events) ? class_variable_get(:@@riaction_events) : class_variable_set(:@@riaction_events, {})
        end
      end
      
      events = riaction_events
      trigger = name unless trigger
      
      # store the event
      events[name] = {:trigger => trigger, :profile => profile, :params => params, :guard => guard}
      class_variable_set(:@@riaction_events, events)
      
      # Create the callback or the means to trigger it
      if Riaction.crud_actions.include? trigger
        send "after_#{trigger}".to_sym, Riaction::CrudEventCallback.new(name)
        
        define_method("trigger_#{name}!") do
          if self.riaction_log_event?(name)
            Resque.enqueue(Riaction::EventPerformer, name, self.class.base_class.to_s, self.id)
          end
        end
      else
        define_method("trigger_#{trigger}!") do
          if self.riaction_log_event?(name)
            Resque.enqueue(Riaction::EventPerformer, name, self.class.base_class.to_s, self.id)
          end
        end
      end
    end
    
    def define_profile(type, fields)
      class << self
        def riaction_profiles
          class_variable_defined?(:@@riaction_profiles) ? class_variable_get(:@@riaction_profiles) : class_variable_set(:@@riaction_profiles, {})
        end
      end
      
      profiles = riaction_profiles
      
      # store the profile
      profiles[type] = fields
      class_variable_set(:@@riaction_profiles, profiles)
      
      class << self
        def riaction_profile?
          true
        end
      end
    end
    
    def riaction_profile?
      false
    end
  end

  module EventInstanceMethods
    def riaction_event(event_name)
      events = self.class.class_variable_defined?(:@@riaction_events) ? self.class.class_variable_get(:@@riaction_events) : {}
      event = events.fetch(event_name.to_sym)
      
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
      events = self.class.class_variable_defined?(:@@riaction_events) ? self.class.class_variable_get(:@@riaction_events) : {}
      event = events.fetch(event_name.to_sym)
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
      profiles = self.class.class_variable_defined?(:@@riaction_profiles) ? self.class.class_variable_get(:@@riaction_profiles) : {}
      
      if profiles.size > 0
        if profile_type && profiles.has_key?(profile_type)
          ids = profiles.fetch(profile_type)
        else
          profile_type = profiles.first[0]
          ids = profiles.first[1]
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

begin
  ActiveRecord::Base.send(:include, Riaction)
rescue NameError => e
  # 
end