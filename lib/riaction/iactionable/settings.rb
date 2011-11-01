module IActionable
  class ConfigError < StandardError
  end
  
  class Settings
    attr :settings
    
    def initialize(values)
      @settings = {
        :app_key => values.fetch(:app_key),
        :api_key => values.fetch(:api_key),
        :version => values.fetch(:version)
      }
    rescue NoMethodError, KeyError => e
      raise ConfigError.new("IAction::Settings being initialized with invalid arguments")
    end
    
    def app_key
      @settings.fetch(:app_key)
    end
    
    def api_key
      @settings.fetch(:api_key)
    end
    
    def version
      @settings.fetch(:version)
    end
  end
end