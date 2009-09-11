require File.join(File.dirname(__FILE__), '..', 'CONFIG.rb')

require 'test/unit'

require 'nitro/test/testcase'
require 'nitro/compiler'

class TC_ClientMorpher < Test::Unit::TestCase
  class MyController < Nitro::Controller
    class Client
      def check_album
        ajax_update 'tools_block', {
          :action => 'checked_albums',
          :params => 'some parameters'
        }
      end
    end
  end

  Action_Name = :an_object_responding_to_the_method_to_sym_is_now_required_when_compiling_a_template

  def setup
    @compiler = Nitro::Compiler.new(MyController)
  end

  def teardown
    @compiler = nil
  end

  def test_javascript_no_params
    template = '<a href="#" client="check_album">Test</a>'
    result = @compiler.transform_template(Action_Name, template)
    assert_match(/__nc_check_album\(\)/, result)
  end

  def test_javascript_one_param
    template = '<a href="#" client="check_album" params="this.id">Test</a>'
    result = @compiler.transform_template(Action_Name, template)
    assert_match(/__nc_check_album\(this\.id\)/, result)
  end

  def test_javascript_multi_params
    template = '<a href="#" client="check_album" params="this.id, this.class">Test</a>'
    result = @compiler.transform_template(Action_Name, template)
    assert_match(/__nc_check_album\(this\.id, this\.class\)/, result)
  end    
end
