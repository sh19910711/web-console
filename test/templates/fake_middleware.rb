require "action_view"

# Fake rack app to render templates
class FakeMiddleware
  def call(env)
    [200, header, [render(req_path(env))]]
  end

  # default header
  def header
    {"Content-Type" => "application/javascript"}
  end

  # extract target path from REQUEST_PATH
  def req_path(env)
    env["REQUEST_PATH"].match(req_path_regex)[1]
  end

  def view_path
    raise "view_path() is not implemented"
  end

  def render(template)
    view.render(template: template, layout: nil)
  end

  def view
    @view ||= create_view
  end

  def create_view
    lookup_context = ActionView::LookupContext.new(view_path)
    lookup_context.cache = false
    FakeView.new(lookup_context)
  end

  class FakeView < ActionView::Base
    def render_inlined_string(template)
      render(template: template, layout: "layouts/inlined_string")
    end
  end
end
