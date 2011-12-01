module Riaction
  class Constants
    def self.crud_actions
      Set.new [:create, :update, :destroy]
    end
  
    def self.retry_attempts_for_internal_error
      3
    end
  end
end
