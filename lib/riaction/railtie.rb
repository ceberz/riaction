require 'rails'

module Riaction
  class Railtie < Rails::Railtie  
    rake_tasks do
      load "tasks/riaction.rake"
    end
    
    generators do
      require "generators/riaction/riaction_generator"
    end
    
    initializer "riaction_railtie.configure_i_actionable_creds" do |app|
      begin
        IActionable::Api.init_settings(YAML.load_file("#{::Rails.root}/config/i_actionable.yml")[::Rails.env].symbolize_keys!)
      rescue Errno::ENOENT => e
        # warn of missing credentials file
      rescue NoMethodError => e
        # warn of malformed credentials file
      end
    end
    
    initializer "riaction_railtie.extend.active_record" do |app|
      ActiveRecord::Base.extend(::Riaction::Riaction::ClassMethods) if defined?(ActiveRecord)
    end
  end
end