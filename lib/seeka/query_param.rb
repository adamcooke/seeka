module Seeka
  class QueryParam

    def initialize(query, name, operator, value)
      @query = query
      @name = name
      @operator = operator
      @value = value
      validate
    end

    attr_reader :query
    attr_reader :name
    attr_reader :operator
    attr_reader :value

    def field
      @field ||= query.definition.field_for(@name)
    end

    def validate
      raise Error, "Invalid field '#{@name}'" unless field
      raise Error, "Invalid operator '#{@operator}' for '#{@name}'" unless field.options[:operators].include?(@operator.to_sym)
    end

    def condition
      @condition ||= field.condition.new(self, field.options[:field], @operator, @value)
    end

    def to_hash
      {
        :name => name,
        :operator => operator,
        :value => value
      }
    end

  end
end
