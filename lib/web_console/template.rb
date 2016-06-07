module WebConsole
  # A facade that handles template rendering and composition.
  #
  # It introduces template helpers to ease the inclusion of scripts only on
  # Rails error pages.
  class Template
    # Lets you customize the default templates folder location.
    cattr_accessor :template_paths
    @@template_paths = [ File.expand_path('../templates', __FILE__) ]

    def initialize
      @mount_point = Middleware.mount_point
    end

    # Render a template (inferred from +template_paths+) as a plain string.
    def render(template)
      view = View.new(template_paths, instance_values)
      view.render(template: template, layout: false)
    end

    def render_with_session(template, session)
      @session = session
      render template
    end
  end
end
