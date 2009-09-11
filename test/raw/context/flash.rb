require File.join(File.dirname(__FILE__), "..", "..", "helper.rb")

require "raw/context/flash"

class AbstractController
  include Raw::Flashing
  
  attr_accessor :session
  
  def initialize
    @session = {}
  end
  
  public :flash, :flash_error
end

class MockValidationErrors
  def to_a
    [[:a1, "world"], [:a2, "hello"]]
  end
end

describe "the flash system" do
  
  before do
    @c = AbstractController.new
  end
     
  it "allows pushing of data" do
    @c.flash.push :DATA, "test1"
    @c.flash[:DATA].include?("test1").should == true
    @c.flash.push :DATA, "test2"
    @c.flash[:DATA].include?("test2").should == true
    @c.flash[:DATA].class.should == Array
  end
  
  it "provides a special helper for errors" do
    @c.flash_error "err1"
    @c.flash_error "err2"
    @c.flash_error "err3"    
    @c.flash[:ERRORS].size.should == 3
    @c.flash[:ERRORS].class.should == Array
    @c.flash[:ERRORS].include?("err3").should == true
  end

  it "handles validation errors" do
    ve = MockValidationErrors.new
    @c.flash_error ve
    @c.flash[:ERRORS].size.should == 2
    @c.flash[:ERRORS].class.should == Array
  end

end
