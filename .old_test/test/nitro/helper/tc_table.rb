require File.join(File.dirname(__FILE__), '..', 'CONFIG.rb')

require 'test/unit'
require 'nitro/helper/table'

class TC_TableHelper < Test::Unit::TestCase # :nodoc: all
  include Nitro
  include TableHelper

  User = Struct.new(:name, :password, :email)

  def setup
    @headers = %w{Name Password Email}
    @users = [
      User.new('gmosx', 'huh?', 'gm@nowhere.com'),
      User.new('renos', 'nah', 'renos@nowhere.com'),
      User.new('stella', 'hoh', 'stella@love.com')
    ]
  end

  def teardown
    @users = nil
  end

  def test_table
    values = @users.collect { |u| [u.name, u.password, u.email] }
    table = build_table(:id => 'test', :headers => @headers, :values => values)
    res = %|<table id="test"><tr><th>Name</th><th>Password</th><th>Email</th></tr><tr><td>gmosx</td><td>huh?</td><td>gm@nowhere.com</td></tr><tr><td>renos</td><td>nah</td><td>renos@nowhere.com</td></tr><tr><td>stella</td><td>hoh</td><td>stella@love.com</td></tr></table>|
    assert_equal res, table
  end
  
  def test_table_footer
    values = @users.collect { |u| [u.name, u.password, u.email] }
    footers = ["#{@users.size}users", '', '']
    
    table = build_table(:id => 'test2', :headers => @headers, :values => values, :footers => footers)
    
    res = %|<table id="test2"><thead><tr><th>Name</th><th>Password</th><th>Email</th></tr></thead><tfoot><tr><td>3users</td><td></td><td></td></tr></tfoot><tr><td>gmosx</td><td>huh?</td><td>gm@nowhere.com</td></tr><tr><td>renos</td><td>nah</td><td>renos@nowhere.com</td></tr><tr><td>stella</td><td>hoh</td><td>stella@love.com</td></tr></table>|
    assert_equal res, table
  end
  
  def test_table_tbody
    values = []
    values << @users[0...1].collect { |u| [u.name, u.password, u.email] }
    values << @users[1..2].collect { |u| [u.name, u.password, u.email] }
    table = build_table(:id => 'test', :headers => @headers, :values => values)
    res = %|<table id="test"><thead><tr><th>Name</th><th>Password</th><th>Email</th></tr></thead><tbody><tr><td>gmosx</td><td>huh?</td><td>gm@nowhere.com</td></tr></tbody><tbody><tr><td>renos</td><td>nah</td><td>renos@nowhere.com</td></tr><tr><td>stella</td><td>hoh</td><td>stella@love.com</td></tr></tbody></table>|
    assert_equal res, table
  end
  
  def test_table_alternating_rows
    values = @users.collect { |u| [u.name, u.password, u.email] }
    table = build_table(:id => 'test', :headers => @headers, :values => values, :alternating_rows => true)
    res = %|<table id="test"><tr><th>Name</th><th>Password</th><th>Email</th></tr><tr class="row_odd"><td>gmosx</td><td>huh?</td><td>gm@nowhere.com</td></tr><tr class="row_even"><td>renos</td><td>nah</td><td>renos@nowhere.com</td></tr><tr class="row_odd"><td>stella</td><td>hoh</td><td>stella@love.com</td></tr></table>|
    assert_equal res, table
  end
  
  def test_table_alternating_rows_tbody
    values = []
    values << @users[0...1].collect { |u| [u.name, u.password, u.email] }
    values << @users[1..2].collect { |u| [u.name, u.password, u.email] }
    table = build_table(:id => 'test', :headers => @headers, :values => values, :alternating_rows => true)
    res = %|<table id="test"><thead><tr><th>Name</th><th>Password</th><th>Email</th></tr></thead><tbody><tr class="row_odd"><td>gmosx</td><td>huh?</td><td>gm@nowhere.com</td></tr></tbody><tbody><tr class="row_even"><td>renos</td><td>nah</td><td>renos@nowhere.com</td></tr><tr class="row_odd"><td>stella</td><td>hoh</td><td>stella@love.com</td></tr></tbody></table>|
    assert_equal res, table
  end
end


