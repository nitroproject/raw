require "raw/builder/xml"

require 'raw/view/control'
require 'raw/view/control/none'

require 'raw/view/control/attribute/fixnum'
require 'raw/view/control/attribute/float'
require 'raw/view/control/attribute/text'
require 'raw/view/control/attribute/password'
require 'raw/view/control/attribute/textarea'
require 'raw/view/control/attribute/checkbox'
require 'raw/view/control/attribute/options'
require 'raw/view/control/attribute/file'

require 'raw/view/control/relation/refers_to'
require 'raw/view/control/relation/has_many'

module Raw

# The FormHelper can be included in a controller to make the
# 'form' method available in the views.
#
#   class MyController
#     include FormHelper
#     ...
#   end
#
# in the view:
#   #{form(:object => MyModelClass, :action => [ControllerClass, :action_name]) do |f|
#       f.attribute :model_attr
#       f.all_attributes
#       f.br
#       f.submit 'Send it'
#     end}
#
# Raw::FormHelper#form has more information on the parameters passed
# to the form method. The object in the block is of type
# Raw::FormHelper::FormXmlBuilder, an XML builder object with specialised
# methods for building forms that relate to managed objects.

module FormHelper

  # A specialized Builder for dynamically building of forms.
  # Provides extra support for forms backed by managed objects
  # (entities).
  #--
  # TODO: allow multiple objects per form.
  # TODO: use more generalized controls.
  #++

  class FormXmlBuilder < ::Raw::XmlBuilder

    # Mappings of control names to controls.

    setting :control_map, :doc => 'Mappings of control names to controls', :default => {
      :fixnum => FixnumControl,
      :integer => FixnumControl,
      :float => FloatControl,
      :true_class => CheckboxControl,
      :boolean => CheckboxControl,
      :checkbox => CheckboxControl,
      :string => TextControl,
      :password => PasswordControl,
      :textarea => TextareaControl,
      :file => FileControl,
      :webfile => FileControl,
=begin
      :array => ArrayControl,
=end
      :options => OptionsControl,
      :refers_to => RefersToControl,
      :has_one => RefersToControl,
      :belongs_to => RefersToControl,
      :has_many => HasManyControl,
      :many_to_many => HasManyControl,
      :joins_many => HasManyControl
    }

    # Returns a control for the given objects attribute.

    def self.control_for(obj, a, anno, options)
      raise "Invalid attribute '#{a}' for object '#{obj}'" if anno.nil?
      name = anno[:control] || anno[:class].to_s.demodulize.underscore.to_sym
      control_class = self.control_map.fetch(name, NoneControl)
      return control_class.new(obj, a, options)
    end

    # Returns a control for the given objects relation.

    def self.control_for_relation(obj, rel, options)
      name = rel[:control] || rel.class.to_s.demodulize.underscore.to_sym
      control_class = self.control_map.fetch(name, NoneControl)
      return control_class.new(obj, rel, options)
    end

    def initialize(buffer = '', options = {})
      super
      @obj = options[:object]
      @errors = options[:errors]
    end

    # Render a control+label for the given property of the form
    # object.

    def attribute(a, options = {})
      if anno = @obj.class.ann(a)
        control = self.class.control_for(@obj, a, anno, options)
        print element(a, anno, control.render)
      else
        raise "Undefined attribute '#{a}' for class '#{@obj.class}'."
      end
    end
    alias_method :attr, :attribute

    # Render controls for all attributes of the form object.
    # It only considers serializable attributes.

    def all_attributes(options = {})
      for a in @obj.class.serializable_attributes
        prop = @obj.class.ann(a)
        unless options[:all]
          next if a == @obj.class.primary_key or prop[:control] == :none or prop[:relation] or [options[:exclude]].flatten.include?(a)
        end
        attribute a, options
      end
    end
    alias_method :attributes, :all_attributes
    alias_method :serializable_attributes, :all_attributes

    # === Input
    #
    # * rel = The relation name as symbol, or the actual
    #   relation object.
    #--
    # FIXME: Fix the mismatch with the attributes.
    #++

    def relation(rel, options = {})
      # If the relation name is passed, lookup the actual
      # relation.

      if rel.is_a? Symbol
        rel = @obj.class.relation(rel)
      end

      control = self.class.control_for_relation(@obj, rel, options)
      print element(rel[:symbol], rel, control.render)
    end
    alias_method :rel, :relation

    # Render controls for all relations of the form object.

    def all_relations(options = {})
      for rel in @obj.class.relations
        unless options[:all]
          # Ignore polymorphic_marker relations.
          #--
          # gmosx: should revisit the handling of polymorphic
          # relations, feels hacky.
          #++
          next if (rel[:control] == :none) or rel.polymorphic_marker?
        end
        relation rel, options
      end
    end
    alias_method :relations, :all_relations

    # Renders a control to select a file for upload.

    def select_file(name, options = {})
      print %|<input type="file" name="#{name}" />|
    end

    # If flash[:ERRORS] is filled with errors structured as
    # name/message pairs the method creates a div containing them,
    # otherwise it returns an empty string.
    #
    # So you can write code like
    #  #{form_errors}
    #  <form>... </form>
    #
    # and redirect the user to the form in case of errors, thus
    # allowing him to see what was wrong.

    def form_errors
      res = ''

      unless @errors.empty?
        res << %{<div class="error">\n<ul>\n}
        for err in @errors
          if err.is_a? Array
            res << "<li><strong>#{err[0].to_s.humanize}</strong>: #{err[1]}</li>\n"
          else
            res << "<li>#{err}</li>\n"
          end
        end
        res << %{</ul>\n</div>\n}
      end

      print(res)
    end

  private

    # Emit a form element. Override this method to customize the
    # rendering for your application needs.

    def element(a, anno, html)
      # TODO: give better form id!
      %{
        <p id="form_#{a}">
          #{html}
        </p>
      }
    end

  end

