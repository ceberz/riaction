module IActionable
  module Objects
    class Level < IActionableObject
      attr_accessor :name
      attr_accessor :number
      attr_accessor :required_points
      attr_accessor :level_type
      
      def initialize(key_values={})
        @level_type = IActionable::Objects::LevelType.new(key_values.delete("LevelType"))
        super(key_values)
      end
    end
  end
end