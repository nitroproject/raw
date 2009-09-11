require File.join(File.dirname(__FILE__), 'CONFIG.rb')

require 'ostruct'
require 'test/unit'

require 'glue'
require 'glue/cache/file'
require 'nitro/session'

class TC_Session < Test::Unit::TestCase # :nodoc: all
  include Nitro

  # TODO: also check for :og !
  CACHES = [:memory, :file] #, :og]
  begin
    require 'glue/cache/memcached'
    Glue::MemCached.new
    CACHES << :memcached
  rescue Errno::ECONNREFUSED => ex # FIXME: Lookup Win32/Linux/BSD error
    Logger.warn "skipping memcached test: server not running"
    #Logger.warn ex.class # FIXME: remove when all error types listed above
  end


  def test_create_id
    sid = Session.new.session_id
    assert_not_equal sid, Session.new.session_id
    assert_not_equal sid, Session.new.session_id
    assert_not_equal sid, Session.new.session_id
    assert_not_equal sid, Session.new.session_id
    assert_not_equal sid, Session.new.session_id
  end

  def test_gc
    CACHES.each do |cache_type|
      Session.keepalive = 2
      
      if :file == cache_type
        path = File.join(File.dirname(__FILE__), '..', 'cache')
        Glue::FileCache.basedir = path
        FileUtils.rm_r path if File.exists? path
      end

      Session.setup(cache_type)

      if cache_type == :og
        Og.start(:store => :sqlite, :destroy => true)
#       Og.start(:store => :mysql, :name => 'test', :user => 'root', :destroy => true)
      end

      sessions = (1..2).collect do
        s = Session.new
        s.sync
        s
      end

      Session.cache.gc!
      sessions.each { |s| assert_not_nil(Session.cache[s.session_id]) }
      Session.cache.gc!
      sessions.each { |s| assert_not_nil(Session.cache[s.session_id]) }
      sleep(3)
      Session.cache.gc!    
      sessions.each { |s| assert_nil(Session.cache[s.session_id]) }
    end
  end
end
