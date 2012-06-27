require 'riaction/constants'
require "resque"

module Riaction
  class ProfileCreator
    extend ::Riaction::ApiFailure
    
    @queue = :riaction_profile_creator
  
    def self.perform(klass_name, id, attempt=0)
      check_class_requirements!(klass_name)
      create_profile(klass_name, id)
    rescue IActionable::Error::BadRequest => e
      # This should only be thrown if the profile type names specified in the model don't match what's on IActionable's dashboard 
      raise e
    rescue Faraday::Error::TimeoutError, Timeout::Error => e
      Resque.enqueue(self, klass_name, id, attempt+1)
    rescue IActionable::Error::Internal => e
      handle_api_failure(e, klass_name, id)
    end
    
    def self.check_class_requirements!(klass_name)
      unless  klass_name.constantize.riactionary? && 
              klass_name.constantize.riaction_profile? &&
              klass_name.constantize.riaction_profile_types_defined > 0
        raise ::Riaction::RuntimeError.new("#{klass_name} does not define any riaction profiles")
      end
    end
    
    def self.create_profile(klass_name, id)
      iactionable_api = IActionable::Api.new
      if record = klass_name.constantize.find_by_id(id)
        record.riaction_profile_keys.each_pair do |profile_type, ids|
          identifiers = ids.to_a
          first_defined = identifiers.shift
          iactionable_api.create_profile(profile_type.to_s, first_defined.first.to_s, first_defined.last.to_s, record.riaction_set_profile(profile_type).riaction_profile_display_name )
          identifiers.each do |identifier|
            iactionable_api.add_profile_identifier(profile_type.to_s, first_defined.first.to_s, first_defined.last.to_s, identifier.first.to_s, identifier.last.to_s)
          end
        end
      end
    end
    
    def self.handle_api_failure(exception, klass_name, id)
      if @api_failure_handler_block
        if @api_failure_handler_block.call(exception, klass_name, id)
          Resque.enqueue(self, klass_name, id)
        end
      else
        default_behavior(exception)
      end
    end
  end
end