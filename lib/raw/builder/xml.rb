require "raw/builder"

module Raw

# A Builder for programmatically building XML blocks.
#--
# TODO: move to nitro or move mixins here.
#++

class XmlBuilder < Builder
  require "raw/view/xhtml"
  require "raw/view/form"
  require "raw/view/table"

  include_builder Raw::XhtmlHelper
  include_builder Raw::Mixin::TableHelper
  include_builder Raw::FormHelper

  def method_missing(tag, *args, &block)
    self.class.module_eval <<-"end_eval", __FILE__, __LINE__
      def #{tag}(*args)
        attrs = args.last.is_a?(Hash) ? args.pop : nil

        if block_given?
          start_tag!('#{tag}', attrs)
          yield
          end_tag!('#{tag}')
        elsif (!args.empty?)
          start_tag!('#{tag}', attrs)
          @buffer << args.first.to_s
          end_tag!('#{tag}')
        else
          start_tag!('#{tag}', attrs, false)
          @buffer << ' />'
        end

        return self
      end
    end_eval

    self.send(tag, *args, &block)
  end

  # Emit the start (opening) tag of an element.

  def start_tag!(tag, attributes = nil, close = true)
    unless attributes
      if close
        @buffer << "<#{tag}>"
      else
        @buffer << "<#{tag}"
      end
    else
      @buffer << "<#{tag}"
      for name, value in attributes
        if value
          @buffer << %| #{name}="#{value}"|
        else
          @buffer << %| #{name}="1"|
        end
      end
      @buffer << ">" if close
    end

    return self
  end

  # Emit the end (closing) tag of an element.

  def end_tag!(tag)
    @buffer << "</#{tag}>"

    return self
  end

  # Emit a comment.

  def comment!(str)
    @buffer << "<!-- #{str} -->"

    return self
  end

  # Emit a processing instruction.

  def processing_instruction!(name, attributes = nil)
    unless attributes
      @buffer << "<?#{name} ?>"
    else
      @buffer << "<?#{name} "
      attributes.each do |a, v|
        @buffer << %[#{a}="#{v}" ]
      end
      @buffer << "?>"
    end

    return self
  end
  alias_method :pi!, :processing_instruction!

end

end
