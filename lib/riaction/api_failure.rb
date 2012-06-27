module Riaction
  module ApiFailure
    def handle_api_failure(exception)
      if @api_failure_handler_block
        @api_failure_handler_block.call(exception)
      else
        default_behavior(exception)
      end
    end
    
    def handle_api_failure_with(&block)
      if block_given?
        @api_failure_handler_block = block
      end
    end
    
    def default_behavior(exception)
      raise exception
    end
  end
end