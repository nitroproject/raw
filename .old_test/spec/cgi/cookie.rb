require "script/lib/spec"
require "raw/cgi/cookie"

module Raw
  
  describe Cookie do  
    before do
      @name, @value, @expire_time = 'cookie_name', 'cookie_value', Time.now
      @cookie = Cookie.new(@name, @value, @expire_time)
      @output = {}
      @cookie.to_s.split(/; /).map do |q| 
        k,v=q.split(/=/)
        @output[k]=v
      end
    end

    it "should initially have '/' as path" do
      @cookie.path.should == '/'
    end

    it "should report expire timestamp in the format used by HTTP/1.1 (rfc2616)" do
      wkdays = %w(Mon Tue Wed Thu Fri Sat Sun)
      months = %w(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec)
      @output['Expires'].should =~ /(\w{3}), (\d{2}) (\w{3}) (\d{4}) (\d{2}):(\d{2}):(\d{2}) GMT/
      if @output['Expires'] =~ /(\w{3}), (\d{2}) (\w{3}) (\d{4}) (\d{2}):(\d{2}):(\d{2}) GMT/
        wkday, day, month  = $1, $2.to_i, $3
        year, hour, minute = $4.to_i, $5.to_i, $6.to_i

        wkday.should be_in(wkdays)
        day.should be_in(1..31)
        month.should be_in(months)
        year.should be_in(1900..2100)
        hour.should be_in(0..23)
        minute.should be_in(0..59)
      end
    end

    it "should return the HTTP cookie string with to_s" do
      @output[@name].should == @value
    end
  end
end
