require 'active_support/core_ext/string/strip'

module WebConsole
  class Middleware
    TEMPLATES_PATH = File.expand_path('../templates', __FILE__)

    cattr_accessor :mount_point
    @@mount_point = '/__web_console'

    cattr_accessor :whiny_requests
    @@whiny_requests = true

    def initialize(app)
      @app = app
    end

    def call(env)
      app_exception = catch :app_exception do
        request = create_regular_or_whiny_request(env)

        if request.auth?
          return render_auth_form(env) if request.get?
          return auth!(request) if request.post?
        end

        return call_app(env) unless request.from_whitelisted_ip?
        return render_auth_secret if request.post? && request.auth_secret?

        if id = request.id_for_repl_session
          return update_repl_session(id, request) if request.put?
          return change_stack_trace(id, request) if request.post?
        end

        status, headers, body = call_app(env)

        if session = Session.from(Thread.current) and acceptable_content_type?(headers)
          response = Response.new(body, status, headers)
          template = Template.new(env, session)

          response.headers["X-Web-Console-Session-Id"] = session.id
          response.headers["X-Web-Console-Mount-Point"] = mount_point
          response.write(template.render('index'))
          response.finish
        else
          [ status, headers, body ]
        end
      end
    rescue => e
      WebConsole.logger.error("\n#{e.class}: #{e}\n\tfrom #{e.backtrace.join("\n\tfrom ")}")
      raise e
    ensure
      # Clean up the fiber locals after the session creation. Object#console
      # uses those to communicate the current binding or exception to the middleware.
      Thread.current[:__web_console_exception] = nil
      Thread.current[:__web_console_binding] = nil

      raise app_exception if Exception === app_exception
    end

    private

      def acceptable_content_type?(headers)
        Mime::Type.parse(headers['Content-Type']).first == Mime[:html]
      end

      def json_response_with_session(id, request, opts = {})
        return respond_with_unacceptable_request unless request.acceptable?
        return respond_with_unavailable_session(id) unless session = Session.find(id)

        Response.json(opts) { yield session }
      end

      def create_regular_or_whiny_request(env)
        request = Request.new(env)
        whiny_requests ? WhinyRequest.new(request) : request
      end

      def update_repl_session(id, request)
        json_response_with_session(id, request) do |session|
          { output: session.eval(request.params[:input]) }
        end
      end

      def change_stack_trace(id, request)
        json_response_with_session(id, request) do |session|
          session.switch_binding_to(request.params[:frame_id])

          { ok: true }
        end
      end

      def render_auth_form(env)
        Response.html { Template.new(env).render('auth_form') }
      end

      def render_auth_secret
        Response.text { format(I18n.t('auth.description'), mount: Middleware.mount_point, secret: Auth.secret) }
      end

      def auth!(request)
        if Auth.valid?(request.params[:secret])
          request.trust_me!
          Response.text { 'OK' }
        else
          Response.text(status: 401) { 'Bad Credentials' }
        end
        Auth.reset!
      end

      def respond_with_unavailable_session(id)
        Response.json(status: 404) do
          { output: format(I18n.t('errors.unavailable_session'), id: id)}
        end
      end

      def respond_with_unacceptable_request
        Response.json(status: 406) do
          { output: I18n.t('errors.unacceptable_request') }
        end
      end

      def call_app(env)
        @app.call(env)
      rescue => e
        throw :app_exception, e
      end

      class Auth
        cattr_reader :last_secret

        class << self
          def secret
            @@last_secret = SecureRandom.hex(12)
          end

          def valid?(secret)
            last_secret == secret unless last_secret.nil?
          end

          def reset!
            @@last_secret = nil
          end
        end
      end
  end
end
