module Riaction
  class Constants
    def self.crud_actions
      Set.new [:create, :update, :destroy]
    end
  
    def self.retry_attempts_for_internal_error
      3
    end
    
    def self.supported_identifier_types
      [:email,:username,:custom,:facebook,:twitter,:salesforce]
    end
  end
end
