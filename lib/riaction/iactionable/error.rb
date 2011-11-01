module IActionable
  module Error
    class Error < StandardError
      attr_accessor :response
      
      def initialize(response)
        @response = response
        super
      end
    end
  
    # http://iactionable.com/api/response-codes/
    class BadRequest < Error; end
    class Unauthorized < Error; end
    class Internal < Error; end
  end
end
