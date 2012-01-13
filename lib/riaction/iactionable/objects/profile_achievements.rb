module IActionable
  module Objects
    class ProfileAchievements < IActionableObject
      attr_accessor :available
      attr_accessor :completed
      
      def initialize(key_values={})
        @available = extract_many_as(key_values, "Available", IActionable::Objects::Achievement)
        @completed = extract_many_as(key_values, "Completed", IActionable::Objects::Achievement)
      end
      
      def to_hash
        {
          "Available" => @available.map{|achievement| achievement.to_hash},
          "Completed" => @completed.map{|achievement| achievement.to_hash}
        }
      end
    end
  end
end