require File.join(File.dirname(__FILE__), "..", "..", "..", "helper.rb")

require "nitro"
require "raw/compiler/filter/elements"

class Container < Raw::Element
  def render
    # store the children dictionary so we can assert in the test.
    $children = @_children
    %{<ul>#{content}</ul>}
  end
end

class Box < Raw::Element
  def render
    %{<li>#{content}</li>}
  end
end

class DBox < Raw::Element
  def render
    %{
    <div style="color: #{attr :color}">
      #{content}
    </div>
    }
  end
end

# Let's test.

describe "the Elements compiler filter" do

  before do
    @f = Raw::ElementsFilter.new
  end
  
  it "handles children elements without custom ids" do
    CHILDREN_WITHOUT_IDS = %{
    <Container>
      <Box>box 1</Box>
      <Box>box 2</Box>
      <Box>box 3</Box>      
    </Container>
    }

    res = @f.apply(CHILDREN_WITHOUT_IDS)
    $children.size.should == 3
    $children["box"].should_not be_nil
    $children["box-2"].should_not be_nil
    $children["box-3"].should_not be_nil
    $children["box-5"].should be_nil
    res.should == "\n    <ul>\n      <li>box 1</li>\n      <li>box 2</li>\n      <li>box 3</li>      \n    </ul>\n    "   
  end
  
  it "can emulate dynamic behaviour (using the attr helper)" do
    SOURCE = %{
      <DBox color="colors[1]">hello</DBox>
    }
    res = @f.apply(SOURCE)
    res.should == "\n      \n    <div style=\"color: \#{@color}\">\n      hello\n    </div>\n    \n    "
  end

end
