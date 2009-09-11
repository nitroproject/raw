require "facets/settings"

module Raw::Mixin

# Displays a collection of entitities in multiple pages.
#
# === Design
#
# This pager is carefully designed for scaleability. It stores
# only the items for one page. The key parameter is needed,
# multiple pagers can coexist in a single page. The pager
# leverages the SQL LIMIT option to optimize database
# interaction.

class Pager

  # Items per page.

  setting :per_page, :default => 10, :doc => "Items per page"

  # The request key.

  setting :key, :default => "_page", :doc => "The request key"

  # The current page.

  attr_accessor :page

  # Items per page.

  attr_accessor :per_page

  # The total number of pages.

  attr_accessor :page_count

  # Total count of items.

  attr_accessor :total_count

  def initialize(request, per_page, total_count, key = Pager.key)
    raise 'per_page should be > 0' unless per_page > 0

    @request, @key = request, key
    @page = (request.query[key] || 1).to_i
    @per_page = per_page
    set_count(total_count)
    @start_idx = (@page - 1) * per_page
  end

  def set_count(total_count)
    @total_count = total_count
    @page_count = (@total_count.to_f / @per_page).ceil
  end

  # Return the first page index.
  
  def first_page
    return 1
  end
  
  # Is the first page displayed?
  
  def first_page?
    @page == 1
  end
  
  # Return the last page index.
  
  def last_page
    return @page_count
  end
  
  # Is the last page displayed?
  
  def last_page?
    @page == @page_count
  end
  
  # Return the index of the previous page.
  
  def previous_page
    return [@page - 1, 1].max()
  end

  # Return the index of the next page.
  
  def next_page
    return [@page + 1, @page_count].min()
  end

  # A set of helpers to create links to common pages.
  
  for target in [:first, :last, :previous, :next]
    eval %{
      def link_#{target}_page
        target_uri(#{target}_page)
      end
      alias_method :#{target}_page_uri, :link_#{target}_page
      alias_method :#{target}_page_href, :link_#{target}_page
    }
  end
  
  # Iterator
  
  def each(&block)
    @page_items.each(&block)
  end
  
  # Iterator
  # Returns 1-based index.
  
  def each_with_index
    idx = @start_idx
    for item in @page_items
      yield(idx + 1, item)
      idx += 1
    end
  end
  
  # Is the pager empty, ie has one page only?
  
  def empty?
    return @page_count < 1
  end
  
  # The items count.
  
  def size
    return @total_count
  end
  
  # Returns the range of the current page.
  
  def page_range
    s = @idx
    e = [@idx + @items_per_page - 1, all_total_count].min
    
    return [s, e]
  end
  
  # Override if needed.
  
  def nav_range
    # effective range = 10 pages.
    s = [@page - 5, 1].max()
    e = [@page + 9, @page_count].min()
    
    d = 9 - (e - s)
    e += d if d < 0
    
    return (s..e)
  end

  # To be used with Og queries.
    
  def limit
    if @start_idx > 0
      { :limit => @per_page, :offset => @start_idx }
    else
      { :limit => @per_page }
    end
  end

  def offset
    @start_idx
  end

  # Create an appropriate SQL limit clause.
  # Returns postgres/mysql compatible limit.
  
  def to_sql
    if @start_idx > 0
      return "LIMIT #{@per_page} OFFSET #{@start_idx}"
    else
      # gmosx: perhaps this is optimized ? naaaaaah...
      return "LIMIT #{@per_page}"
    end
  end

  # Override this method in your application if needed.
  #--
  # TODO: better markup.
  #++
  
  def navigation
    nav = ""
    
    unless first_page?
      nav << %{
        <div class="first"><a href="#{first_page_href}">First</a></div>
        <div class="previous"><a href="#{previous_page_href}">Previous</a></div>
      }
    end
    
    unless last_page?
      nav << %{
        <div class="last"><a href="#{last_page_href}">Last</a></div>
        <div class="next"><a href="#{next_page_href}">Next</a></div>
      }
    end

    nav << %{<ul>}
    
    for i in nav_range()
      if i == @page
        nav << %{
          <li class="active">#{i}</li>
        }
      else
        nav << %{
          <li><a href="#{target_uri(i)}">#{i}</a></li>
        }
      end
    end
    
    nav << %{</ul>}
    
    return nav
  end
  alias_method :links, :navigation

  def navigation_needed?
    @page_count > 1
  end
  alias_method :navigation?, :navigation_needed?

private

  # Generate the target URI.
   
  def target_uri(page)
    uri = @request.uri.to_s

    if uri =~ /[?;]#{@key}=(\d*)/
      return uri.gsub(/([?;]#{@key}=)\d*/) { |m| "#$1#{page}" }
    elsif uri =~ /\?/
      return "#{uri};#{@key}=#{page}"
    else
      return "#{uri}?#{@key}=#{page}"
    end
  end

end

# Pager related helper methods.

module PagerHelper

private

  # Helper method that generates a collection of items and the
  # associated pager object.
  #
  # === Example
  #
  # entries, pager = paginate(Article, :condition => 'title LIKE %Ab%', :per_page => 10)
  #
  # or
  #
  # items = [ 'item1', 'item2', ... ]
  # entries, pager = paginate(items, :per_page => 10)
  #
  # or
  #
  # entries, pager = paginate(article.comments, :per_page => 10)
  #
  # <ul>
  # <?r for entry in entries ?>
  #    <li>#{entry.to_link}</li>
  # <?r end ?>
  # </ul>
  # #{pager.links}

  def paginate(items, options = {})
    per_page = options.delete(:per_page) || options[:limit] || Pager.per_page
    pager_key = options.delete(:pager_key) || Pager.key

    if items.is_a? Array
      items = items.dup
      pager = Pager.new(request, per_page, items.size, pager_key)
      items = items.slice(pager.offset, pager.per_page) || []
      return items, pager
    elsif defined? Og
      if items.is_a? Og::Collection
        collection = items
        pager = Pager.new(request, per_page, collection.count, pager_key)
        options.update(pager.limit)
        items = collection.reload(options)
        return items, pager
      elsif items.ancestors.include? Og::Model
        klass = items
        pager = Pager.new(request, per_page, klass.count(options), pager_key)
        options.update(pager.limit)
        items = klass.all(options)
        return items, pager
      end
    else
      raise ArgumentError, "#{items.inspect} is not an acceptable container for paginate."
    end
  end

end

end
