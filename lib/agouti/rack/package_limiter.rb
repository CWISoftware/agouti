require 'rack'

module Agouti
  module Rack

    # Public: rack middleware that truncates the gzipped response.
    # Useful for testing critical rendering path optimization.
    class PackageLimiter

      ENABLE_HEADER = 'X-Agouti-Enable'
      LIMIT_HEADER = 'X-Agouti-Limit'
      # Public: Default limit of bytes.
      DEFAULT_LIMIT = 14000

      # Public: Constructor.
      #
      # app - rack app instance
      #
      # Returns an instance of Agouti::Rack::PackageLimiter middleware.
      def initialize(app)
        @app = app
      end

      # Public: Apply middleware to request.
      #
      # env - environment.
      #
      # Raises Agouti::Rack::PackageLimiter::InvalidHeaderException if headers are not valid. The following values are accepted:
      #   X-Agouti-Enable:
      #   - header not present or set with value 0(disabled).
      #   - header set with value 1 (enabled).
      #   X-Agouti-Limit: a positive integer.
      #
      # The response body is gzipped only when the following conditions are met:
      #   Header X-Agouti-Enable set with value 1 and header Content-Type with value 'text/html'.
      #   If header X-Agouti-Limit is set, response body will be truncated to the given number of bytes.
      #   Otherwise, body will be truncated to the default limit, which is 14000 bytes.
      #
      # If header X-Agouti-Enable is enabled but header Content-Type does not have value 'text/html',
      # the middleware will return a response with status code 204 and empty body.
      #
      # If header X-Agouti-Enable has value 0 or is empty, the response will not be modified.
      def call(env)
        raise InvalidHeaderException unless valid?(env)

        status, headers, body = @app.call(env)

        set_limit(env)

        if enabled?(env)
          unless headers['Content-Type'] == 'text/html'
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
        @limit = (get_http_header(env, LIMIT_HEADER)) ? get_http_header(env, LIMIT_HEADER).to_i : DEFAULT_LIMIT
      end

      def valid_enable_header? env
        header = get_http_header(env, ENABLE_HEADER)

        (0..1).include?(header) || header.nil?
      end

      def valid_limit_header? env
        header = get_http_header(env, LIMIT_HEADER)

        (header.kind_of?(Integer) && header > 0) || header.nil?
      end

      def valid? env
        valid_enable_header?(env) && valid_limit_header?(env)
      end

      # Public: class responsible for truncating the gzip stream to a given number of bytes.
      class GzipTruncatedStream < ::Rack::Deflater::GzipStream
        # Public: Constructor.
        #
        # body - response body.
        # mtime - last-modified time.
        # byte_limit - byte limit.
        #
        # Returns an instance of Agouti::Rack::PackageLimiter::GzipTruncatedStream.
        def initialize body, mtime, byte_limit
          super body, mtime
          @byte_limit = byte_limit
          @total_sent_bytes = 0
        end

        # Public: Writes data to stream.
        #
        # data - data.
        #
        # If total sent bytes reaches bytes limit, data is sliced.
        def write(data)
          if @total_sent_bytes + data.bytesize > @byte_limit
            data = data.byteslice(0, @byte_limit - @total_sent_bytes)
          end

          @total_sent_bytes += data.bytesize
          @writer.call(data)
        end
      end

      # Public: custom exception class for invalid headers.
      class InvalidHeaderException < Exception; end;
    end
  end
end
