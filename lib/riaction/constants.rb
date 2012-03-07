module Riaction
  class Constants
    # sets the default actions to be considered as part of riaction
    def self.crud_actions
      Set.new [:create, :update, :destroy]
    end
    
    # sets the default number of attempts to retry a action incase of an internal error  
    def self.retry_attempts_for_internal_error
      3
    end

    # sets the valid supported identifiers
    # @return  returns an array of symbols
    def self.supported_identifier_types
      [:email,:username,:custom,:facebook,:twitter,:salesforce]
    end
    
    def self.riaction_options
      {
        :default_event_params => {}
      }
    end
  end
end
