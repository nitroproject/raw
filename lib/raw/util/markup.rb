begin ; require "redcloth" ; rescue LoadError ; end

require "cgi"

require "raw/util/html_filter"

module Raw

# Generalised Markup transformations.
#
# The expand methods evaluate (expand) the markup
# code to produce the final content. The compact
# methods reverse this process to create the original
# markup code. Not all markup transformations are
# reversible.
#
# When this library is included, the default PropertyUtils
# implementation is overriden to add markup support.
#
# === Examples
#
# Define your custom markup methods like this:
#
# module Markup
#   def markup_simple
#      ...
#    end
#    def markup_special
#      ...
#    end
#
#   # maps the {{..}} macro
#    alias_method :sanitize, :markup_simple
#    # maps the {|..|} macro
#    alias_method :markup, :markup_special
#  end
#
# here comes the #{obj.body} # => prints the expanded version.
#
#  obj.body = markup(@params['body'])

module Markup

private
  # The default markup method. You should override this method
  # in your application to call your custom markup
  # methods.

  def expand(str)
    if str
      xstr = str.dup.html_filter
#      xstr.gsub!(/</, '&lt;')
#      xstr.gsub!(/>/, '&gt;')
      xstr.gsub!(/\n/, '<br />')

      return xstr
    end
    return nil
  end
  alias_method :sanitize, :expand

  # Translates a String with Textile/Markdown formatting
  # into XHTML. Depends on the RedCloth gem to work properly

  def expand_redcloth(str)
    if str
      begin
        RedCloth.new(expand(str)).to_html
      rescue
        "You called expand_redcloth(), but it needs RedCloth installed to work"
      end
    else
      nil
    end
  end

  alias_method :markup, :expand_redcloth

  # Compact (reverse) the content to the origial markup
  # code. Not all markup transformations are reversible.
  # You should override this method in your application
  # to call your custom markup methods.
  #
  # NOT IMPLEMENTED.

  def compact(str, meth = nil)
  end

  # Remove markup code from the input string.
  #
  # NOT IMPLEMENTED.

  def clear(str)
  end

  def escape(str)
    CGI.escape(str.gsub(/ /, '_'))
  end

  def unescape(str)
    CGI.unescape(str.gsub(/_/, ' '))
  end

  # Markup class-level extensions.

  module Self
    # Helper method for manipulating the sanitize transformation.

    def setup_sanitize_transform(&block)
      self.send :define_method, :sanitize, block
    end
    alias_method :setup_sanitize_transformation, :setup_sanitize_transform

    # Helper method for manipulating the markup transformation.

    def setup_markup_transform(&block)
      self.send :define_method, :markup, block
    end
    alias_method :setup_markup_transformation, :setup_markup_transform
  end
end

# An abstract Markup class.

class MarkupKit
  can Markup    # can is an alias for extend
   is Markup
end

end

