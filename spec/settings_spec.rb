require 'spec_helper.rb'

describe IActionable::Settings do
  before do
    @settings_hash = {
      :app_key => "12345",
      :api_key => "abcde",
      :version => "3"
    }
  end
  
  describe "with a valid input hash" do
    it "should initialize" do
      lambda { IActionable::Settings.new(@settings_hash) }.should_not raise_error
    end
  end
  
  describe "with an invalid input hash" do
    it "should not initialize from missing app key" do
      @settings_hash.delete(:app_key)
      lambda { IActionable::Settings.new(@settings_hash) }.should raise_error(IActionable::ConfigError)
    end
    
    it "should not initialize from missing api key" do
      @settings_hash.delete(:api_key)
      lambda { IActionable::Settings.new(@settings_hash) }.should raise_error(IActionable::ConfigError)
    end
    
    it "should not initialize from missing version" do
      @settings_hash.delete(:version)
      lambda { IActionable::Settings.new(@settings_hash) }.should raise_error(IActionable::ConfigError)
    end
  end
  
  describe "once initialized" do
    before do
      @settings = IActionable::Settings.new(@settings_hash)
    end
    
    it "should return the app key" do
      @settings.app_key.should == @settings_hash[:app_key]
    end
    
    it "should return the api key" do
      @settings.api_key.should == @settings_hash[:api_key]
    end
    
    it "should return the version" do
      @settings.version.should == @settings_hash[:version]
    end
  end
end