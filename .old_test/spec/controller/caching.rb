require "script/lib/spec"
require "raw/controller/caching"

class DummyCa
  include Raw::Caching
end

describe Raw::Caching do
  it "should have no public instance methods" do
    normal = Object.public_instance_methods
    pim = Raw::Caching.public_instance_methods - normal
    pim.should == []
  end
end

describe "A class that mixes in Raw::Caching" do
  it "should have no public instance methods" do
    normal = Object.public_instance_methods
    pim = DummyCa.public_instance_methods - normal
    pim.should == []
  end
end
