module Seeka
  module Conditions
    class SubQuery < Abstract

      def field
        'id'
      end

      def sql_query
        arel_table[:id].in(get_ids_for_query)
      end

      private

      #
      # This method will get an array of all
      #
      def get_ids_for_query
        if param.field.options[:definition]
          definition = param.field.options[:definition]
        else
          # Set up a definition
          definition = Definition.new
          definition.base = param.field.options[:base].is_a?(Proc) ? param.field.options[:base].call : param.field.options[:base]

          # Get the fields which we should search for
          fields = @field.is_a?(Array) ? @field : [@field]
          fields.each do |field|
            definition.fields << DefinitionField.new(field, :condition => Local, :value_transmogrification => param.field.options[:value_transmogrification])
          end
        end

        # Set up a query
        query = Query.new(definition)

        # Add all the fields
        query.group(:any) do |params|
          fields.each do |field|
            params << query.param(field, @operator, @value)
          end
        end

        ids = query.results.pluck(param.field.options[:foreign_key])

        if @operator == :blank
          all_ids = param.query.definition.base.pluck(:id)
          present_ids = definition.base.pluck(param.field.options[:foreign_key])
          ids = (all_ids - present_ids) + ids
        end

        ids

      end
    end
  end
end
