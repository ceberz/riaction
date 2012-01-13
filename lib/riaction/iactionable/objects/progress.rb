module IActionable
  module Objects
    class Progress < IActionableObject
      attr_accessor :description
      attr_accessor :condition_met_date
      attr_accessor :original_condition_met_date
      attr_accessor :current_value
      attr_accessor :required_value
      attr :complete
      
      def initialize(key_values={})
        super(key_values)
        # convert the miliseconds within the date string to seconds (per ruby)
        # "/Date(1275706032317-0600)/" => "1275706032-0600"
        @original_condition_met_date = @condition_met_date
        @condition_met_date = IActionableObject.timestamp_to_seconds(@condition_met_date) unless @condition_met_date.blank?
      end
      
      def complete?
        Integer(@current_value) >= Integer(@required_value)
      rescue TypeError => e
        false
      end
      
      def percent_complete
        Integer(Float(@current_value) / Integer(@required_value) * 100)
      rescue TypeError => e
        0
      end
      
      def condition_met_date
        # bug in ruby 1.9.2 where Time.strptime does not support seconds-since-epoch format, but Date.strptime does, so we'll use that for now
        Date.strptime(@condition_met_date, "%s%z").to_time unless @condition_met_date.blank?
      end
      
      def to_hash
        {
          "Description" => @description,
          "CurrentValue" => @current_value,
          "RequiredValue" => @required_value,
          "ConditionMetDate" => @original_condition_met_date
        }
      end
    end
  end
end