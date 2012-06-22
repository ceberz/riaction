class CreateRescuedRiactionApiCalls < ActiveRecord::Migration
  def self.up
    create_table :rescued_riaction_api_calls do |t|
      t.text :arg_hash
      t.timestamps
    end
  end

  def self.down
    drop_table :rescued_riaction_api_calls
  end
end
