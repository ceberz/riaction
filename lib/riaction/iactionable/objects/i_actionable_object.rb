module IActionable
  module Objects
    class IActionableObject
      def initialize(key_values={})
        key_values.each_pair do |key, value|
          instance_variable_set "@#{key.camelize.underscore}".to_sym, value
        end
      end
      
      def self.timestamp_regexp
        /\/Date\((\d+)((\-|\+)\d{4})\)\//
      end
      
      def self.timestamp_to_seconds(timestamp)
        milliseconds = timestamp[timestamp_regexp, 1]
        tz = timestamp[timestamp_regexp, 2]
        "#{Integer(milliseconds)/1000}#{tz}"
      end
      
      private
      
      def extract_many_as(key_values, field, klass)
        if key_values.fetch(field, nil).respond_to?(:inject)
          loaded = []
          content = key_values.delete(field)
          content.each do |c|
            loaded << klass.new(c)
          end
          loaded
        else
          []
        end
      end
    end
  end
end