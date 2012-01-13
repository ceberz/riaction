module IActionable
  module Objects
    class ProfilePoints < IActionableObject
      attr_accessor :level # not always present
      attr_accessor :point_type
      attr_accessor :points
      attr_accessor :reason # not always present
      
      def initialize(key_values={})
        levels = key_values.delete("Level")
        @level = IActionable::Objects::ProfileLevel.new(levels) unless levels.nil?
        @point_type = IActionable::Objects::PointType.new(key_values.delete("PointType"))
        super(key_values)
      end
      
      def to_hash
        hash = {
          "Level" => @level.nil? ? nil : @level.to_hash,
          "PointType" => @point_type.to_hash,
          "Points" => @points,
          "Reason" => @reason
        }
        hash.delete "Level" if @level.nil?
        hash.delete "Reason" if @reason.nil?
        hash
      end
    end
  end
end