require 'riaction/constants'
require "resque"

module Riaction
  class EventPerformer
    extend ::Riaction::ApiFailure
    
    @queue = :riaction_event_logger

    # Sends an event to IActionable based on the name of a riaction class and the ID used to locate the instance
    def self.perform(event_name, klass_name, id, attempt=0)
      check_class_requirements!(event_name, klass_name)
      begin
        log_event(event_name, klass_name, id)
      rescue IActionable::Error::BadRequest => e
        # Log event should never throw this as of IActionable API v3
      rescue Faraday::Error::TimeoutError, Timeout::Error => e
        Resque.enqueue(self, event_name, klass_name, id, attempt+1)
      rescue IActionable::Error::Internal => e
        # handle_api_failure(event_name, klass_name, id, attempt)
        handle_api_failure(e, event_name, klass_name, id)
      end
    end
    
    def self.check_class_requirements!(event_name, klass_name)
      unless  klass_name.constantize.riactionary? &&
              klass_name.constantize.riaction_events? &&
              klass_name.constantize.riaction_defines_event?(event_name.to_sym)
        raise ::Riaction::ConfigurationError.new("#{klass_name} does not define event #{event_name}")
      end
    end
    
    def self.log_event(event_name, klass_name, id)
      iactionable_api = IActionable::Api.new      
      if event_object = klass_name.constantize.find_by_id(id)
        event_params = event_object.riaction_event_params
        if event_params.has_key?(event_name.to_sym)
              iactionable_api.log_event(  event_params[event_name.to_sym][:profile][:type],
                                          event_params[event_name.to_sym][:profile][:id_type],
                                          event_params[event_name.to_sym][:profile][:id],
                                          event_name.to_sym,
                                          event_params[event_name.to_sym][:params])
        else
          raise ::Riaction::ConfigurationError.new("Instance of #{klass_name} with ID #{id} could not construct event parameters for event #{event_name}.  Is the profile a valid one?")
        end
      end
    end
    
    def self.handle_api_failure(exception, event_name, klass_name, id)
      if @api_failure_handler_block
        @api_failure_handler_block.call(exception, event_name, klass_name, id)
      else
        default_behavior(exception)
      end
    end
  end
end