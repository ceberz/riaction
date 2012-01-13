module IActionable
  module Objects
    module Awardable
      def self.included(base)
        base.extend(ClassMethods)  
      end
    
      module ClassMethods
        def awardable
          attr_accessor :award_date
          attr_accessor :original_award_date
          attr_accessor :progress
          include IActionable::Objects::Awardable::InstanceMethods
        end
      end

      module InstanceMethods
        def initialize_awardable(key_values={})
          @progress = extract_many_as(key_values, "Progress", IActionable::Objects::Progress)
          # convert the miliseconds within the date string to seconds (per ruby)
          # "/Date(1275706032317-0600)/" => "1275706032-0600"
          @original_award_date = @award_date = key_values.delete("AwardDate")
          @award_date = IActionableObject.timestamp_to_seconds(@award_date) unless @award_date.blank?
        end
      
        def complete?
          @progress.any? && @progress.all?
        end
      
        def percent_complete
          Integer(Float(@progress.select{|p| p.complete?}.size) / @progress.size * 100)
        rescue TypeError => e
          0
        end
      
        def awarded_on
          # bug in ruby 1.9.2 where Time.strptime does not support seconds-since-epoch format, but Date.strptime does, so we'll use that for now
          Date.strptime(@award_date, "%s%z").to_time unless @award_date.blank?
        end
        
        def awardable_hash
          {
            "AwardDate" => @original_award_date,
            "Progress" => @progress.map{|prog| prog.to_hash}
          }
        end
      end
    end
  end
end