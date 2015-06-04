require_relative "fake_middleware"

$current_dir = File.dirname(__FILE__)

# node modules (e.g. "/node_modules/mocha/mocha.js")
map "/node_modules" do
  node_modules = File.expand_path($current_dir + "/../../node_modules")
  unless Dir.exists?(node_modules)
    raise "missing the node_modules directory"
    exit 1
  end
  run Rack::Directory.new(node_modules)
end

# test runners (html)
map "/html" do
  class TestRunners < FakeMiddleware
    def req_path_regex
      %r{^/html/(.*)}
    end

    def header
      {"Content-Type" => "text/html"}
    end

    def view_path
      $current_dir + "/html"
    end
  end

  run TestRunners.new
end

# specs (js)
map "/spec" do
  class Specs < FakeMiddleware
    def req_path_regex
      %r{^/spec/(.*)}
    end

    def view_path
      $current_dir + "/spec"
    end
  end

  run Specs.new
end

# templates (js)
map "/templates" do
  class Templates < FakeMiddleware
    def req_path_regex
      %r{^/templates/(.*)}
    end

    def view_path
      $current_dir + "/../../lib/web_console/templates"
    end
  end

  run Templates.new 
end

