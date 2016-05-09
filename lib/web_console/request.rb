module WebConsole
  # Web Console tailored request object.
  class Request < ActionDispatch::Request
    # Configurable set of whitelisted networks.
    cattr_accessor :whitelisted_ips
    @@whitelisted_ips = Whitelist.new

    # Define a vendor MIME type. We can call it using Mime[:web_console_v2].
    Mime::Type.register 'application/vnd.web-console.v2', :web_console_v2

    # Returns whether a request came from a whitelisted IP.
    #
    # For a request to hit Web Console features, it needs to come from a white
    # listed IP.
    def from_whitelisted_ip?
      whitelisted_ips.include?(strict_remote_ip)
    end

    # Determines the remote IP using our much stricter whitelist.
    def strict_remote_ip
      GetSecureIp.new(self, whitelisted_ips).to_s
    end

    # Returns whether the request is acceptable.
    def acceptable?
      xhr? && accepts.any? { |mime| Mime[:web_console_v2] == mime }
    end

    def id_for_repl_session
      xhr? && repl_sessions_re.match(path) { |m| m[:id] }
    end

    def id_for_repl_session_trace
      xhr? && repl_session_trace_re.match(path) { |m| m[:id] }
    end

    def auth?
      auth_re.match(path)
    end

    def auth_secret?
      post? && auth_secret_re.match(path)
    end

    def trust_me!
      whitelisted_ips.add(strict_remote_ip)
    end

    private

      def repl_sessions_re
        @_repl_sessions_re ||= %r{#{Middleware.mount_point}/repl_sessions/(?<id>[^/]+)}
      end

      def repl_session_trace_re
        @_repl_session_trace_re ||= %r{#{repl_sessions_re}/trace\z}
      end

      def auth_re
        @_auth_re ||= %r{#{Middleware.mount_point}/auth\z}
      end

      def auth_secret_re
        @_auth_new_re ||= %r{#{Middleware.mount_point}/auth/secret\z}
      end

      class GetSecureIp < ActionDispatch::RemoteIp::GetIp
        def initialize(req, proxies)
          # After rails/rails@07b2ff0 ActionDispatch::RemoteIp::GetIp initializes
          # with a ActionDispatch::Request object instead of plain Rack
          # environment hash. Keep both @req and @env here, so we don't if/else
          # on Rails versions.
          @req      = req
          @env      = req.env
          @check_ip = true
          @proxies  = proxies
        end

        def filter_proxies(ips)
          ips.reject do |ip|
            @proxies.include?(ip)
          end
        end
      end
  end
end
