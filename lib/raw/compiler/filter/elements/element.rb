require "facets/stylize"
#require "facets/string/demodulize"
#require "facets/string/camelize"
require "facets/string/capitalized"
#require "facets/kernel/method_name" #methodize?
require "facets/dir/recurse"
require "facets/settings"
require "facets/dictionary"

module Raw

# A programmatically generated element. Elements are a form
# of macros to allow for cleaner templates. They are evaluated
# at compile time, so there is no performance hit when you use
# them (at the expense of slightly reduced functionality).
#
# Raw provides an additional method of defining elements.
# Instead of creating a lot of small classes, you can put
# .htmlx templates in the Element template_root. These templates
# are automatically converted into Element classes.
#
# For extra safety, you are advised to place your classes in the
# Raw::Element namespace. If your classes do not extend
# Raw::Element, the Raw::ElementMixin is automatically
# injected in the class.
#
# An element can have and access a hierarchy of sub-elements.
# use #{content :sub_element_name} to access the render output
# of the subelement. Additionaly you can access the whole
# subelement object: _children[:sub_element_name]
#
# === Dynamic elements.
#
# Even though elements are evaluated at compile time (for
# performance reasons) you can still achieve many dyanmic effects.
# Here is an example that demonstrates the technique:
#
# class Box < Raw::Element
#   def render
#      %{
#      <div style="color: \#{#{@color}}">
#        #{content}
#      </div>
#      }
#   end
# end
#
# then use it like this:
#
# <?r
# colors = [ "#ff0", "#f00", "#00f", #"0ff" ]
# ?>
# <h1>Dynamic boxes</h1>
#
# <Box color="colors[rand(colors.size)]">
#   This box is randomly colored ;-)
# </Box>
#
# To make the Element render method  more elegant, you can use
# the attr (or attribute helper). You can replace:
#
#   <div style="color: \#{#{@color}}">
#
# with
#   <div style="color: #{attr :color}">
#
# or
#   <div style="color: #{attribute :color}">
#
# === Design
#
# An underscore is used for the standard attibutes to avoid name
# clashes.

module ElementMixin
  # The parent of this element.

  attr_accessor :_parent

  # The children of this element.

  attr_accessor :_children
  alias_method :children, :_children

  # The text of this element.

  attr_accessor :_text

  # The view of this element.

  attr_accessor :_view

  # The id of this element.

  attr_accessor :id

  def initialize(id)
    @_children = Dictionary.new
    @_text = ""
    @id = id
  end

  # Prepend this code to the element content.

  def open
  end

  # If an optional name parameter is passed renders
  # the content of the named child element.
  #
  # eg. #{content :child_element_id}
  #
  # === Example
  #
  # <Page>
  #   ..
  #
  #   <Box id="hello">
  #     ..
  #   </Box>
  #
  #   <Box id="world">
  #     ..
  #   </Box>
  #
  #   <Sidebar>
  #     ..
  #   </Sidebar>
  #
  #   ..
  #
  # </Page>
  #
  # Access children content from within the enclosing element
  # (Page) like this:
  #
  # {content :hello}
  # {content :world}
  # {content :sidebar}

  def content(cname = nil)
    if cname
      if c = @_children[cname.to_s]
        c.content
      else
        return nil
      end
    else
      @_text
    end
  end

  # Access a child element.

  def child(cname)
    @_children[cname.to_s]
  end

  # Include a text file in the element template. All the
  # conventions of the StaticInclude compiler apply here. Please
  # not that unless you pass an absolute path (starting with
  # '/') you have to pass a controller instance as well.
  #
  # Example:
  #
  #   def render
  #     %~
  #     <div>
  #       #{include '/links/latest'}
  #     </div>
  #     ~
  #   end

  def include(href, controller = nil)
    filename = StaticIncludeFilter.new.resolve_include_filename(href)
    return ElementsFilter.new.apply(File.read(filename))
  end

  def attribute(a)
    return "\#{@#{a}}"
  end
  alias_method :attr, :attribute

  # Append this code to the element content.

  def close
  end

  # Override this.

  def render
    "#{open}#{content}#{close}"
  end

  def render_children
    str = ""
    for c in @_children.values
      str << c.render
    end

    return str
  end

  def add_child(child)
    child._parent = self

    key = child.instance_variable_get("@id")

    # The elements compiler assures the id is unique
    @_children[key] = child
  end

  alias_method :children, :_children

end

# A programmatically generated element.
#
# === Usage
#
# = in the code
#
# class Page < Raw::Element
#   def render
#     %{
#     <div id="@id">#{content}</div>
#     }
#   end
# end
#
# = in your template
#
# <Page>hello</Page>
#
# => <div id="page">hello</div>
#
# the id is automatically fille with the class name using
# class.methodize eg. MyModule::MyPage => my_module__my_page
#
# you can override the id to use the element multiple times on
# the page.
#
# == Sub Elements
#
# Elements can be imbricated. To render the the child element in
# the parent's template, use #{content :element_id}
#
# === Design
#
# An underscore is used for the standard attibutes to avoid name
# clashes.

class Element
  include ElementMixin

  # The prefix for element tags (in xhtml compatibility mode)

  setting :prefix, :default => "x", :doc => "The prefix for element tags"

  # Allow auto extension of element classes?

  setting :auto_extend, :default => true, :doc => "Allow auto extension of element classes?"
end

end
