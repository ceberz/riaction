module IActionable
  module Objects
    class Leaderboard < IActionableObject
      attr_accessor :key
      attr_accessor :name
      
      def to_hash
        {
          "Key" => @key,
          "Name" => @name
        }
      end
    end
  end
end