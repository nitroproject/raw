require File.join(File.dirname(__FILE__), "..", "..", "helper.rb")

require "nitro"
require "raw/dispatcher/mounter"

class RootController
end

class UsersController
end

class Article
end

class Article::Controller
end

# Lets test.

describe "the dispatcher mounter system" do

  before do
    @d = Raw::Dispatcher.new
  end
  
  it "allows builder-style 'mounting' of controllers" do
    @d.root = RootController
    @d.root.users = UsersController
    
    @d[""].should == RootController
    @d["/users"].should == UsersController
  end

  it "handles 'default' controllers (ie, Model -> Model::Controller)" do
    @d.root = Article
     
    @d[""].should == Article::Controller
  end
  
end
