module WebConsole
  # A response object that writes content before the closing </body> tag, if
  # possible.
  class Response < Rack::Response
    def insert_head(content)
      insert_after '<head>', content
    end

    def insert_body(content)
      insert_before '</body>', content
    end

    private

      def insert_before(*args)
        insert(*args) { |body, tag| body.index(tag) }
      end

      def insert_after(*args)
        insert(*args) do |body, tag|
          if pos = body.rindex(tag)
            pos + tag.length
          end
        end
      end

      def insert(tag, content)
        raw_body = Array(body).first.to_s

        if pos = yield(raw_body, tag)
          raw_body.insert(pos, content)
        else
          raw_body << content
        end

        initialize raw_body, status, headers
      end
  end
end
