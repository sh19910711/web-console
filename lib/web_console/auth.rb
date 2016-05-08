module WebConsole
  class Auth
    cattr_reader :last_secret
    cattr_reader :passports
    @@passports = Set.new

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

      def new_passport
        passport = SecureRandom.uuid
        passports << passport
        passport
      end

      def passholder?(request)
        passports.include?(request.cookie_jar['passport'])
      end
    end
  end
end