private

  # A sophisticated form generation helper method.
  # If no block is provided, render all attributes.
  #
  # === Options
  #
  # * :object, :entity, :class = The object that acts as model
  #   for this form. If you pass a class an empty object is
  #   instantiated.
  #
  # * :action = The action of this form. The parameter is
  #   passed through the R operator (encode_uri) to support
  #   advanced uri transformation.
  #
  # * :errors = An optional collection of errors.
  #
  # === Example
  #
  # #{form(:object => @owner, :action => :save_profile) do |f|
  #   f.attribute :name, :editable => false
  #   f.attribute :password
  #   f.br
  #   f.submit 'Update'
  # end}

  def form(options = {}, &block)
    obj = (options[:object] ||= options[:entity] || options[:class])

    # If the passed obj is a Class instantiate an empty object
    # of this class.

    if obj.is_a? Class
      obj = options[:object] = obj.allocate
    end

    # Convert virtual :multipart method to method="post",
    # enctype="multipart/form-data"

    if options[:method] == :multipart
      options[:method] = "POST"
      options[:enctype] = "multipart/form-data"
    end

    options[:errors] ||= []

    if errors = flash[:ERRORS]
      if errors.is_a? Array
        options[:errors].concat(errors)
      elsif errors.is_a? ::Validation::Errors
        options[:errors].concat(errors.to_a)
      else
        options[:errors] << errors
      end
    end

    if obj and errors = obj.validation_errors
      options[:errors].concat(errors.to_a)
    end

    b = FormXmlBuilder.new('', options)

    b << '<form'
    b << %| action="#{R *options[:action]}"| if options[:action]
    b << %| method="#{options[:method]}"| if options[:method]
    b << %| accept-charset="#{options[:charset]}"| if options[:charset]
    b << %| enctype="#{options[:enctype]}"| if options[:enctype]
    b << '>'

    b.hidden(:oid, obj.oid) if obj and obj.saved?

    # If no block is provided, render all attributes.

    if block_given?
      yield b
    else
      b.all_attributes
    end

    b << '</form>'

    return b
  end

end

end
