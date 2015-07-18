module Seeka
  class Definition

    #
    # Stores the base object which will be searched on
    #
    attr_accessor :base

    #
    # Return the name of the model for our base
    #
    def model
      @model ||= base.respond_to?(:proxy_association) ? base.proxy_association.reflection.class_name.constantize : base
    end

    #
    # Returns all the fields which are available on this definition
    #
    def fields
      @fields ||= []
    end

    #
    # Set some groups
    #
    def group(group_name, &block)
      fields = []
      block.call(fields)
      fields.each { |f| f.group = group_name }
      @fields = (self.fields || []) | fields
    end

    #
    # Return the definition field for the given name
    #
    def field_for(name)
      fields.select { |f| f.name.to_sym == name.to_sym }.first
    end

    #
    # To Hash
    #
    def to_hash
      {:fields => fields.group_by(&:group).map { |g, i| [g, i.map(&:to_hash)] } }
    end

    def to_json
      to_hash.to_json
    end

  end
end
