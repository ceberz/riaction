require 'rails/generators'
require 'rails/generators/migration'
require 'generators/riaction_generator'

module Riaction
  module Generators
    class RescueGenerator < Base
      include Rails::Generators::Migration

      def self.next_migration_number(dirname)
        if ActiveRecord::Base.timestamped_migrations
          migration_number = Time.now.utc.strftime("%Y%m%d%H%M%S").to_i
          migration_number += 1
          migration_number.to_s
        else
          "%.3d" % (current_migration_number(dirname) + 1)
        end
      end

      def create_migration
        migration_template 'migration.rb', 'db/migrate/create_rescued_riaction_api_calls'
      end
    end
  end
end