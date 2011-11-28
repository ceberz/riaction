module IActionable
  module Objects
    class Achievement < IActionableObject
      attr_accessor :key
      attr_accessor :description
      attr_accessor :image_url
      attr_accessor :name
      
      def initialize(key_values={})
        initialize_awardable(key_values)
        super(key_values)
      end
      
      awardable
    end
  end
end