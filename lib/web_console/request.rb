module WebConsole
  # Web Console tailored request object.
  class Request < ActionDispatch::Request
    # Configurable set of whitelisted networks.
    cattr_accessor :whitelisted_ips
    @@whitelisted_ips = Whitelist.new

    # Define a vendor MIME type. We can call it using Mime[:web_console_v2].
    Mime::Type.register 'application/vnd.web-console.v2', :web_console_v2

    # A token to access Web Console features from non whitelisted ips
    cattr_reader :passport
    cattr_reader :secret

    # Generates a new passport and returns it
    def self.new_passport
      @@passport = SecureRandom.uuid
    end

    # Generates a new secret key and returns it
    def self.new_secret
      @@secret = SecureRandom.hex(12)
    end

    # Returns whether a request came from a whitelisted IP or a passholder.
    #
    # For a request to hit Web Console features, it needs to come from a white
    # listed IP or passholder.
    def whitelisted?
      from_whitelisted_ip? || passholder?
    end

    # Determines the remote IP using our much stricter whitelist.
    def strict_remote_ip
      GetSecureIp.new(self, whitelisted_ips).to_s
    end

    # Returns whether the request is acceptable.
    def acceptable?
      xhr? && accepts.any? { |mime| Mime[:web_console_v2] == mime }
    end

    # Returns whether the request has a secret token to generate a passport
    def has_secret?
      secret && secret == params[:secret]
    end

    def id_for_repl_session
      xhr? && repl_sessions_re.match(path) { |m| m[:id] }
    end

    def auth?
      auth_re.match(path)
    end

    private

      def from_whitelisted_ip?
        whitelisted_ips.include?(strict_remote_ip)
      end

      def passholder?
        passport && passport == cookie_jar['__web_console_passport']
      end

      def repl_sessions_re
        @_repl_sessions_re ||= %r{#{Middleware.mount_point}/repl_sessions/(?<id>[^/]+)}
      end

      def auth_re
        @_auth_re ||= %r{#{Middleware.mount_point}/auth\z}
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
