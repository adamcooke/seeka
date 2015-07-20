require 'seeka/view_helpers'

module Seeka
  class Engine < ::Rails::Engine

    initializer 'seeka.initializer' do
      ActiveSupport.on_load(:action_view) do
        ActionView::Base.send :include, Seeka::ViewHelpers
      end
    end

  end
end
