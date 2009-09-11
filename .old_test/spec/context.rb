require "script/lib/spec"
require "ostruct"

require "raw"

module Raw

  describe Context do
    it "should have a status code of 200" do
      conf = OpenStruct.new
      conf.dispatcher = nil
      c = Context.new(conf)
      c.status.should eql(200)   #type+value comparison
    end
  end

end
