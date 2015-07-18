module Seeka
  module Conditions
    class RelationCounter < Abstract

      def field
        "count"
      end

      def joins
        ["LEFT JOIN (SELECT #{relationship.foreign_key}, count(#{relationship.foreign_key}) as #{field} from #{relationship.table_name} group by #{relationship.foreign_key}) #{temp_table_name} ON #{arel_table.name}.#{param.query.definition.model.primary_key} = #{temp_table_name}.#{relationship.foreign_key}"]
      end

      def arel_field
        @arel_field ||= Arel::Table.new(temp_table_name)[field]
      end

      private

      def temp_table_name
        @temp_table_name ||= "a#{Digest::SHA1.hexdigest("#{Time.now.to_f}-#{rand(1000)}")[0,6]}"
      end

      def relationship
        param.query.definition.model.reflect_on_all_associations.select { |a| a.name == param.field.options[:relationship] }.first
      end

    end
  end
end
