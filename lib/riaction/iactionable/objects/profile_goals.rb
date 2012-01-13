module IActionable
  module Objects
    class ProfileGoals < IActionableObject
      attr_accessor :available
      attr_accessor :completed
      
      def initialize(key_values={})
        @available = extract_many_as(key_values, "Available", IActionable::Objects::Goal)
        @completed = extract_many_as(key_values, "Completed", IActionable::Objects::Goal)
      end
      
      def to_hash
        {
          "Available" => @available.map{|goal| goal.to_hash},
          "Completed" => @completed.map{|goal| goal.to_hash}
        }
      end
    end
  end
end