module Raw

# A helper mixin for programmatically building XML
# blocks.
#--
# gmosx, INVESTIGATE: is this used or deprecated?
#++

module XmlHelper

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
          self << args.first
          end_tag!('#{tag}')
        else
          start_tag!('#{tag}', attrs, false)
          self << ' />'
        end
      end
    end_eval

    self.send(tag, *args, &block)
  end

  # Emit the start (opening) tag of an element.

  def start_tag!(tag, attributes = nil, close = true)
    unless attributes
      if close
        self << "<#{tag}>"
      else
        self << "<#{tag}"
      end
    else
      self << "<#{tag}"
      for name, value in attributes
        if value
          self << %| #{name}="#{value}"|
        else
          self << %| #{name}="1"|
        end
      end
      self << ">" if close
    end

    return self
  end

  # Emit the end (closing) tag of an element.

  def end_tag!(tag)
    self << "</#{tag}>"

    return self
  end

  # Emit a text string.

  def text!(str)
    self << str

    return self
  end
  alias_method :print, :text!

  # Emit a comment.

  def comment!(str)
    self << "<!-- #{str} -->"

    return self
  end

  # Emit a processing instruction.

  def processing_instruction!(name, attributes = nil)
    unless attributes
      self << "<?#{name} ?>"
    else
      self << "<?#{name} "
      attributes.each do |a, v|
        self << %[#{a}="#{v}" ]
      end
      self << "?>"
    end
  end
  alias_method :pi!, :processing_instruction!

end

# A class that encapsulats the XML generation
# functionality. Utilizes duck typing to redirect
# output to a target buffer.

class XmlBuilder
  include XmlHelper

  # The target receives the generated xml,
  # should respond_to :<<

  attr_accessor :target

  def initialize(target = '')
    @target = target
  end

  def << (str)
    @target << str
  end

  def to_s
    @target.to_s
  end
end

end
