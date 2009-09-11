require "raw/view/control/attribute"

module Raw

class NoneControl < AttributeControl
  def render
    %{
    #{emit_label}<br />
    <div class="none_ctl_container">
      No control available
    </div>
    }
  end
end

end
