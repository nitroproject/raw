module Raw

# A helper mixin for programmatically building Navigation Menus
# through easy to style XHTML.
# The code resulting from these methods is in line with that found in most examples at
# listamatic, thus you can use prebuilt CSS and Javascript to create horizontal or vertical menus.
# Basically it generates something like
#  <div id="navcontainer">
#   <ul id="navlist">
#    <li id="active"> <a href="/foo" id="current"> Current Page </a></li>
#    <li> <a href="/bar"> Other page </a> </li>
#   </ul>
#   </div>
#
# This helper takes care of setting of putting the special CSS
# identifiers for the current controller automatically.
# You could override menuitem_active_on(path)
# to change the behaviour that choose the active item,
# for example  to keep the item "Wiki" active both for
# /wiki/pageone and /wiki/pagetwo
#
# Example of horizontal bar at listamatic:
# http://css.maxdesign.com.au/listamatic/horizontal26.htm
# Vertical example
# http://css.maxdesign.com.au/listamatic/vertical09.htm
#
# NOTE: No tests were made with Publishable objects which are not
# subclass of Raw::Controller, but it _should_ work.

module NavigationHelper

TEMPLATE=<<Eof
<div id="navcontainer">
 <ul id="navlist">
LIST
 </ul>
</div>
Eof

  # Takes a list of controllers and builds a menu
  # using #mount_path as the uri and the controller name as text.
  # An eventual "Controller" suffix will be stripped, so i.e. for controllers
  # named +HomeController+, +Pages+, +FeedCtl+ it will use
  # +Home+, +Page+, +FeedCtl+.
  #
  # For more finegrained control you can pass a block to this function, each
  # controller will be passed to it and the result will be used as the text
  # for the menu item.
  #
  #
  # Otherwise you can specify pairs of path/text using #navigation_for_hash

  def menu_for(*controllers) #:yields:
    hash= {}
    controllers.each do |c|
      hash[c.mount_path] = block_given? ? yield(c) : c.name.gsub(/Controller/,'')
    end
    menu_from_hash(hash)
  end

  # The argument must be an hash of pairs {'path'=>'text for menu item'},
  # no control will be applied on these values, they will be used directly.
  # You can use the method like
  #  navigation_for_hash '/foo/bar'=>'Page One', '/foo/baz'=>'Page Two'
  #
  # The method takes care of setting the CSS values as expected.
  #
  # To avoid specifying everything the method #navigation_menu can be used.

  def menu_from_hash(hash)
    list=hash.map do |path,name|
      if menuitem_active_on?(path)
        %{<li id="active"><a href="#{path}" id="current"> #{name} </a></li>}
      else
        %{<li><a href="#{path}"> #{name} </a></li>}
      end
    end.join("\n")
    TEMPLATE.gsub("LIST",list)
  end

  def menuitem_active_on?(path)
    path == request.path
  end

end

end
