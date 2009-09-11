require "script/lib/spec"

require "raw/controller"

#FIXME : This is a verbatim conversion from Test::Unit, it no longer runs
#FIXME : Add more specs to document how the compiler works

module Raw
  describe Compiler do
    class TestController < Controller
      def test(arg1, arg2); end
    end

    before do
      Server.map['/'] = TestController
      reset_context()
    end

    it "should raise nothing when no param specified" do

      lambda do
        process(:uri => '/test/two')
      end.should_not raise_error(Exception=nil, message=nil)

    end

  end
end
