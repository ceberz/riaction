require 'riaction/constants'
require "resque"

module Riaction
  class EventPerformer
    @queue = :riaction_event_logger

    def self.perform(event_name, klass_name, id, attempt=0)
      iactionable_api = IActionable::Api.new
      event_object = klass_name.constantize.find_by_id!(id)
      event_params = event_object.riaction_event_params

      if (  klass_name.constantize.riactionary? &&
            klass_name.constantize.riaction_events? &&
            klass_name.constantize.riaction_defines_event?(event_name) )
        iactionable_api.log_event(  event_params[event_name][:profile][:type],
                                    event_params[event_name][:profile][:id_type],
                                    event_params[event_name][:profile][:id],
                                    event_name,
                                    event_params[event_name][:params])
      else
        raise ::Riaction::ConfigurationError.new("#{klass_name} does not define event #{event_name}")
      end
    rescue ActiveRecord::RecordNotFound => e
      # event_object no longer exists; no means to recover
    rescue IActionable::Error::BadRequest => e
      # Log event should never throw this as of IActionable API v3
    rescue IActionable::Error::Internal => e
      # upon an intenal error from IActionable, retry some set number of times by requeueing the task through Resque 
      # after the max number of attempts, re-raise
      if attempt < ::Riaction::Constants.retry_attempts_for_internal_error
        Resque.enqueue(self, event_name, klass_name, id, attempt+1)
      else
        raise e
      end
    end
  end
end