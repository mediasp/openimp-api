module CI

  # TODO would be nice to make clients aware of repositories and classes
  # in a nice way, so that we don't have the class mapping business and can do
  # smarter stuff with models like not awful lazy loading
  class Client

    attr_reader :base_uri
    attr_reader :username
    attr_reader :password
    attr_reader :open_timeout
    attr_reader :read_timeout

    include Deserializer

    def initialize(uri = 'https://api.cissme.com/media/v1', options={})
      @base_uri = uri
      @base_uri = URI.parse(uri) unless uri.is_a?(URI)

      @username   = options.fetch(:username)
      @password   = options.fetch(:password)

      @logger     = options[:logger]
      @open_timeout = options[:open_timeout] || 60
      @read_timeout = options[:read_timeout] || 60
    end

    # Have to be careful here, as CI use usernames with an @ sign in them,
    # and the ruby URI::HTTP doesn't handle escaping and unescaping these
    # properly. So we store the (unescaped) credentials separately; if you
    # want a URL with them incorporated you can call this which will make
    # sure they get escaped properly.
    def uri_with_credentials(extra_path=nil)
      uri = @base_uri.dup

      # URI::REGEXP::UNSAFE but disallowing @ and :
      uri.user     = escape_uri_part(@username)
      uri.password = escape_uri_part(@password)
      uri.path += extra_path if extra_path
      uri
    end

    def escape_uri_part(part)
      URI.escape(part, /[^-_.!~*'()a-zA-Z\d;\/?&=+$,\[\]]/n)
    end

    def get(path, options={})
      make_http_request(path, options) do |path|
        query = options[:query] and begin
          path << '?'
          path << query.map {|k,v| "#{CGI.escape(k.to_s)}=#{CGI.escape(v.to_s)}"}.join("&")
        end
        Net::HTTP::Get.new(path)
      end

    end

    def head(path, options={})
      make_http_request(path, options) {|path| Net::HTTP::Head.new(path)}
    end

    def post(path, values, options={})
      make_http_request(path, options) do |path|
        request = Net::HTTP::Post.new(path)
        request.set_form_data(values)
        request
      end
    end

    MIME_DELIMITER_CHARS = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ()+_-./:=?'" # "," RFC valid character but not supported by MFS parser

    def multipart_post(path, options={})
      make_http_request(path, options) do |path|
        request = Net::HTTP::Post.new(path)
        bodies = [yield(path)]
        delimiter = create_mime_delimiter
        request['Content-Type'] = "multipart/form-data; boundary=\"#{delimiter}\""
        separator = "\r\n--#{delimiter}\r\n"
        request.body = "\r\n#{separator}#{bodies.join(separator)}\r\n--#{delimiter}--\r\n"
        request['Content-Length'] = request.body.length.to_s # will need to change to bytesize for 1.9
        request
      end
    end

    def put(path, content_type, payload)
      make_http_request(path, options, payload) do |path, p, data|
        request = Net::HTTP::Put.new(path)
        request['Content-Length'] = payload.length.to_s
        request['Content-Type'] = content_type
        request.body = data
        request
      end
    end

    def delete(path, options={})
      make_http_request(path, options) {|path| Net::HTTP::Delete.new(path)}
    end

    # way to get a URI object for some particular path_components, allowing you to override the base
    # (protocol / host / port, but not path) of the uri from the globally-configured default, if you
    # so desire.
    # TODO: sort out once and for all the messy URI handling in this library, and stop it relying on
    # global config.
    def uri_for(path_components, override_base_uri=nil)
      (override_base_uri || base_uri).merge(path(path_components))
    end

  private
    class HTTPError < StandardError; end

    def make_http_request(path, options={}, &block)
      start_time = Time.now

      connection = Net::HTTP.new(@base_uri.host, @base_uri.port)
      connection.open_timeout = @open_timeout if @open_timeout
      connection.read_timeout = @read_timeout if @read_timeout
      if @base_uri.scheme == 'https' then
        connection.use_ssl = true
        connection.verify_mode = OpenSSL::SSL::VERIFY_NONE
      end
      connection.start do
        path_as_string = case path
        when String then '/' + path
        when Array  then '/' + path.join('/')
        end
        request = yield(@base_uri.path + path_as_string)
        request.basic_auth(@username, @password)
        options[:headers].each {|k,v| request[k] = v} if options[:headers]
        request['Accept'] = 'application/json' if options.fetch(:json, true)
        log_http_request(request)

        response = connection.request(request)

        case response
        when nil
          log :warn, "No response received"
          raise HTTPError, "No response received!"
        when Net::HTTPClientError, Net::HTTPServerError
          log_http_response(start_time, request, response)
          raise HTTPError, "#{response.code}: #{response.body}"
        else
          log_http_response(start_time, request, response)
          if options.fetch(:json, true) && response.body

            # we inject a nasty instance variable to the client so that it
            # can lazy load any references to other objects - could be done
            # with thin_models, as this has built in support
            # for lazy loading attributes
            deserialized_object = parse_json(response.body) do |instance|
              instance.instance_variable_set("@__deserializing_client", self)
            end

            deserialized_object.tap do |result|
              # not sure whether this should include the base_uri path
              # mung the uri on to the deserialized object - used for equality
              # and sort of replaces the old path_components property
              result.respond_to?(:uri=) && result.uri = path_as_string
            end
          else
            response
          end
        end
      end
    end

    def create_mime_delimiter(length = 30)
      srand; result = ''; raise 'too long' if length > 70
      random_range = MIME_DELIMITER_CHARS.length
      length.times { result << MIME_DELIMITER_CHARS[rand(random_range), 1] }
      result
    end

    # dump out an http request on to the logger
    def log_http_request(request)
      log :info,    "Starting request: #{request.method} #{request.path}"

      return unless log_debug?

      log :debug,   "  body    : #{request.body}"
      log :debug,   "  headers :"
      request.each_header do |name, value|
        log :debug, "    #{name}: #{value}"
      end
    end

    def log_http_response(start_time, request, response)
      took_secs = Time.now - start_time
      # anything below http 400 is not an error
      level = response.code.to_i < 400 ? :info : :warn
      log level,   "Finished request: #{request.method} #{request.path} #{response.code} #{took_secs}"

      return unless log_debug?
    end

    def log(level, msg)
      @logger and @logger.send(level, msg)
    end

    def log_debug?
      @logger && @logger.debug?
    end
  end
end
