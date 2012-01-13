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
      
      def to_hash
        hash = {
          "Key" => @key,
          "Description" => @description,
          "Name" => @name,
          "Interval" => @interval
        }
        hash.merge!(awardable_hash) unless @progress.empty?
        hash.delete("AwardDate") if @award_date.nil?
        hash.delete("Interval") if @interval.nil?
        hash
      end
    end
  end
end