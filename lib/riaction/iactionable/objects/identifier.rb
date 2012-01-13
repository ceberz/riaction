module IActionable
  module Objects
    class Identifier < IActionableObject
      attr_accessor :id
      attr_accessor :id_hash
      attr_accessor :id_type
      
      def to_hash
        {
          "ID" => @id,
          "IDHash" => @id_hash,
          "IDType" => @id_type
        }
      end
    end
  end
end