require "script/lib/spec"

require "raw/dispatcher"

module Nitro
  STANDARD_FORMATS=[]

  def Nitro.proto_path
    ''
  end
end

module Raw
  describe Dispatcher::Mounter do
    RootController = Class.new
    LinkController = Class.new
    LinkCommentController = Class.new
    UserController = Class.new
    
  
    before do
      @d = Dispatcher.new
    end
  
    after do
      @d = nil
    end

    it "should mount '/' with #root=" do
      @d.root = RootController
      @d["/"].should == RootController
    end

    it "should mount at a path based on the method name" do
      @d.root = RootController
      @d.root.links = LinkController
      @d["/links"].should == LinkController
    end

    it "should store the parent controller as an annotation on the child" do
      @d.root = RootController
      @d.root.links = LinkController
      LinkController.ann(:self, :parent).should == RootController

      @d.root.links.comments = LinkCommentController
      @d["/links/comments"].should == LinkCommentController
      LinkCommentController.ann(:self, :parent).should == LinkController
    end
      
    it "should allow multiple paths at the same level" do
      @d.root = RootController
      @d.root.links = LinkController
      @d.root.users = UserController
      @d["/users"].should == UserController
      @d["/links"].should == LinkController
    end
  
  end
end
