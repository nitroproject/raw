require File.join(File.dirname(__FILE__), "..", "..", "helper.rb")

require "nitro"
require "raw/dispatcher/format"
require "raw/dispatcher/format/html"

class DummyFilter1
end

class DummyFilter2
end

class DummyFilter3
end

class DummyFilter4
end

class DummyFilter5
end

# Lets test.

describe "the format implementation" do

  before do
    @f = Raw::HTMLFormat.new
  end
  
  it "allows manipulation of the template filters pipeline" do
    @f.insert_filter_at_head(DummyFilter1)
    @f.instance_variable_get("@template_filters").first.class.should == DummyFilter1

    @f.insert_filter_at_tail(DummyFilter2)
    @f.instance_variable_get("@template_filters").last.class.should == DummyFilter2

    @f.insert_filter(DummyFilter3, 2)
    @f.instance_variable_get("@template_filters")[2].class.should == DummyFilter3
  
    @f.insert_filter_before(DummyFilter4, Raw::CleanupFilter)
    @f.instance_variable_get("@template_filters")[5].class.should == DummyFilter4

    @f.insert_filter_after(DummyFilter5, Raw::CleanupFilter)
    @f.instance_variable_get("@template_filters")[7].class.should == DummyFilter5 
  end
    
end
