require File.join(File.dirname(__FILE__), "..", "..", "helper.rb")

require "raw/view/nform"

PRIVATE_METHODS = [:form, :end_form, :start_form, :preserve_param]

class AbstractForm

  include Raw::Forms

  def R(str)
    str
  end

  def request
    { "name" => "gmosx", "position" => "CEO" }
  end
  
end

class PublicForm < AbstractForm
  
  for m in PRIVATE_METHODS
    public m
  end
  
end

describe "the form helper" do
  
  setup do
    @f = PublicForm.new
  end
  
  it "defines private methods" do
    f = AbstractForm.new
    
    for m in PRIVATE_METHODS
      f.private_methods.include?(m.to_s).should == true
    end
  end
  
  it "handles the start tag" do    
    @f.form.should == %{<form method="GET">}    
    @f.form(:method => :post).should == %{<form method="POST">}    
    @f.form(:id => "login_form", :action => "/login").should =~ /id="login_form"/   
  end

  it "handles the end tag" do
    @f.end_form.should == %{</form>}
  end
  
  it "can preserve request parameters" do
    e = %{<input type="hidden" name="name" value="gmosx" />}
    @f.preserve_param(:name).should == e
  end
  
end
