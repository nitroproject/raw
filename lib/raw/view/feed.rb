require 'rss/maker'
require 'rexml/document'
require 'time'
require 'uri'

require 'facets/string/first_char'

require 'raw/util/markup'

module Raw

# A helper that provides Feed related methods.
#
# To include this helper into your controller,
# add the following at the beginning of your controller:
#
#  helper :feed
#
# Then define actions that set an appropriate content_type and use build_(rss|atom|opml)
# to generate your desired feed. See below for details.
#
# == RSS 0.91, 1.0 and 2.0
#
#  response.content_type = "application/rss+xml"
#  build_rss(og_objects,
#    :version => "0.9",
#    :base => context.host_uri, # + object.to_href results in an item-link
#    :link => context.host_uri+"/feed", # link to this feed
#    :title => "Feed Title",
#    :description => "What this feed is about",
#    :search_title => "Search Form Here",
#    :search_description => "Search description",
#    :search_input_name => "search_field",
#    :search_form_action => "http://uri/to/search_action"
#  )
#
# For RSS 1.0 or RSS 2.0 just change :version (defaults to '0.91'),
# possible :version options are "0.9", "0.91", "1.0" and "2.0"
#
# * for RSS 0.9 :language is required (or defaults to 'en')
# * for all RSS versions :title, :link and/or :base, :description are required
#
# <b>individual objects have to respond to at least:</b>
#
# * 1.0/0.9/2.0 require @title
# * 1.0/0.9 require @to_href
# * 2.0 requires @body
#
# if it doesn't, no item is created
#
# * @update_time, @create_time or @date is used for item.date
# * so if Og's "is Timestamped" is being used, it'll be @update_time
# * @author.name can optionally be used for item.author
#
# == Atom 1.0
#
#   response.content_type = "application/atom+xml"
#   build_atom(og_objects,
#     :title => "Feed Title",
#     :base => context.host_uri, # + object.to_href results in an item-link
#     :link => context.host_uri+"/atomfeed",
#     :id => "your_unique_id",  # :base is being used unless :id specified (:base is recommended)
#     :author_name => "Takeo",
#     :author_email => "email@example.com",
#     :author_link => "http://uri.to/authors/home",
#   )
#
# <b>individual objects have to respond to at least:</b>
#
# * @title
# * @to_href
# * @update_time/@create_time/@date (at least one of them)
#
# if it doesn't, no entry is created
#
# optional:
#
# * @body (taken as summary (256 chars))
# * @full_content     # can countain html
# * use Og's "is Timestamped", so both @update_time and @create_time can be used
# * @author.name
# * @author.link
# * @author.email    # be careful, you don't want to publish your users email address to spammers
#
#
# == OPML 1.0 feed lists
#
# Fabian: Eew, who invented OPML? Who needs it? Implementing it in a very rough way anyway though.
# takes a Hash of Feeds and optional options
#
#   response.content_type = "application/opml+xml"
#   build_opml(
#     {
#     "http://oxyliquit.de/feed" => "rss",
#     "http://oxyliquit.de/feed/questions" => "rss",
#     "http://oxyliquit.de/feed/tips" => "rss",
#     "http://oxyliquit.de/feed/tutorials" => "rss"
#     },
#     :title => "My feeds"
#   )

