require 'spec_helper.rb'

describe IActionable::Connection do
  before do
    @settings_hash = {
      :app_key => "12345",
      :api_key => "abcde",
      :version => "3"
    }
    @settings = IActionable::Settings.new(@settings_hash)
  end
  
  describe "initialization" do
    it "should initialize a new Faraday connection object" do
      mock_faraday_bulder = mock("faraday builder")
      
      Faraday.should_receive(:new).once.with("http://api.iactionable.com/v#{@settings.version}/").and_yield(mock_faraday_bulder)
      mock_faraday_bulder.should_receive(:use).once.with(FaradayStack::ResponseJSON, {:content_type => 'application/json'})
      mock_faraday_bulder.should_receive(:use).once.with(Faraday::Response::RaiseError)
      mock_faraday_bulder.should_receive(:use).once.with(Faraday::Adapter::NetHttp)
      
      IActionable::Connection.new(@settings)
    end
  end
  
  describe "requests" do
    before do
      @mock_faraday_connection = mock("mock faraday connection")
      @mock_faraday_response = mock("mock faraday response")
      @mock_faraday_request_builder = mock("mock faraday request builder")
      @mock_response_body = mock("mock response body")
      @mock_faraday_request_headers = mock("mock faraday request headers")
      @mock_faraday_response.stub!(:body).and_return(@mock_response_body)
      @mock_faraday_request_builder.stub!(:headers).and_return(@mock_faraday_request_headers)
      @mock_faraday_request_headers.stub!(:merge!).and_return(true)
      Faraday.stub!(:new).and_return(@mock_faraday_connection)
      @connection = IActionable::Connection.new(@settings)
      @path = "/test/path"
    end
    
    describe "using get method" do
      describe "requiring an app key" do
        describe "with optional params" do
          it "should request correctly through faraday and return the body" do
            @mock_faraday_connection.should_receive(:get).and_yield(@mock_faraday_request_builder).and_return(@mock_faraday_response)
            @mock_faraday_request_builder.should_receive(:url).once.with(@path, hash_including(:appKey => @settings.app_key, :foo => :bar))
            @mock_faraday_request_builder.should_receive(:headers).any_number_of_times
            @connection.request.to(@path).with_app_key.with_params(:foo => :bar).get.should == @mock_response_body
          end
        end
        
        describe "without optional params" do
          it "should request correctly through faraday and return the body" do
            @mock_faraday_connection.should_receive(:get).and_yield(@mock_faraday_request_builder).and_return(@mock_faraday_response)
            @mock_faraday_request_builder.should_receive(:url).once.with(@path, hash_including(:appKey => @settings.app_key))
            @mock_faraday_request_builder.should_receive(:headers).any_number_of_times
            @connection.request.to(@path).with_app_key.get.should == @mock_response_body
          end
        end
      end
    end
    
    describe "using post method" do
      describe "requiring an app key" do
        describe "requiring an api key" do
          describe "with optional params" do
            it "should request correctly through faraday and return the body" do
              @mock_faraday_connection.should_receive(:post).and_yield(@mock_faraday_request_builder).and_return(@mock_faraday_response)
              @mock_faraday_request_builder.should_receive(:url).once.with(@path, hash_including(:appKey => @settings.app_key, :foo => :bar))
              @mock_faraday_request_builder.should_receive(:headers).once.and_return(@mock_faraday_request_headers)
              @mock_faraday_request_headers.should_receive(:merge!).once.with(:Authorization => @settings.api_key)
              @connection.request.to(@path).with_app_key.with_api_key.with_params(:foo => :bar).post.should == @mock_response_body
            end
          end
        
          describe "without optional params" do
            it "should request correctly through faraday and return the body" do
              @mock_faraday_connection.should_receive(:post).and_yield(@mock_faraday_request_builder).and_return(@mock_faraday_response)
              @mock_faraday_request_builder.should_receive(:url).once.with(@path, hash_including(:appKey => @settings.app_key))
              @mock_faraday_request_builder.should_receive(:headers).once.and_return(@mock_faraday_request_headers)
              @mock_faraday_request_headers.should_receive(:merge!).once.with(:Authorization => @settings.api_key)
              @connection.request.to(@path).with_app_key.with_api_key.post.should == @mock_response_body
            end
          end
          
          describe "with an optional body" do
            it "should request correctly through faraday and return the body" do
              @mock_faraday_connection.should_receive(:post).and_yield(@mock_faraday_request_builder).and_return(@mock_faraday_response)
              @mock_faraday_request_builder.should_receive(:url).once.with(@path, hash_including(:appKey => @settings.app_key))
              @mock_faraday_request_builder.should_receive(:headers).once.and_return(@mock_faraday_request_headers)
              @mock_faraday_request_headers.should_receive(:merge!).once.with(:Authorization => @settings.api_key)
              @mock_faraday_request_builder.should_receive(:body=).once.with(:foo => :bar)
              @connection.request.to(@path).with_app_key.with_api_key.with_body(:foo => :bar).post.should == @mock_response_body
            end
          end
        
          describe "without an optional body" do
            it "should request correctly through faraday and return the body" do
              @mock_faraday_connection.should_receive(:post).and_yield(@mock_faraday_request_builder).and_return(@mock_faraday_response)
              @mock_faraday_request_builder.should_receive(:url).once.with(@path, hash_including(:appKey => @settings.app_key))
              @mock_faraday_request_builder.should_receive(:headers).once.and_return(@mock_faraday_request_headers)
              @mock_faraday_request_headers.should_receive(:merge!).once.with(:Authorization => @settings.api_key)
              @mock_faraday_request_builder.should_not_receive(:body=)
              @connection.request.to(@path).with_app_key.with_api_key.post.should == @mock_response_body
            end
          end
        end
      end
    end
  end
end