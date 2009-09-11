require File.join(File.dirname(__FILE__), '..', 'CONFIG.rb')

require 'test/unit'
require 'nitro/helper/navigation'


class TC_NavigationHelper < Test::Unit::TestCase # :nodoc: all
  include Nitro
  include NavigationHelper
  FirstController = Class.new(Controller) do 
    def self.mount_path() "controller1" end
  end
  Second          = Class.new(Controller) do
    def self.mount_path() "controller2" end
  end
  MockRequest=Struct.new(:path)
  attr :request
  def setup
    @request=MockRequest.new("controller1")
  end
  def check_div(text)
    #offsets accomodate \n
    assert_equal '<div id="navcontainer">',text[0,23]
    assert_equal '</div>',text[-8,6]
  end
  def check_ul(text)
    assert_equal '<ul id="navlist">',text[25,17]
    assert_equal '</ul>',text[-14,5]
  end
  def test_navfor_around_html
    text= menu_for(FirstController)
    check_div(text)
    check_ul(text)
  end
  
  def test_navfor_inner_html_single
    text= menu_for(FirstController)
    text.gsub!(%r{</?(div|ul).*?>},'')
    text.gsub!("\n",'')
    assert_equal '<li id="active"><a href="controller1" id="current"> TC_NavigationHelper::First </a></li>',
                 text.strip
  end
  def test_navfor_inner_html_many             
    text = menu_for(FirstController,Second)
    assert_match %r|href="controller1" id="current">| , text
    assert_match %r|href="controller2">| , text
    assert_match %r| TC_NavigationHelper::First | , text
    assert_match %r| TC_NavigationHelper::Second |, text
  end
  
  def test_navfor_yielding
    text= menu_for(FirstController,Second) do |controller|
      controller==FirstController ? 'first' : 'second'
    end
    assert_match %r|<a href="controller1".*first </a>|,text
    assert_match %r|<a href="controller2".*second </a>|,text
  end
  def test_navforhash_around_html
    text= menu_from_hash('path'=>'text')
    check_div(text)
    check_ul(text)
  end
  
  def test_navforhash_inner_html_single
    text= menu_from_hash('link'=>'text')
    text.gsub!(%r{</?(div|ul).*?>},'')
    text.gsub!("\n",'')
    assert_equal '<li><a href="link"> text </a></li>',
                 text.strip
  end
  

               
end
