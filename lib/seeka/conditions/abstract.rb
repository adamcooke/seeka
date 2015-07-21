module Seeka
  module Conditions
    class Abstract

      attr_reader :param
      attr_reader :field
      attr_reader :operator
      attr_reader :value

      def initialize(param, field, operator, value)
        @param = param
        @field = field
        @operator = operator
        @value = value
      end

      #
      # Return the SQL query for this condition
      #
      def sql_query
        case @operator
        when :equals
          arel_field.eq(transmogrified_value)
        when :does_not_equal
          arel_field.not_eq(transmogrified_value)
        when :contains
          arel_field.matches("%#{transmogrified_value}%")
        when :does_not_contain
          arel_field.does_not_contain("%#{transmogrified_value}%")
        when :starts_with
          arel_field.matches("#{transmogrified_value}%")
        when :ends_with
          arel_field.matches("%#{transmogrified_value}")
        when :greater_than
          arel_field.gt(transmogrified_value)
        when :greater_than_or_equal_to
          arel_field.gteq(transmogrified_value)
        when :less_than
          arel_field.lt(transmogrified_value)
        when :less_than_or_equal_to
          arel_field.lteq(transmogrified_value)
        when :in
          arel_field.in(transmogrified_value.split(/\,\s*/))
        when :not_in
          arel_field.not_in(transmogrified_value.split(/\,\s*/))
        when :blank
          arel_field.eq(nil)
        when :not_blank
          arel_field.not_eq(nil)
        end
      end

      #
      # Return the field on the table
      #
      def arel_field
        case param.field.options[:transmogrification]
        when :timestamp_to_hours
          Arel::Nodes::NamedFunction.new('TIMESTAMPDIFF', [Arel::Nodes::SqlLiteral.new('HOUR'), arel_table[field], Arel::Nodes::SqlLiteral.new('UTC_TIMESTAMP()')])
        when :timestamp_to_days
          Arel::Nodes::NamedFunction.new('TIMESTAMPDIFF', [Arel::Nodes::SqlLiteral.new('DAY'), arel_table[field], Arel::Nodes::SqlLiteral.new('UTC_TIMESTAMP()')])
        when :sum
          Arel::Nodes::NamedFunction.new('SUM', [arel_table[field]])
        when :upper
          Arel::Nodes::NamedFunction.new('UPPER', [arel_table[field]])
        when :lower
          Arel::Nodes::NamedFunction.new('LOWER', [arel_table[field]])
        else
          arel_table[field]
        end
      end

      #
      # Return the actual value to search on
      #
      def transmogrified_value
        case param.field.options[:value_transmogrification]
        when :chronic
          Chronic.parse(value, :context => :past)
        when :chronic_date
          v = Chronic.parse(value, :context => :past)
          v ? v.to_date : nil
        when :upcase
          value.upcase
        when :downcase
          value.downcase
        else
          value
        end
      end

      #
      # Returns an array of relationships which must be included in order
      # to run this query.
      #
      def includes
        []
      end

      #
      # Returns an array of joins
      #
      def joins
        []
      end

      #
      # Return the table
      #
      def arel_table
        param.query.definition.model.arel_table
      end

      #
      # Returns an array of operators which are supported by this
      # condition type.
      #
      def self.available_operators
        [:equals, :does_not_equal, :contains, :does_not_contain, :starts_with, :ends_with, :greater_than, :greater_than_or_equal_to, :less_than, :less_than_or_equal_to, :in, :not_in, :blank, :not_blank]
      end

    end
  end
end
