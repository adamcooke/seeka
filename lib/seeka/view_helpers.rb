module Seeka
  module ViewHelpers

    def seeka_form(definition, url, query = nil, options = {})
      Array.new.tap do |html|
        html << "<script id='seekaDefinitionJSON' type='application/json'>#{definition.to_json}</script>"
        if query.is_a?(Seeka::Query)
          html << "<script id='seekaQueryJSON' type='application/json'>#{query.to_json}</script>"
        end
        html << form_tag(url, {:class => 'seeka__form'}.merge(options)) + "</form>".html_safe
      end.join("\n").html_safe
    end

  end
end
