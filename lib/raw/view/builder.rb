require "raw/builder/xml"

module Raw

module Render

  # Access the programmatic renderer (builder).

  def build(&block)
    if block.arity == 1
      yield XmlBuilder.new(@out)
    else
      XmlBuilder.new(@out).instance_eval(&block)
    end
  end

  # Return a programmatic renderer that targets the
  # output buffer.

  def builder
    XmlBuilder.new(@out)
  end

end

end
