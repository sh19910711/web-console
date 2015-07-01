require 'active_support/core_ext/string/strip'

module WebConsole
  class Middleware
    TEMPLATES_PATH = File.expand_path('../templates', __FILE__)

    DEFAULT_OPTIONS = {
      # TODO: they can be unified?
      update_re: %r{/repl_sessions/(?<id>.+?)\z},
      binding_change_re: %r{/repl_sessions/(?<id>.+?)/trace\z},
      context_info_re: %r{/repl_sessions/(?<id>.+?)/context\z},
    }

    UNAVAILABLE_SESSION_MESSAGE = <<-END.strip_heredoc
      Session %{id} is is no longer available in memory.

      If you happen to run on a multi-process server (like Unicorn) the process
      this request hit doesn't store %{id} in memory.
    END

    cattr_accessor :whiny_requests
    @@whiny_requests = true

    def initialize(app, options = {})
      @app     = app
      @options = DEFAULT_OPTIONS.merge(options)
    end

    def call(env)
      request = create_regular_or_whiny_request(env)
      return @app.call(env) unless request.from_whitelited_ip?

      if request.xhr?
        unless request.acceptable?
          return respond_with_unacceptable_request
        end
      end

      if id = id_for_repl_session_update(request)
        return update_repl_session(id, request.params)
      elsif id = id_for_repl_session_stack_frame_change(request)
        return change_stack_trace(id, request.params)
      elsif id = id_for_repl_session_context_info(request)
        return get_context_info(id, request.params)
      end

      status, headers, body = @app.call(env)

      if exception = env['web_console.exception']
        session = Session.from_exception(exception)
      elsif binding = env['web_console.binding']
        session = Session.from_binding(binding)
      end

      if session && request.acceptable_content_type?
        headers["X-Web-Console-Session-Id"] = session.id
        response = Rack::Response.new(body, status, headers)
        template = Template.new(env, session)

        response.write(template.render('index'))
        response.finish
      else
        [ status, headers, body ]
      end
    end

    private

      def create_regular_or_whiny_request(env)
        request = Request.new(env)
        whiny_requests ? WhinyRequest.new(request) : request
      end

      def update_re
        @options[:update_re]
      end

      def binding_change_re
        @options[:binding_change_re]
      end

      def context_info_re
        @options[:context_info_re]
      end

      def id_for_repl_session_update(request)
        if request.xhr? && request.put?
          update_re.match(request.path_info) { |m| m[:id] }
        end
      end

      def id_for_repl_session_stack_frame_change(request)
        if request.xhr? && request.post?
          binding_change_re.match(request.path_info) { |m| m[:id] }
        end
      end

      def id_for_repl_session_context_info(request)
        if request.xhr? && request.get?
          context_info_re.match(request.path_info) { |m| m[:id] }
        end
      end

      def json_response(id)
        unless session = Session.find(id)
          return respond_with_unavailable_session(id)
        end

        status  = 200
        headers = { 'Content-Type' => 'application/json; charset = utf-8' }
        body    = yield(session).to_json

        Rack::Response.new(body, status, headers).finish
      end

      def update_repl_session(id, params)
        json_response(id) do |session|
          { output: session.eval(params[:input]) }
        end
      end

      def change_stack_trace(id, params)
        json_response(id) do |session|
          session.switch_binding_to(params[:frame_id])
          { ok: true }
        end
      end

      def get_context_info(id, params)
        json_response(id) do |session|
          session.context
        end
      end

      def respond_with_unavailable_session(id)
        status = 404
        headers = { 'Content-Type' => 'application/json; charset = utf-8' }
        body    = { output: format(UNAVAILABLE_SESSION_MESSAGE, id: id)}.to_json

        Rack::Response.new(body, status, headers).finish
      end

      def respond_with_unacceptable_request
        status  = 406
        headers = { 'Content-Type' => 'application/json; charset = utf-8' }
        body    = { error: "A supported version is expected in the Accept header." }.to_json

        Rack::Response.new(body, status, headers).finish
      end
  end
end
