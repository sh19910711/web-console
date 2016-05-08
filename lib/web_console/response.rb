module WebConsole
  # A response object that writes content before the closing </body> tag, if
  # possible.
  #
  # The object quacks like Rack::Response.
  class Response < Struct.new(:body, :status, :headers)
    def write(content)
      raw_body = Array(body).first.to_s

      if position = raw_body.rindex('</body>')
        raw_body.insert(position, content)
      else
        raw_body << content
      end

      self.body = raw_body
    end

    def finish
      Rack::Response.new(body, status, headers).finish
    end

    class << self
      def text(opts = {})
        status  = opts.fetch(:status, 200)
        headers = { 'Content-Type' => "#{opts.fetch(:type, 'text/plain')}; charset=utf-8" }
        body    = yield

        Rack::Response.new(body, status, headers).finish
      end

      def html(opts = {}, &b)
        text opts.merge(type: 'text/html'), &b
      end

      def json(opts = {})
        text opts.merge(type: 'application/json') do
          yield.to_json
        end
      end
    end
  end
end
