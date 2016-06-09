module WebConsole
  # An extension of Rack::Response that writes content before the </body> tag
  # or after the <head> tag, if possible.
  class Response < ::Rack::Response
    def insert_head(content)
      insert '<head>', content, true
    end

    def insert_body(content)
      insert '</body>', content, false
    end

    private

      def insert(tag, content, shift)
        raw_body = Array(body).first.to_s

        if pos = raw_body.rindex(tag)
          pos += tag.length if shift
          raw_body.insert(pos, content)
        else
          raw_body << content
        end

        initialize raw_body, status, headers
      end
  end
end
