require "script/lib/spec"
require 'ostruct'

require 'glue'
require 'glue/logger'
require 'nitro'
require 'raw'

class FirstController < Raw::Controller
  def list ; end
end

class SecondController < Raw::Controller
  attr_reader :aqflag, :tflag

  def self.setup_template_root(path)
    @template_root << File.expand_path(File.join(Raw::LibPath, "../test/public/#{path}"))
  end   

  def list
    @aqflag = true 
  end

  def another(oid)
    # nop
  end

  private
    def encode_myself
      encode_url :list
    end

    def encode_first
      encode_url FirstController, :list
    end
end


module Raw
  describe Controller do

    before do
      @disp = Dispatcher.new('/first'  => FirstController, 
                             '/second' => SecondController)
      @conf = OpenStruct.new
      @conf.dispatcher = @disp
      
      @conf.compiler = Compiler.new(@conf)
    end

    it "should do some veritably interesting stuff, this was called test_render" do
      ctx = Context.new(@conf)
      ctx.headers = {"REQUEST_METHOD"=>"GET"}
      ctx.params = {}
      ctx.headers['REQUEST_URI'] = '/second/list'
      ctx.instance_eval '@session = {}'
      klass, action = ctx.dispatcher.dispatch(ctx.uri, ctx)
      c = klass.new(ctx)

      begin
        c.send(action)
      rescue RenderExit
        # drink
      end

      c.send(:encode_myself).should == '/second/list'
      c.send(:encode_first).should == '/first/list'
      
      # handle action with arity.
      c.send(:encode_url, :another, :oid, 32).should == '/second/another/32'

      c.aqflag.should == true
    end

    it "should report it's newly defined methods as action_methods" do
      FirstController.action_methods.should == ['list']
      FirstController.action_methods.size.should == 1
      
      SecondController.action_methods.size.should == 4
      SecondController.action_methods.should include('list')
    end

    it "it should know it's mount path, on class and instance level" do
      FirstController.mount_path.should == '/first'
      SecondController.mount_path.should == '/second'

      FirstController.mount_path.should == '/first'
      SecondController.mount_path.should == '/second'
    end

    after do
      @disp = @conf = nil
    end
  end

end
