require 'generators/riaction_generator'

module Riaction
  module Generators
    class InstallGenerator < Base
      argument :credentials, :type => :array, :required => true, :banner => "environment:app_key:api_key environment:app_key:api_key"

      def create_credentials_file
        credentials.map!{|credential| { :env => credential[credential_regexp,1],
                                        :app_key => credential[credential_regexp,2], 
                                        :api_key => credential[credential_regexp,3] } }
        template "i_actionable.yml", "config/i_actionable.yml"
      end

      private

      def credential_regexp
        /^(\w+):(\w+):(\w+)$/
      end
    end
  end
end