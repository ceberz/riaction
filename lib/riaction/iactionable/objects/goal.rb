module IActionable
  module Objects
    class Goal < IActionableObject
      awardable
      
      attr_accessor :key
      attr_accessor :description
      attr_accessor :name
      attr_accessor :interval
      
      def initialize(key_values={})
        initialize_awardable(key_values)
        super(key_values)
      end
    end
  end
end