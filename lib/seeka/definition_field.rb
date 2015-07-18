module Seeka
  class DefinitionField

    attr_accessor :group

    def initialize(name, options = {})
      @name = name
      @options = options

      options[:field] ||= @name
      options[:operators] ||= condition.available_operators
      options[:transmogrification] ||= :none
      options[:value_transmogrification] ||= :none
      options[:input_type] ||= 'string'
      options[:select_options] ||= []
    end

    attr_reader :name, :options

    def label
      @label ||= begin
        if options[:label]
          options[:label]
        else
          translations = I18n.translate("seeka.fields", :default => {})
          translations[@name.to_sym] || @name.to_s.humanize
        end
      end
    end

    def condition
      options[:condition] ||= begin
        if options[:foreign_key] && options[:base]
          Conditions::SubQuery
        elsif options[:field].is_a?(Hash)
          Conditions::BelongsTo
        else
          Conditions::Local
        end
      end
    end

    def select_options
      options[:select_options].is_a?(Proc) ? options[:select_options].call(query, self) : options[:select_options]
    end

    def to_hash
      {
        :name => @name,
        :label => self.label,
        :input_type => options[:input_type],
        :operators => available_operators,
        :select_options => select_options
      }
    end

    def available_operators
      available_operators ||= begin
        condition.available_operators.map do |o|
          translations = I18n.translate('seeka.operators', :default => {})
          {:key => o, :label => translations[o.to_sym] || o.to_s.humanize.downcase}
        end
      end
    end

  end
end
