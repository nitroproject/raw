require File.join(File.dirname(__FILE__), "..", "..", "helper.rb")

require "facets/settings"

require "nitro"
require "raw"
require "raw/util/encode_uri"
require "raw/controller"
require "raw/dispatcher/format"
require "raw/dispatcher/format/html"

class Raw::Context
  class << self
    def current
      self
    end
    
    def dispatcher
      self
    end
    
    def router
      nil
    end
    
    def format
      Raw::HTMLFormat
    end
  end
end

class RootController
  def index
  end

  def view
  end
  
  def self.mount_path
    ""
  end
end

class TestController
  include Raw::Publishable
  include Raw::EncodeURI
  
  ann :self, :template_dir_stack => []

  def initialize(kok)
  end
    
  def index
  end
  
  def list
  end
  
  def view(name)
    puts name
  end
  
  def self.mount_path
    "/tests"
  end
end

class Model
end

class Model::Controller
  def self.mount_path
    "/models"
  end
end

describe "The encode_uri method" do

  before do
    @t = TestController.new(nil)
  end
  
  it "returns a string argument unchanged" do
    @t.send(:encode_uri, "/index").should == "/index"
  end
  
  it "gives special treatment to the 'index' action" do
    @t.send(:encode_uri, TestController, :index).should == "/tests"
  end

  it "respects the mount path" do
    @t.send(:encode_uri, TestController, :index).should == "/tests"
    @t.send(:encode_uri, TestController, :list).should == "/tests/list"
  end

  it "respects the action arity and creates nice urls" do
    @t.send(:encode_uri, TestController, :view, :name, "George").should == "/tests/view/George"
  end
  
  it "accepts a Model and returns its Controller's mount_path" do
    @t.send(:encode_uri, Model).should == "/models"
  end

  it "correctly handles controllers mounted at '' (root)" do
    @t.send(:encode_uri, RootController).should == ""
    @t.send(:encode_uri, RootController, :view).should == "/view"
  end
  
end

