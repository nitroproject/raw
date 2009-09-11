require "uri"
require "blow/atom"
require "facets/settings"
require "raw/util/markup"

module Raw

# ATOM (GData) loader / dumper

module ATOM
  extend Raw::Markup
  class << self
    public :markup  # TODO fix Raw::Markup
  end

  # The content type.

  setting :content_type, :default => "text/html", :doc => "The content type"

  # Return an ATOM string corresponding to the Ruby object
  # +obj+.

  def self.dump(obj_or_enumerable, options = {})
    if obj_or_enumerable.is_a? Enumerable
      dump_enumerable(obj_or_enumerable, options).to_xml
    else
      dump_object(obj_or_enumerable, options).to_xml
    end
  end

  #def self.load(atom)
  #end

  private

  #

  def self.dump_object(obj, options={})

    # figure out author information
    if obj.respond_to?(:author) && obj.author
      has_author = true
      if obj.author.is_a? String
        author_name = obj.author
        author_uri  = nil
      else
        author_name = obj.author.name
        author_uri  = obj.author.uri if obj.author.respond_to?(:uri)
      end
    else
      has_author = false
    end

    #Blow::Atom::Entry.new do
    lambda do
      id "#{Context.current.host_uri}#{obj.to_href}"

      title obj.title

      link :rel=>"alternate", :type => "text/html", :href=> "#{Context.current.host_uri}#{obj.to_href}"

      author do
        name author_name
        uri author_uri if author_uri
      end if has_author

      summary ATOM::markup(obj.summary) if obj.respond_to? :summary

      # TODO: The Atom feed should do the HTML escape.
      if ATOM.content_type == "text/html"
        #content CGI.escapeHTML(ATOM::markup(obj.body)), :type=>"html"
        content ATOM::markup(obj.body), :type=>"html"
      else
        content obj.body, :type=>"text"
      end

      # TODO: The Atom feed should format the time correctly.
      updated "#{obj.update_time.iso8601}" if (obj.respond_to? :update_time) and obj.update_time

      # TODO: The Atom feed should format the time correctly.
      published "#{obj.create_time.iso8601}" if obj.respond_to? :create_time and obj.create_time
    end
  end

  #

  def self.dump_enumerable(collection, options={})
    openSearch = { "xmlns:openSearch" => "http://a9.com/-/spec/opensearchrss/1.0/" }

    feed = Blow::Atom.feed(openSearch) do

      id URI.parse(options[:id]).normalize

      title (options[:title] || "Syndication"), :type => "text"

      updated collection.map{|e|e.update_time}.max.iso8601

      link :rel=>"self", :href=>"#{options[:link]}" if options[:link]

      generator "Nitro", :uri=>"http://www.nitroproject.org", :version=>"#{Raw::Version}"

      # More stuff:
      #
      # category
      # contributor
      # icon
      # logo
      # rights
      # subtitle
    end

    for obj in collection
      # next unless obj.respond_to?(:to_href) and obj.respond_to?(:title)
      feed.entry(&dump_object(obj))
    end

    feed
  end

end

end


class Object

  # Dump object as ATOM.

  def to_atom(*args)
    Raw::ATOM.dump(self, *args)
  end

end

=begin demo
  module Raw
    Version = "0.50"
    require "facets/nullclass"
    Context = NullClass.new
  end

  obj = Object.new
  def obj.update_time; Time.now; end
  def obj.author; "Tommy"; end
  def obj.title; "This is it"; end
  def obj.to_href; "http://sick.html"; end
  def obj.body; "Try it on!"; end

  collection = [ obj ]

  options = {}
  options[:id] = "1"
  options[:title] = "HELLO"
  options[:link] = "http://blah.xml"

  puts collection.to_atom(options)
=end
