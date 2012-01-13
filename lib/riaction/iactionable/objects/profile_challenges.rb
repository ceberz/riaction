module IActionable
  module Objects
    class ProfileChallenges < IActionableObject
      attr_accessor :available
      attr_accessor :completed
      
      def initialize(key_values={})
        @available = extract_many_as(key_values, "Available", IActionable::Objects::Challenge)
        @completed = extract_many_as(key_values, "Completed", IActionable::Objects::Challenge)
      end
      
      def to_hash
        {
          "Available" => @available.map{|challenge| challenge.to_hash},
          "Completed" => @completed.map{|challenge| challenge.to_hash}
        }
      end
    end
  end
end