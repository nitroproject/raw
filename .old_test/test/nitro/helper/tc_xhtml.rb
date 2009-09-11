require File.join(File.dirname(__FILE__), '..', 'CONFIG.rb')

require 'test/unit'
require 'nitro/helper/xhtml'

class TC_XhtmlHelper < Test::Unit::TestCase # :nodoc: all
  include Nitro
  include XhtmlHelper

  def test_all
  end
  
  def test_popup
    res = popup :text => 'Pop', :url => 'add-comment', :scrollbars => true
    exp = %{<a href="#" onclick="javascript: var pwl = (screen.width - 320) / 2; var pwt = (screen.height - 240) / 2; window.open('add-comment', 'Popup', 'width=320,height=240,top='+pwt+',left='+pwl+', resizable=no,scrollbars=yes'); return false;"">Pop</a>}
    assert_equal exp, res    
  end

end
