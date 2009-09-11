require "script/lib/spec"
require "raw/controller"
require "raw/context"

require "nitro/aspects"

# FIXME make it run
# FIXME make it pass
# FIXME make it better

module Raw  
  class TestController < Controller
    attr_reader :aflag, :tflag

    @template_root = []

    post "@aflag = 25", :on => :list
    
    def list
      @aflag = 3
    end
  end

  
  describe "nitro/aspects used inside a controller" do
    before do
      ctx = Context.new(Server.new) #where does this Server come from?
      ctx.instance_variable_set '@session', {}
      ctx.instance_variable_set '@headers', {}
      c = TestController.new(ctx)
      c.list_action
    end
    
    it "..." do
      c.aflag.should == 25
    end
  end

end
