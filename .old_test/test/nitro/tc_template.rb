require File.join(File.dirname(__FILE__), 'CONFIG.rb')

require 'test/unit'

require 'nitro/template'

class TestTemplate < Test::Unit::TestCase # :nodoc: all
  include Nitro

  def test_all
    template = %q{
      Hello #{user}

      dont forget the following todo items:

      <?r for item in items ?>
        <li>#{item}</li>
      <?r end ?>
    }

    user = 'gmosx'
    items = %w{ nitro is really great }
    out = ''

    Nitro::Template.process(template, :out, binding)

    assert_match %r{\<li\>nitro\</li\>}, out
    assert_match %r{\<li\>really\</li\>}, out
    assert_match %r{Hello gmosx}, out

    # TODO: add test for static inclusion.

  end

  def test_interpolation
    template = %q[
      <% user1 = 'one' %>
      <%
        user2 = 'two'
      %>
      <?r user3 = 'three' ?>
      <?r
        user4 = 'four'
      ?>
      <ruby>user5 = 'five'</ruby>
      <ruby>
        user6 = 'six'
      </ruby>
      user1: #\user1\
      user2: #{user2}
      user3: #{ user3 }
      user4: #\ user4\
      user5: #\user5 \
      user6: #\ user6\
    ]

    out = ''
    Nitro::Template.process(template, :out, binding)

    {
      :user1 => 'one',
      :user2 => 'two',
      :user3 => 'three',
      :user4 => 'four',
      :user5 => 'five',
      :user6 => 'six'
    }.each do |key, val|
      assert_match "#{key}: #{val}", out
    end
  end
end
