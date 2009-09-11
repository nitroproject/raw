require File.join(File.dirname(__FILE__), "..", "..", "helper.rb")

require "raw/cgi/cookie"

describe "the cookie" do
  
  it "is valid" do
    c = Raw::Cookie.new
    c.path.should == "/"
  end

end
