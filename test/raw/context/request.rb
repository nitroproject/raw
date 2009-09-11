require File.join(File.dirname(__FILE__), "..", "..", "helper.rb")

require "facets/dictionary"

require "raw/context/request"

class AbstractRequest
  include Raw::Request
  
  def initialize
    @get_params = Dictionary.new
  end
  
  def method
    :get
  end  
end

describe "the request params" do
  
  before do
    @r = AbstractRequest.new
    @r["name"] = "gmosx"
  end
     
  it "are accessed as a hash" do
    @r.params.class.should == Hash
  end

end
