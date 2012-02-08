require 'riaction/constants'
require "resque"

module Riaction
  class ProfileCreator
    @queue = :riaction_profile_creator
  
    def self.perform(klass_name, id, attempt=0)
      if klass_name.constantize.riactionary? && 
        klass_name.constantize.riaction_profile? &&
        klass_name.constantize.riaction_profile_types_defined > 0
        record = klass_name.constantize.find_by_id!(id)
        iactionable_api = IActionable::Api.new
        record.riaction_profile_keys.each_pair do |profile_type, ids|
          identifiers = ids.to_a
          first_defined = identifiers.shift
          iactionable_api.create_profile(profile_type.to_s, first_defined.first.to_s, first_defined.last.to_s, nil)
          identifiers.each do |identifier|
            iactionable_api.add_profile_identifier(profile_type.to_s, first_defined.first.to_s, first_defined.last.to_s, identifier.first.to_s, identifier.last.to_s)
          end
        end
      else
        raise ::Riaction::RuntimeError.new("#{klass_name} does not define any riaction profiles")
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