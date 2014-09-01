require 'rack'

module Agouti
  module Rack
    class PackageLimiter

      ENABLE_HEADER = 'X-Agouti-Enable'
      LIMIT_HEADER = 'X-Agouti-Limit'
      DEFAULT_LIMIT = 14000

      # Creates Agouti::Rack::PackageLimiter middleware.
      #
      # [app] rack app instance
      def initialize(app)
        @app = app
      end

      def call(env)
        raise InvalidHeaderException.new unless valid?(env, ENABLE_HEADER) && valid?(env, LIMIT_HEADER)

        status, headers, body = @app.call(env)

        set_limit(env)

        if enabled?(env)
          # Just execute for html
          # TODO: find a better way of doing it
          unless (headers.key? 'Content-Type' and headers['Content-Type'].include? 'text/html')
            # Returns empty responses for requests that are not html
            return [204, {}, []]
          end

          headers = ::Rack::Utils::HeaderHash.new(headers)

          headers['Content-Encoding'] = 'gzip'
          headers.delete('Content-Length')
          mtime = headers.key?('Last-Modified') ? Time.httpdate(headers['Last-Modified']) : Time.now

          [status, headers, GzipTruncatedStream.new(body, mtime, @limit)]
        else
          [status, headers, body]
        end
      end

      private

      def get_http_header env, header
        env["HTTP_#{header.upcase.gsub('-', '_')}"]
      end

      def enabled? env
        get_http_header(env, ENABLE_HEADER) && get_http_header(env, ENABLE_HEADER) == 1
      end

      def set_limit env
        @limit = (get_http_header(env, LIMIT_HEADER)) ?  get_http_header(env, LIMIT_HEADER).to_i : DEFAULT_LIMIT
      end

      def valid? env, header
        case header
        when ENABLE_HEADER
          (0..1).include?(get_http_header(env, ENABLE_HEADER)) || get_http_header(env, ENABLE_HEADER).nil?
        when LIMIT_HEADER
          get_http_header(env, LIMIT_HEADER).class == Fixnum || get_http_header(env, LIMIT_HEADER).nil?
        end
      end

      class GzipTruncatedStream < ::Rack::Deflater::GzipStream
        attr_reader :byte_limit

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

      class InvalidHeaderException < Exception; end;
    end
  end
end
