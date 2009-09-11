require File.join(File.dirname(__FILE__), "..", "helper.rb")

require "nitro"
require "raw/dispatcher"

# A simple controller.

class RootController
  def index
  end
  
  def delete
  end
end

# A simple model.

class Article
end

# The default controller for Article model.

class Article::Controller
  def index
  end
end

# Invalid controller (modules cannot be controllers).

module InvalidController
end

# Let's test.

describe "the dispatcher" do
  
  def mount(dispatcher)
    dispatcher.mount(
      "" => RootController,
      "/articles" => Article::Controller
    )
  end
  
  before do
    @d = Raw::Dispatcher.new
  end
  
  it "mounts controllers individually" do
    @d[""] = RootController
    @d["/articles"] = Article # mounts the default controller.

    @d[""].should == RootController
    @d["/articles"].should == Article::Controller
  end
  
  it "mounts controller in one go (from a hash)" do
    mount(@d)
    @d[""].should == RootController
    @d["/articles"].should == Article::Controller
  end

  it "dispatches to actions" do
    mount(@d)

    controller, action, query, params, format = @d.dispatch("/")   
    controller.should == RootController
    action.should == "index___super"
    query.should == nil
    params.should == []
    format.content_type.should == "text/html"

    controller, action, query, params, format = @d.dispatch("/articles")   
    controller.should == Article::Controller
    action.should == "index___super"
    format.content_type.should == "text/html"
  end
  
  it "raises an ArgumentError when mounting invalid controllers" do
    lambda {
      @d[""] = InvalidController 
    }.should raise_error(ArgumentError)
  end

  it "dispatches to index of the root controller when dispatching an empty string" do
    mount(@d)

    controller, action, query, params, format = @d.dispatch("")
    controller.should == RootController
    action.should == "index___super"
    format.content_type.should == "text/html"
  end
  
  it "sets the controller mount path" do
    mount(@d)
    
    RootController.mount_path.should == ""
    Article::Controller.mount_path.should == "/articles"
  end

  it "mounts the controller given to the constructor as root controller" do
    @d = Raw::Dispatcher.new(RootController)

    @d[""].should == RootController
  end

  it "handles trailing '/'s" do
    mount(@d)
    controller, action, query, params, format = @d.dispatch("/articles/")   
    controller.should == Article::Controller
    action.should == "index___super"
  end

end
