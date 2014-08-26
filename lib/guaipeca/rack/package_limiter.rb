module Guaipeca

  module Rack

    class PackageLimiter

      ENABLE_HEADER = 'X-Guaipeca-Enable'
      LIMIT_HEADER = 'X-Guaipeca-Limit'
      DEFAULT_LIMIT = 14000

      ##
      # Creates Agouti::Rack::PackageLimiter middleware.
      #
      # [app] rack app instance
      # [options] hash of package limiter options, i.e.
      #           'if' - a lambda enabling / disabling deflation based on returned boolean value
      #                  e.g use Rack::Deflater, :if => lambda { |env, status, headers, body| body.length > 512 }
      def initialize(app, options = {})
        @app = app
        @condition = options[:if]
        @limit = options[:limit] || 14000
      end

      def get_http_header env, header
        env["HTTP_#{header.upcase.gsub('-', '_')}"]
      end

      def call(env)
        status, headers, body = @app.call(env)

        set_limit(env)

        if enabled?(env)
          # Just execute for html
          # TODO: find a better way of doing it
          unless (headers.has_key? 'Content-Type' and headers['Content-Type'].include? 'text/html')
            # Returns empty responses for requests that are not html
            return [204, {}, []]
          end

          headers = ::Rack::Utils::HeaderHash.new(headers)

          headers['Content-Encoding'] = "gzip"
          headers.delete('Content-Length')
          mtime = headers.key?("Last-Modified") ? Time.httpdate(headers["Last-Modified"]) : Time.now

          [status, headers, GzipTruncatedStream.new(body, mtime, @limit)]
        else
          [status, headers, body]
        end
      end

      private

      def enabled? env
        get_http_header(env, ENABLE_HEADER) and get_http_header(env, ENABLE_HEADER) == '1'
      end

      def set_limit env
        @limit = (get_http_header(env, LIMIT_HEADER)) ?  get_http_header(env, LIMIT_HEADER).to_i : DEFAULT_LIMIT
      end

      class GzipTruncatedStream < ::Rack::Deflater::GzipStream
        def initialize body, mtime, byte_limit
          super body, mtime
          @byte_limit = byte_limit
          @total_sent_bytes = 0
        end

        def write(data)
          # slices data if total sent bytes reaches byte limit
          if @total_sent_bytes + data.bytesize > @byte_limit
            data = data.byteslice(0, @byte_limit - @total_sent_bytes)
          end

          @total_sent_bytes += data.bytesize
          @writer.call(data)
        end
      end
    end
  end
end