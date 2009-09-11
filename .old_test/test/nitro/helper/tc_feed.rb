require File.join(File.dirname(__FILE__), '..', 'CONFIG.rb')

require 'test/unit'
require 'nitro/helper/feed'

class TC_FeedHelper < Test::Unit::TestCase # :nodoc: all
  include Nitro
  include FeedHelper
  
  Blog = Struct.new(:title, :body, :to_href) 
  Blog2 = Struct.new(:title, :body, :to_href, :update_time)
  # TODO: add more (all)
  FullBlown = Struct.new(:title, :body, :full_content, :to_href, :update_time, :create_time, :author)

  # RSS Testing
  def test_rss
    blogs = []
    blogs << Blog.new('Hello1', 'World1', 'uri1');
    blogs << Blog.new('Hello2', 'World2', 'uri2');
    blogs << Blog.new('Hello3', 'World3', 'uri3');
    blogs2 = []
    updated = Time.now
    blogs2 << Blog2.new('Hello1', 'World1', 'uri1', updated);
    blogs2 << Blog2.new('Hello2', 'World2', 'uri2', updated);
    blogs2 << Blog2.new('Hello3', 'World3', 'uri3', updated);

    # rss without version (0.9)
    rss = build_rss(blogs, :base => 'http://oxyliquit.de')

    assert_match %r{<link>http://oxyliquit.de/uri1</link>}, rss
    assert_match %r{<link>http://oxyliquit.de/uri2</link>}, rss
    
    # rss 0.9
    rss09 = build_rss(blogs, :version => "0.91", :link => 'http://oxyliquit.de')
    assert_match %r{<link>http://oxyliquit.de/uri1</link>}, rss09
    assert_match %r{<link>http://oxyliquit.de/uri2</link>}, rss09
    
    # rss 1.0
    rss10 = build_rss(blogs, :version => "1.0", :link => 'http://oxyliquit.de')
    assert_match %r{<link>http://oxyliquit.de/uri1</link>}, rss10
    assert_match %r{<link>http://oxyliquit.de/uri2</link>}, rss10
    
    # rss 2.0
    rss20 = build_rss(blogs2, :version => "2.0", :link => 'http://oxyliquit.de')
    assert_match %r{<link>http://oxyliquit.de/uri1</link>}, rss20
    assert_match %r{<link>http://oxyliquit.de/uri2</link>}, rss20
    
    # rss full blown
    rssfull = build_rss(blogs, :version => "0.9", :base => 'http://oxyliquit.de', :link => 'http://oxyliquit.de/feed', :title => "Oxyliquit feed", :language => 'en', :about => 'http://ox.li/about.rdf', :description => "Example feed of Oxyliquit", :search_title => "Oxyliquit search", :search_description => "Search through Oxyliqit", :search_input_name => "q", :search_form_action => "http://oxyliquit.de/search")
    assert_match %r{<link>http://oxyliquit.de/uri1</link>}, rssfull
    assert_match %r{<link>http://oxyliquit.de/uri2</link>}, rssfull
    # TODO: there should be some more
    
    # rss with full blown object
    update_time = Time.now
    create_time = Time.now - 360
    author = Hash.new
    author[:name] = "Bill"
    author[:link] = "http://bills.url"
    author[:email] = "bill@email.com"
    fullblownobject = []
    fullblownobject << FullBlown.new('Hello1', 'World1', 'Fullsize text with lots of words..', 'uri1', update_time, create_time, author)
    fullblownobject << FullBlown.new('Hello2', 'World2', ' text with lots of words..', 'uri2', update_time, create_time, author)
    rss_f_o = build_rss(fullblownobject, :version => "0.9", :base => 'http://oxyliquit.de', :link => 'http://oxyliquit.de/feed', :title => "Oxyliquit feed", :language => 'en', :about => 'http://ox.li/about.rdf', :description => "Example feed of Oxyliquit", :search_title => "Oxyliquit search", :search_description => "Search through Oxyliqit", :search_input_name => "q", :search_form_action => "http://oxyliquit.de/search")
    assert_match %r{<link>http://oxyliquit.de/uri1</link>}, rss_f_o
    assert_match %r{<link>http://oxyliquit.de/uri2</link>}, rss_f_o
    
    # rss with wrong version
    assert_raise(RuntimeError) do
      build_rss(blogs, :version => "0.5", :link => 'http://oxyliquit.de')
    end
    
  end # test_rss
  
  # Atom Testing
  def test_atom
    blogs = []
    updated = Time.now
    blogs << Blog2.new('Hello1', 'World1', 'uri1', updated);
    blogs << Blog2.new('Hello2', 'World2', 'uri2', updated);
    blogs << Blog2.new('Hello3', 'World3', 'uri3', updated);
        
    # atom small
    atom = build_atom(blogs, :base => 'http://oxyliquit.de')

    assert_match %r{<id>http://oxyliquit.de/uri1</id>}, atom
    assert_match %r{<id>http://oxyliquit.de/uri2</id>}, atom
    
    # atom big
    atom = build_atom(blogs, :title => "Oxyliquit Feed", :base => "http://oxyliquit.de", :link => "http://oxyliquit.de/atomfeed", :author_name => "Fabian Buch", :author_email => "fabian@fabian-buch.de", :author_link => "http://fabian-buch.de")
    
    assert_match %r{<id>http://oxyliquit.de/uri1</id>}, atom
    assert_match %r{<id>http://oxyliquit.de/uri2</id>}, atom
    assert_match %r{<title>Oxyliquit Feed</title>}, atom
    assert_match %r{<updated>\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(Z|[+-]\d{2}:\d{2})</updated>}, atom
    
    # atom with full blown object
    update_time = Time.now
    create_time = Time.now - 360
    author = Hash.new
    author[:name] = "Bill"
    author[:link] = "http://bills.url"
    author[:email] = "bill@email.com"
    fullblownobject = []
    fullblownobject << FullBlown.new('Hello1', 'World1', 'Fullsize text with lots of words..', 'uri1', update_time, create_time, author)
    fullblownobject << FullBlown.new('Hello2', 'World2', ' text with lots of words..', 'uri2', update_time, create_time, author)
    atom_f_o = build_atom(fullblownobject, :title => "Oxyliquit Feed", :base => "http://oxyliquit.de", :link => "http://oxyliquit.de/atomfeed", :author_name => "Fabian Buch", :author_email => "fabian@fabian-buch.de", :author_link => "http://fabian-buch.de")
    assert_match %r{<id>http://oxyliquit.de/uri1</id>}, atom_f_o
    assert_match %r{<id>http://oxyliquit.de/uri2</id>}, atom_f_o
    assert_match %r{<title>Oxyliquit Feed</title>}, atom_f_o
    assert_match %r{<summary>\w+</summary>}, atom_f_o
    assert_match %r{<updated>\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(Z|[+-]\d{2}:\d{2})</updated>}, atom_f_o
    assert_match %r{<published>\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(Z|[+-]\d{2}:\d{2})</published>}, atom_f_o
    assert_match %r{<author><name>Bill</name><email>bill@email.com</email><uri>http://bills.url</uri></author>}, atom_f_o
    
  end # test_atom
  
  # OPML Testing
  def test_opml
    
    opml = build_opml(
      {
      "http://oxyliquit.de/feed" => "rss",
      "http://oxyliquit.de/feed/questions" => "rss",
      "http://oxyliquit.de/feed/tips" => "rss",
      "http://oxyliquit.de/feed/tutorials" => "rss"
      },
      :title => "My feeds"
    )
    
    assert_match %r{<outline xmlUrl='http://oxyliquit.de/feed/tips' type='rss'/>}, opml
    
  end # test_opml

end
