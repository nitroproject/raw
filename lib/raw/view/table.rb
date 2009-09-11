require "facets/settings"

require "blow/uri"

module Raw::Mixin

# The TableBuilder is a helper class that automates the creation
# of tables from collections of objects. The resulting html
# can be styled using css.
#
# === Example
#
# <?r
# users = User.all.map { |u| [u.name, u.first_name, u.last_name, u.email] }
# headers = ['Username', 'First name', 'Last name', 'Email']
# ?>
#
# <div class="custom-table-class">
#   #{table :values => users, :headers => header}
# </div>
#
#
# === Extended Example
#
#  <?r
#  users = User.all.map { |u| [u.name, u.first_name, u.last_name, u.email] }
#  headers = ['Username', 'First name', 'Last name', 'Email']
#  order_opts = { :right => true, # right align the order controls
#       :values => [nil, 'first_name', 'last_name'], # column names from DB
#       :asc_pic => "/images/asc.png",
#       :desc_pic => "/images/desc.png" }
#  ?>
#
#  <div class="custom-table-class">
#    #{table :values => users, :headers => header,
#     :order => order_opts, :alternating_rows => true }
#  </div>
#
#--
# TODO: legend, verbose... ?
# TODO, gmosx: Remove crappy, bloatware additions.
#++

module TableHelper

  # The order by key.

  setting :order_by_key, :default => '_order_by', :doc => 'The order key'

  # The order by key.

  setting :order_direction_key, :default => '_order_direction', :doc => 'The order direction key'

  # [+options+]
  #    A hash of options.
  #
  # :id = id of the component.
  # :class = class of the component
  # :headers = an array of the header values
  # :values = an array of arrays.
  # :order = options hash (:left, :right, :asc_pic, :desc_pic, :values)
  # :alternating_rows = alternating rows, use css to color row_even / row_odd
  # :footers = an array of tfooter values

  def table(options)
    str = '<table'
    str << %| id="#{options[:id]}"| if options[:id]
    str << %| class="#{options[:class]}"| if options[:class]
    str << '>'

    str << table_rows(options)

    str << '</table>'
  end
  alias_method :build_table, :table

  # [+options+]
  #    A hash of options.
  #
  # :headers = an array of the header values
  # :values = an array of arrays.
  # :order = options hash (:left, :right, :asc_pic, :desc_pic, :values)
  # :alternating_rows = alternating rows, use css to color row_even / row_odd
  # :footers = an array of tfooter values

  def table_rows(options)
    # also accept :items, :rows
    options[:values] = options[:values] || options[:items] || options[:rows]

    str = ''
    str << table_header(options) if options[:headers]
    str << table_footer(options) if options[:footers]

    items = options[:values]

    row_state = 'odd' if options[:alternating_rows]

    # when items is an array of arrays of arrays (meaning, several
    # arrays deviding the table into several table parts (tbodys))

    if create_tbody?(options)
      for body in items
        str << '<tbody>'

        for row in body
          str << '<tr'

          if options[:alternating_rows]
            str << %| class="row_#{row_state}"|
            row_state = (row_state == "odd" ? "even" : "odd")
          end

          str << '>'

          for value in row
            str << %|<td>#{value}</td>|
          end

          str << '</tr>'
        end

        str << '</tbody>'
      end
    else
      for row in items
        str << '<tr'

        if options[:alternating_rows]
          str << %| class="row_#{row_state}"|
          row_state = (row_state == "odd" ? "even" : "odd")
        end

        str << '>'

        for value in row
          str << %|<td>#{value}</td>|
        end

        str << '</tr>'
      end
    end

    return str
  end

  private

  # [+options+]
  #    A hash of options.
  #
  # :id = id of the component.
  # :headers = an array of the header values
  # :values = an array of arrays.
  # :order = options hash (:left, :right, :asc_pic, :desc_pic, :values)
  # :alternating_rows = alternating rows, use css to color row_even / row_odd
  # :footers = an array of tfooter values

  def table_header(options)
    str = ''
    str << '<thead>' if create_tbody?(options) || options[:footers]
    str << '<tr>'

    options[:headers].each_with_index do |header, index|
      if (options[:order] && options[:order][:values] &&
                            options[:order][:values][index])
        order_by = options[:order][:values][index]

        asc_val = if options[:order][:asc_pic]
           %|<img src="#{options[:order][:asc_pic]}" alt="asc" />|
        else
          '^'
        end
        desc_val = if options[:order][:desc_pic]
           %|<img src="#{options[:order][:desc_pic]}" alt="desc" />|
        else
          'v'
        end

        order_asc = "<a href='#{target_uri(order_by, 'ASC')}'>#{asc_val}</a>"
        order_desc = "<a href='#{target_uri(order_by, 'DESC')}'>#{desc_val}</a>"

        str << '<th><table width="100%" cellspacing="0" cellpadding="0"><tr>'

        if options[:order][:left] || !options[:order][:right]
          str << "<th>#{order_asc}<br />#{order_desc}</th>"
        end

        str << %|<th>#{header}</th>|

        if options[:order][:right]
          str << "<th>#{order_asc}<br />#{order_desc}</th>"
        end

        str << '</tr></table></th>'
      else
        str << %|<th>#{header}</th>|
      end
    end

    str << '</tr>'
    str << '</thead>' if create_tbody?(options) || options[:footers]

    return str
  end

  # [+options+]
  #    A hash of options.
  #
  # :id = id of the component.
  # :headers = an array of the header values
  # :values = an array of arrays.
  # :order = options hash (:left, :right, :asc_pic, :desc_pic, :values)
  # :alternating_rows = alternating rows, use css to color row_even / row_odd
  # :footers = an array of tfooter values

  def table_footer(options)
    str = '<tfoot><tr>'

    for footer in options[:footers]
      str << %|<td>#{footer}</td>|
    end

    str << '</tr></tfoot>'

    return str
  end

  # Generate the target URI.

  def target_uri(order_by, direction)
    params = { TableHelper.order_by_key => order_by,
              TableHelper.order_direction_key => direction }

    return Blow::UriUtils.update_query_string(request.uri.to_s, params)
  end

  def create_tbody?(options)
    options[:values][0][0].respond_to?(:to_ary) rescue false
  end

end

end
