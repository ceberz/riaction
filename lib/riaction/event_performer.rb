require 'riaction/iactionable/api'
require 'riaction/constants'
require "resque"

module Riaction
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
      if attempt < ::Riaction::Constants.retry_attempts_for_internal_error
        Resque.enqueue(self, event_name, klass_name, id, attempt+1)
      else
        raise e
      end
    end
  end
end