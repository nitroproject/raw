#
# Used by the Raw::Cgi spec
#
# Adds a String.random method, using ruby inline for speed if available
#

class String
  class << self

    begin
      require "inline"

      inline do |builder|
        builder.c_raw <<-EOS
          static VALUE rnd(int argc, VALUE* args, VALUE self)
          {
            if (!argc)
              rb_raise(rb_eArgError, "not enough arguments");
            if (argc > 0)
              Check_Type(args[0], T_FIXNUM);
            if (argc > 1)
              Check_Type(args[1], T_FIXNUM);

            int size = FIX2INT(args[0]);
            int seed = argc > 1 ? FIX2INT(args[1]) : 0;
            int i = 0;
            VALUE str = rb_str_new((char*)0, size);

            srandom(seed);

            for (; i < size; i++) {
              RSTRING(str)->ptr[i] = (char)(((random() % ('z' - ' ')) + ' '));
            }

            return str;
          }
        EOS
      end

      def random(size, seed = 22)
        return rnd(size.to_i, seed.to_i)
      end

    rescue Exception => e
      puts "please install Ruby::Inline (gem install RubyInline) to speed up this test"

      def random(size)
        s = String.new
        range = (' '..'z').to_a
        r_size = range.size
        for i in (0...size)
          s << range[Kernel.rand(r_size)] # ascii range
        end
        s
      end

    end

  end
end

require "script/lib/spec"

describe "The String.random spec helper" do
  before do
    @size = 500
    @str = String.random(@size)
  end

  it "should return a String of the given length" do
    @str.size.should == @size
  end

  it "Should only include bytes between ASCII 32 (space) and ASCII 122 (z)" do
    @str.each{|x| (' '..'z').should include(x) }
  end
  
  after do
    @size = nil
    @str = nil
  end
end
