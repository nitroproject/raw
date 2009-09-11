module Raw

# A Builder integrates a number of Modules containing text
# manipulation utilities and provides an alternative
# 'accomulation' interface.

class Builder

  # The builder output is accomulated in the buffer.

  attr_accessor :buffer

  class << self

    def include_builder(*modules)
      for mod in modules
        include mod
        for meth in mod.public_instance_methods
          self.module_eval %{
            alias_method :_mixin_#{meth}, :#{meth}
            def #{meth}(*args)
              @buffer << _mixin_#{meth}(*args)
              return self
            end
          }
        end
      end
    end
    alias_method :builder, :include_builder

  end

  # Provide the target where the builder output will be
  # accomulated. The builder utilizes duck typing to make it
  # compatible with any target responding to <<.

  def initialize(buffer = '', options = {})
    @buffer = buffer
  end

  # Emit a text string.

  def text!(str)
    @buffer << str

    return self
  end
  alias_method :print, :text!
  alias_method :<<, :text!

  def to_s
    @buffer.to_s
  end

end

end
