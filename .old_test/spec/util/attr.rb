require "script/lib/spec"

require "facets/more/ann_attr"
require "og"
require "og/util/ann_attr"
require "raw/util/attr"
  
class Dummy
  attr_accessor :live, TrueClass
  define_force_methods
end

describe "The AttributeUtils#populate_object method" do
  it "sets non-params booleans to false" do
    d = Dummy.new
    AttributeUtils.populate_object(d, {})
    d.live.should be_false    
  end
end
