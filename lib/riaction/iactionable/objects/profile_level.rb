require 'riaction/iactionable/objects/i_actionable_object.rb'
require 'riaction/iactionable/objects/level.rb'

module IActionable
  module Objects
    class ProfileLevel < IActionableObject
      attr_accessor :current
      attr_accessor :next
      
      def initialize(key_values={})
        @current = IActionable::Objects::Level.new(key_values.delete("Current")) unless key_values["Current"].blank?
        @next = IActionable::Objects::Level.new(key_values.delete("Next")) unless key_values["Next"].blank?
      end
    end
  end
end