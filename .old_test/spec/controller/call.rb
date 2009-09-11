require "script/lib/spec"

require "raw/controller/call"

class Mock
  include Raw::Render
  
  class Req
    attr_accessor :method
    
    def post?
      @method == :post
    end
    
    def initialize(method)
      @method = method
    end

    def uri
      "http://nitroproject.org"
    end
  end
  
  attr_accessor :request
  attr_accessor :session
  
  def initialize(method)
    @request = Req.new(method)
    @session = {}
  end
    
  def redirect(*args)
  end
end

describe "Render#call implements a Seaside style call/answer mechanism. The method" do

  setup do
    @mp = Mock.new(:post)
    @mg = Mock.new(:get)
  end

  it "calls if the request method is not POST" do
    @mg.send(:call, :hello)
    @mg.session.should have_key(:CALL_STACK)
  end

  it "redirects if the request method is POST" do
    @mp.send(:call, :hello)
    @mp.session.should_not have_key(:CALL_STACK)
  end

end
