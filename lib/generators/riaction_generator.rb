require 'rails/generators/named_base'

module Riaction
  module Generators
    class Base < Rails::Generators::Base
      def self.source_root 
        @_riaction_source_root ||= File.expand_path(File.join(File.dirname(__FILE__), 'riaction', generator_name, 'templates'))
      end
    end
  end
end