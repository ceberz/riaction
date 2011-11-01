require 'faraday'
require 'faraday_stack'
require 'riaction/iactionable/error'

module IActionable
  class Request < Struct.new(:path, :params, :headers, :body)
    attr :settings
    
    def initialize(settings)
      @settings = settings
      self.path = nil
      self.params = {}
      self.headers = {}
      self.body = {}
    end
    
    def to(path)
      self.path = path unless path.nil? || path.empty?
      self
    end
    
    def with_api_key
      (self.headers[:Authorization] = @settings.api_key) and self
    end
    
    def with_app_key
      (self.params[:appKey] = @settings.app_key) and self
    end
    
    def with_params(params={})
      self.params.merge!(params) and self
    end
    
    def with_body(body={})
      self.body.merge!(body) and self
    end
  end
  
  class Connection
    attr :connection
    attr :settings
    attr :request
    attr_accessor :response
    
    def initialize(settings)
      @settings = settings
      
      @connection = Faraday.new api_url(@settings.version) do |builder|
        builder.use FaradayStack::ResponseJSON, content_type: 'application/json'
        builder.use Faraday::Response::RaiseError
        builder.use Faraday::Adapter::NetHttp
      end
      
      @request = nil
    end
    
    def request
      (@request = Request.new(@settings)) and self
    end
    
    def get(path=nil, query_params={})
      @request ||= Request.new(@settings)
      @request.to(path).with_params(query_params)
      @response = @connection.get do |req|
        req.headers.merge! @request.headers
        req.url @request.path, @request.params
      end
      @response.body
    rescue Faraday::Error::ClientError => e
      handle_client_error e
    ensure
      @request = nil
    end
    
    def post(path=nil, query_params={}, body_params={})
      @request ||= Request.new(@settings)
      @request.to(path).with_params(query_params)
      @response = @connection.post do |req|
        req.headers.merge! @request.headers
        req.url @request.path, @request.params
        req.body = @request.body unless @request.body.empty?
      end
      @response.body
    rescue Exception => e
      handle_client_error e
    ensure
      @request = nil
    end
    
    private
    
    def method_missing(symbol, *args)
      @request.send(symbol, *args) and self
    rescue NoMethodError => e
      raise e
    end
    
    def api_url(version)
      "http://api.iactionable.com/v#{version}/"
    end
    
    def handle_client_error(e)
      # http://iactionable.com/api/response-codes/
      case e.response[:status]
      when 400
        raise IActionable::Error::BadRequest.new(e.response)
      when 401
        raise IActionable::Error::Unauthorized.new(e.response)
      when 500
        raise IActionable::Error::Internal.new(e.response)
      end
    end
  end
end