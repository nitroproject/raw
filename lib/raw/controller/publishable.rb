require "facets/annotations"

require "raw/controller/render"
require "raw/controller/caching"
require "raw/controller/cookie"
require "raw/context/flash"
require "raw/compiler"
require "raw/compiler/filter/template"
require "raw/util/encode_uri"
require "raw/util/markup"

module Raw

# Include this Mixin to a class to make objects of this class
# publishable, ie accessible through a standard web (REST)
# interface.

module Publishable
  is Render
  is EncodeURI
  is CookieHelper
  is Markup

  # TODO: Why are thses not simply included like any other module?

  def self.included(base)
    super
    base.send(:include, Flashing)
    base.send(:include, Caching)
  end

  # Use the method_missing hook to compile the actions
  # for this controller.

  def method_missing(action, *args)
    if Context.current.application.compiler.compile(self.class, action)
      send(action, *args)
    else
      super
    end
  end

  # Publishable class-level extenesions.

  module Self

    # The path where this controller is mounted.

    attr_accessor :mount_path

    # Return the 'action' methods for this Object. Some
    # dangerous methods from ancestors are removed. All private
    # methods are ignored.
    #--
    # gmosx, TODO: We should optimize this method.
    #++

    def action_methods
      public_instance_methods - Controller.public_instance_methods
    end
    alias_method :actions, :action_methods

    # Check if the controller responds to this action.

    def action?(action)
      action_methods.include?(action.to_s)
    end
    alias_method :respond_to_action?, :action?

    # Check if the a template for this action and format exists.
    # Returns a valid path or nil.

    def template?(action, format)
      # Allow for template override using the :template annotation
      #
      # class MyController
      #   def myaction
      #   end
      #   ann :myaction, :template => :another_template
      # end

      template = ann(action, :template) || action

      template = template.to_s.gsub(/__/, "/")

      for dir in ann(:self, :template_dir_stack)
        name = "#{dir}/#{template}".squeeze("/")

        # attempt to find a template of the form:
        # dir/action.xhtml

        path = "#{name}.#{format.template_extension}"
        return path if File.exist?(path)

        # attempt to find a template of the form:
        # dir/action/index.xhtml

        path = "#{name}/index.#{format.template_extension}"
        return path if File.exist?(path)
      end

      return nil
    end
    alias_method :has_template?, :template?
    alias_method :template_path, :template?

    # Check if this action or template exists.

    def action_or_template?(action, format)
      action?(action) or template?(action, format)
    end
    alias_method :respond_to_action_or_template?, :action_or_template?

    # Aliases an action
    #--
    # gmosx, FIXME: better implementation needed.
    # gmosx, FIXME: copy all annotations.
    #++

    def alias_action(new, old)
      alias_method new, old
      ann new, :template => old
    end

    # Override this method to customize the template_dir_stack.
    # Typically used in controllers defined in reusable Parts.
    # Call super to include the parent class's customizations.
    # Implements some form of template root inheritance,
    # thus allowing for more reusable controllers. Ie you can
    # 'extend' a controller, and only override the templates
    # you want to change. The compiler will traverse the
    # template dir stack and use the templates from parent
    # controllers if they are not overriden.
    #
    # def self.setup_template_dir_stack(stack)
    #   super
    #   stack << "custom/route/#{self.mount_path}"
    #   stack << "another/route"
    # end

    def setup_template_dir_stack(path)
    end

    # This callback is called when this controller is mounted.

    def mount_at(path)
      @mount_path = path

      # Setup the template_dir_stack.

      stack = []
      stack << File.join(Template.root_dir, path).gsub(/\/$/, "")
      self.setup_template_dir_stack(stack)
      stack << File.join(Nitro.proto_path, "app", "template", path).gsub(/\/$/, "")

      ann(:self, :template_dir_stack => stack)
    end
    alias_method :mount, :mount_at

  end

end

end
