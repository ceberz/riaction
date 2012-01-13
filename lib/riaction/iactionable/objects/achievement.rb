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
      
      def to_hash
        hash = {
          "Key" => @key,
          "Description" => @description,
          "ImageURL" => @image_url,
          "Name" => @name
        }
        hash.merge!(awardable_hash) unless @progress.empty?
        hash.delete("AwardDate") if @award_date.nil?
        hash
      end
    end
  end
end