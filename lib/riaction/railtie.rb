require 'rails'

module Riaction
  class Railtie < Rails::Railtie  
      rake_tasks do
        load "tasks/riaction.rake"
      end
    end
end