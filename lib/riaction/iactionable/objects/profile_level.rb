module IActionable
  module Objects
    class ProfileLevel < IActionableObject
      attr_accessor :current
      attr_accessor :next
      
      def initialize(key_values={})
        @current = IActionable::Objects::Level.new(key_values.delete("Current")) unless key_values["Current"].blank?
        @next = IActionable::Objects::Level.new(key_values.delete("Next")) unless key_values["Next"].blank?
      end
      
      def to_hash
        {
          "Current" => @current.to_hash,
          "Next" => @next.to_hash
        }
      end
    end
  end
end