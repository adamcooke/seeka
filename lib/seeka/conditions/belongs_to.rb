module Seeka
  module Conditions
    class BelongsTo < Abstract

      def field
        @field.first[1]
      end

      def includes
        [relationship.name]
      end

      def arel_table
        relationship.klass.arel_table
      end

      private

      def relationship
        param.query.definition.model.reflect_on_all_associations.select { |a| a.macro == :belongs_to && a.name == @field.first[0]}.first
      end

    end
  end
end
