module Seeka
  class Query

    attr_reader :definition
    attr_reader :options

    def initialize(definition, options = {})
      @definition = definition
      @options = options
    end

    #
    # Store all the conditions which are needed for this object
    #
    def condition_groups
      @condition_groups ||= []
    end

    #
    # A helper for creating a query param
    #
    def param(name, operator, value)
      QueryParam.new(self, name, operator, value)
    end

    #
    # A helper for quickly creating a condition group
    #
    def group(type, &block)
      condition_group = ConditionGroup.new(self, type)
      block.call(condition_group.params)
      condition_groups << condition_group
    end

    #
    # Return results
    #
    def results
      results = definition.base
      condition_groups.each do |cg|
        # Add the where string
        results = results.where(cg.sql_query)
        # Add any includes (as references too in case they were references)
        results = results.includes(cg.includes).references(cg.includes)
        # Add any extra joins
        results = results.joins(cg.joins)
      end
      ids = results.select('id').pluck(:id)
      definition.base.where(:id => ids)
    end

    def to_hash
      {
        :groups => condition_groups.map(&:to_hash)
      }
    end

    def to_json
      to_hash.to_json
    end

    def self.from_json(definition, json)
      query = self.new(definition)
      if json.blank?
        query
      else
        hash = JSON.parse(json)
        hash['groups'].each do |group|
          query.group(group['type']) do |params|
            group['params'].each do |param|
              params << query.param(param['name'].to_s.to_sym, param['operator'].to_s.to_sym, param['value'])
            end
          end
        end
      end
      query
    end

  end
end
