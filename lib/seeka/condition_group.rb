module Seeka
  class ConditionGroup

    attr_reader :query
    attr_reader :type

    def initialize(query, type)
      @query = query
      @type = type
    end

    def params
      @params ||= []
    end

    #
    # Return all the includes which are needed to query with this
    # condition group
    #
    def includes
      params.map(&:condition).map(&:includes).compact.flatten
    end

    #
    # Return all the additional joins which are needed
    #
    def joins
      params.map(&:condition).map(&:joins).compact.flatten
    end

    #
    # Return the full SQL query needed for this condition group. It
    # will take all the values from the associated conditions and
    # add them together using an appropriate joiner for this condition
    # group.
    #
    def sql_query
      results = query.definition.model
      sql = params.map { |p| p.condition.sql_query.to_sql}.join(joiner)
      "(#{sql})"
    end

    def to_hash
      {
        :type => @type,
        :params => params.map(&:to_hash)
      }
    end

    private

    def joiner
      type.to_s.downcase == 'all' ? ' AND ' : ' OR '
    end

  end
end
