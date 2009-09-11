require File.join(File.dirname(__FILE__), "..", "..", "helper.rb")

require "nitro"
require "raw/dispatcher/router"

class UserController
  def view
  end
  
  def self.mount_path
    ""
  end
end

# Lets test.

describe "the router" do

  before do
    @r = Raw::Router.new
  end
  
  it "defines routes" do
    @r.add_rule(:match => %r{^~(.*)}, :controller => UserController, :action => :view, :params => [:name])
    @r.decode_route("~gmosx").should == "/view/gmosx"
    @r.decode_route("~renos").should == "/view/renos"
  end
  
end