module FeedHelper
  is Markup

  # RSS 0.91, 1.0, 2.0 feeds.

  def build_rss(objects, options = {})

    # default options
    options = {
      :title => 'Syndication',
      :description => 'Syndication',
      :version => '0.9',
      :language => 'en',  # required by 0.9
    }.update(options)

    raise "Option ':version' contains a wrong version!" unless %w(0.9 0.91 1.0 2.0).include?(options[:version])

    options[:base] ||= options[:link]
    raise "Option ':base' cannot be omitted!" unless options[:base]

    # build rss
    rss = RSS::Maker.make(options[:version]) do |maker|
      maker.channel.title = options[:title]
      maker.channel.description = options[:description]
      if options[:link]
        maker.channel.link = options[:link]
      else
        maker.channel.link = options[:base] #FIXME: not sure
      end
      case options[:version]
        when '0.9', '0.91'
          maker.channel.language = options[:language]
        when '1.0'
          if options[:link]
            maker.channel.about = options[:link]
          else
            raise "Option ':link' is required for RSS 1.0"
          end
      end
      maker.channel.generator = "Nitro #{Nitro::Version}"

      maker.items.do_sort = true

      # items for each object
      # * 1.0/0.9/2.0 require @title
      # * 1.0/0.9 require @link
      # * 2.0 requires @description
      objects.each do |o|

        # new Item
        item = maker.items.new_item

        # Link
        item.link = "#{options[:base]}#{fhref o}" if o.respond_to?(:to_href)
        item.guid.content = "#{options[:base]}#{fhref o}" if options[:version] == '2.0' && o.respond_to?(:to_href)

        # Title
        item.title = o.title if o.respond_to?(:title)

        # Description
        if o.respond_to? :body and body = o.body
          #TODO: think about whether markup should always be done
          # and whether 256 chars should be a fixed limit
          #item.description = markup(body.first_char(256))
          # markup disabled, feedvalidator.org says "description should not contain HTML"
          # so removing everything that looks like a tag
          item.description = body.first_char(256).gsub!(/<[^>]+>/, ' ')
        end

        # Date  (item.date asks for a Time object, so don't .to_s !)
        if o.respond_to?(:update_time)
          item.date = o.update_time
        elsif o.respond_to?(:create_time)
          item.date = o.create_time
        elsif o.respond_to?(:date)
          item.date = o.date
        end

        # Author. Use .to_s to be more flexible.

        if o.respond_to?(:author)
          if o.author.respond_to?(:name)
            item.author = o.author.name
          else
            item.author = o.author.to_s
          end
        end

      end if objects.size > 0 # objects/items

      # search form
      maker.textinput.title = options[:search_title] if options[:search_title]
      maker.textinput.description = options[:search_description] if options[:search_description]
      maker.textinput.name = options[:search_input_name] if options[:search_input_name]
      maker.textinput.link = options[:search_form_action] if options[:search_form_action]
    end

    return rss.to_s
  end
  alias_method :rss, :build_rss


  # Atom 1.0 feeds.

  def build_atom(objects, options = {})

    # default options
    options = {
      :title => 'Syndication',
    }.update(options)

    raise "first param must be a collection of objects!" unless objects.respond_to?(:to_ary)
    raise "your object(s) have to respond to :update_time, :create_time or :date" unless objects[0].respond_to?(:update_time) or objects[0].respond_to?(:create_time) or objects[0].respond_to?(:date)
    raise "Option ':base' cannot be omitted!" unless options[:base]

    # new XML Document for Atom
    atom = REXML::Document.new
    atom << REXML::XMLDecl.new("1.0", "utf-8")

      # Root element <feed />
      feed = REXML::Element.new("feed").add_namespace("http://www.w3.org/2005/Atom")

        # Required feed elements

        # id: Identifies the feed using a universally unique and permanent URI.
        iduri = URI.parse(options[:id] || options[:base]).normalize.to_s
        id = REXML::Element.new("id").add_text(iduri)
        feed << id

        # title: Contains a human readable title for the feed.
        title = REXML::Element.new("title").add_text(options[:title])
        feed << title

        # updated: Indicates the last time the feed was modified in a significant way.
        latest = Time.at(0) # a while back
        objects.each do |o|
          if o.respond_to?(:update_time)
            latest = o.update_time if o.update_time > latest
          elsif o.respond_to?(:create_time)
            latest = o.create_time if o.create_time > latest
          elsif o.respond_to?(:date)
            latest = o.date if o.date > latest
          end
        end
        updated = REXML::Element.new("updated").add_text(latest.iso8601)
        feed << updated

        # Recommended feed elements

        # link: A feed should contain a link back to the feed itself.
        if options[:link]
          link = REXML::Element.new("link")
          link.add_attributes({ "rel" => "self", "href" => options[:link] })
          feed << link
        end

        # author: Names one author of the feed.
        if options[:author_name]  # name is required for author
          author = REXML::Element.new("author")
          author_name = REXML::Element.new("name").add_text(options[:author_name])
          author << author_name
          if options[:author_email]
            author_email = REXML::Element.new("email").add_text(options[:author_email])
            author << author_email
          end
          if options[:author_link]
            author_link = REXML::Element.new("uri").add_text(options[:author_link])
            author << author_link
          end
          feed << author
        end

        # Optional feed elements

        # category:
        # contributor:
        # generator: Identifies the software used to generate the feed.
        generator = REXML::Element.new("generator")
        generator.add_attributes({ "uri" => "http://www.nitroproject.org", "version" => Nitro::Version })
        generator.add_text("Nitro")
        feed << generator
        # icon
        # logo
        # rights
        # subtitle

        # Entries
        objects.each do |o|

          # new Entry (called "item" in RSS)
          unless o.respond_to?(:to_href) and o.respond_to?(:title)
            next
          end
          entry = REXML::Element.new("entry")

          # Required entry elements

            # id
            if o.respond_to?(:to_href)
              id = REXML::Element.new("id").add_text("#{options[:base]}#{fhref o}")
              entry << id
            end

            # title
            if o.respond_to?(:title)
              title = REXML::Element.new("title").add_text(o.title)
              entry << title
            end

            # updated
            updated = Time.at(0) # a while back
            if o.respond_to?(:update_time)
              updated = o.update_time
            elsif o.respond_to?(:create_time)
              updated = o.create_time
            elsif o.respond_to?(:date)
              updated = o.date
            end
            entry << REXML::Element.new("updated").add_text(updated.iso8601)

          # Recommended entry elements

            # author
            if o.respond_to?(:author)

              if o.author.kind_of?(Hash)
                oauthor = OpenStruct.new(o.author)
              else
                oauthor = o.author
              end

              author = REXML::Element.new("author")
              author_name = REXML::Element.new("name").add_text(oauthor.name)
              author << author_name
              if oauthor.email
                author_email = REXML::Element.new("email").add_text(oauthor.email)
                author << author_email
              end
              if oauthor.link
                author_link = REXML::Element.new("uri").add_text(oauthor.link)
                author << author_link
              end
              entry << author
            end

            # summary

            if o.respond_to?(:body)
              summary = REXML::Element.new("summary")
              #TODO: think about whether 256 chars should be a fixed limit
              summary.add_text(o.body.first_char(256).gsub(/<[^>]+>/, ' '))
              entry << summary
            end

            # content
            # may have the type text, html or xhtml

            if o.respond_to?(:full_content)
              content = REXML::Element.new("content")
              link.add_attribute("type", "html")
              content.add_text(o.full_content)
              entry << content
            end

            # link: An entry must contain an alternate link if there is no content element.

            if o.respond_to?(:to_href)
              link = REXML::Element.new("link")
              link.add_attributes({ "rel" => "alternate", "href" => "#{options[:base]}#{fhref o}" })
              entry << link
            end

            # Optional entry elements

            # category
            # could be used for Tags maybe?
            # contributor
            # published

            if o.respond_to?(:create_time)
              published = REXML::Element.new("published")
              published.add_text(o.create_time.iso8601)
              entry << published
            end

            # source
            # rights

          # don't forget to add the entry to the feed
          feed << entry

        end if objects.size > 0 # objects/entries

    atom << feed

    return atom.to_s
  end
  alias_method :atom, :build_atom

  # OPML 1.0 feed lists
  # Fabian: eww, who invented OPML? Who needs it? Implementing
  # it in a very rough way anyway though. Takes a Hash of
  # Feeds and optional options.

  def build_opml(feedhash, options = {})

    # new XML Document for OPML
    opml = REXML::Document.new
    opml << REXML::XMLDecl.new("1.0", "utf-8")

    # Root element <opml />
    opml = REXML::Element.new("opml")
    opml.add_attribute("version", "1.0")

    # head
    head = REXML::Element.new("head")
      # title
      if options[:title]
        title = REXML::Element.new("title").add_text(options[:title])
        head << title
      end
      # dateCreated
      # dateModified
      # ownerName
      # ownerEmail
    opml << head

    # body
    body = REXML::Element.new("body")
      feedhash.each do |uri, type|
        outline = REXML::Element.new("outline")
        outline.add_attributes({ "type" => type, "xmlUrl" => uri })
        body << outline
      end
    opml << body

    return opml.to_s
  end
  alias_method :opml, :build_opml


  # Helper

  def fhref(obj)
    "/#{obj.to_href}".squeeze('/')
  end

end

end
