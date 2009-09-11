require "facets/inflect"

require "raw/element"

module Raw

# This helper uses Nitro's powerfull Elements mechanism to
# implement a simple Rails style Layout helper. Perhaps this
# may be useful for people coming over from Rails.
#
# WARNING: This is not enabled by default. You have to insert
# the LayoutCompiler before the ElementsCompiler for layout to
# work.

module LayoutHelper

  def self.included(base)
    base.module_eval do
      # Enclose all templates of this controller with the
      # given element.

      def self.layout(name = nil)
        klass = name.to_s.camelize

        unless klass
          if defined? 'Raw::Element::Layout'
            klass = Raw::Element::Layout
          end
        end

        if klass
          ann :self, :layout => klass
        end
      end
    end
  end

end

end
