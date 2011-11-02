require 'rails'

module Riaction
  class Railtie < Rails::Railtie
      railtie_name :riaction
  
      rake_tasks do
        load "tasks/riaction.rake"
      end
    end
end