module WebConsole
  class Auth
    cattr_reader :last_secret

    class << self
      def new_secret
        @@last_secret = SecureRandom.hex(12)
      end

      def valid?(secret)
        if memo = last_secret
          @@last_secret = nil
          secret == memo
        end
      end
    end
  end
end
