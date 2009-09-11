require File.join(File.dirname(__FILE__), 'CONFIG.rb')

require 'test/unit'

require 'glue'
require 'nitro/compiler/elements'

include Nitro

$source = %{
<html>
  <?r a = 5 ?>
  Here is some text
  <body style="hidden" name="1">
    Some more
    <Box color="#f00">
      Hello World
      <Box color="#ff0">
        <b>nice</b>
        <i>stuff</i>
        <Box color="#fff">
          It works
        </Box>
      </Box>
      Text
    </Box>
    The End
  </body>
</html>
}

$source2 = %{
  <x:box color="#ff0">
    xhtml mode
  </x:box>  
}

$source3 = %{
  <Page>
    <Box>Hello</Box>
    <Box>World</Box>
    <Bar>Foo</Bar>
  </Page>
}

class Page < Nitro::Element
  def render
    %~
    <html id="2">
      #{content}
      #{content :bar}
    </html>
    ~
  end
end

class Box < Nitro::Element
  def open
    %|<div style="color: #@color">|
  end
  
  def close
    "</div>"
  end
end

class Bar < Nitro::Element
  def render
    %~
    This is a great #{content}.
    ~
  end
end

class TC_Element < Test::Unit::TestCase # :nodoc: all
  def test_all
    compiler_mock = Struct.new(:controller).new
    
    res = ElementCompiler.transform($source, compiler_mock)
    assert_match /div style/, res
    res = ElementCompiler.transform($source2, compiler_mock)
    assert_match /div style/, res
    res = ElementCompiler.transform($source3, compiler_mock)
  end
end
