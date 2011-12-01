require 'riaction/iactionable/api'
require 'riaction/constants'
require "resque"

module Riaction
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
      if attempt < ::Riaction::Constants.retry_attempts_for_internal_error
        Resque.enqueue(self, klass_name, id, attempt+1)
      else
        raise e
      end
    end
  end
end