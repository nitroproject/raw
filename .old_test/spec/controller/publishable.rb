require "script/lib/spec"

require "raw"

class Test
  include Raw::Publishable

  def index
  end
  
  def view
  end
end

describe "A Publishable" do

  it "returns its locally defined public methods as actions" do
    actions = Test.action_methods
    actions.size.should == 2
    actions.should include("index")
    actions.should include("view")
  end

end
