require "script/lib/spec"

require "raw/util/markup"


module Raw
  class Test
    include Markup
  end

  describe "Raw::Markup" do

    before do
      @t = Test.new
    end
  
    it "should convert newlines to <br /> with #expand" do
      @t.send(:expand, "hello\nworld").should == "hello<br />world"
    end


    # FIXME : This test is converted from TC, it fails
    #         The call to expand simply strips the html returning "Hello World!"
    #         Either fix the code or fix the spec

    it "should convert < and > to &lt; and &gt; with #expand" do
      @t.send(:expand, "<p>Hello World!</p>").should == "&lt;p&gt;Hello World!&lt;/p&gt;"
    end

    it "should convert newlines to <br /> and insert <p>..</p> with #markup" do
      @t.send(:markup, "hello\nworld").should == "<p>hello<br />world</p>"
    end

    it "should do Redcloth expansion" do
      @t.send(:expand_redcloth, "h1. Hello World!").should == "<h1>Hello World!</h1>"
    end

    it "should do URL escaping" do
      @t.send(:escape, %{Marc & Joe went over the 'Hill' and shouted "Hello World!"}).should ==
        %{Marc_%26_Joe_went_over_the_%27Hill%27_and_shouted_%22Hello_World%21%22}
    end

    it "should do URL un-escaping" do
      @t.send(:unescape, %{Marc_%26_Joe_went_over_the_%27Hill%27_and_shouted_%22Hello_World%21%22}).should ==
        %{Marc & Joe went over the 'Hill' and shouted "Hello World!"}
    end
  
  end
end
