require "raw/view/control/attribute"

module Raw

# Usage note:
#  don't forget to set form :method to :multipart
#  or :method to :post and :enctype to 'multipart/form-data'

class FileControl < AttributeControl
  setting :style, :default => 'width: 250px', :doc => 'The default style'

  def render
    %{
    #{emit_label}
    <input type="file" id="#{control_id}" name="#{@attribute}" value="#{@object.send(@attribute)}"#{emit_style}#{emit_disabled} />
    }
  end
end

end
