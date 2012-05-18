module CI
  class Client
    attr_reader :base_uri

    def initialize(uri = 'https://api.cissme.com/media/v1', options={})
      @base_uri = uri
      @base_uri = URI.parse(uri) unless uri.is_a?(URI)

      @username   = options[:username]
      @password   = options[:password]

      @logger     = options[:logger]
      @open_timeout = options[:open_timeout]
      @read_timeout = options[:read_timeout]
    end

    # Have to be careful here, as CI use usernames with an @ sign in them,
    # and the ruby URI::HTTP doesn't handle escaping and unescaping these
    # properly. So we store the (unescaped) credentials separately; if you
    # want a URL with them incorporated you can call this which will make
    # sure they get escaped properly.
    def uri_with_credentials(extra_path=nil)
      uri = @base_uri.dup

      # URI::REGEXP::UNSAFE but disallowing @ and :
      uri.user     = URI.escape(@username, /[^-_.!~*'()a-zA-Z\d;\/?&=+$,\[\]]/n)
      uri.password = URI.escape(@password, /[^-_.!~*'()a-zA-Z\d;\/?&=+$,\[\]]/n)
      uri.path += extra_path if extra_path
      uri
    end

    # FIXME get it to support reading the response directly
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

    def multipart_post(path, options)
      make_http_request(path, options) do |path|
        request = Net::HTTP::Post.new(path)
        bodies = [yield(url)]
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
        full_path = case path
        when String then @base_uri.path + path
        when Array  then [@base_uri.path, *path].join('/')
        end
        request = yield(path)
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
          if response.body && options.fetch(:json, true)
            parse_json(response.body)
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

    # Classes must respond to .json_create(properties, client)
    # They will be passed a hash of json properties; any class instances within
    # this property hash will already have been recursively instantiated.
    #
    # Note we don't use the JSON library's inbuilt instantiation feature, as we
    # want to use this restricted custom class mapping:
    CLASS_MAPPING = {
      'MFS::Metadata::ArtistAppearance' => CI::Metadata::ArtistAppearance,
      'MFS::Metadata::Encoding'         => CI::Metadata::Encoding,
      'MFS::Metadata::Recording'        => CI::Metadata::Recording,
      'MFS::Metadata::Release'          => CI::Metadata::Release,
      'MFS::Metadata::Track'            => CI::Metadata::Track,
      'MFS::Pager'                      => CI::Pager,
      'MFS::FileToken'                  => CI::FileToken,
      'MFS::File'                       => CI::File,
      'MFS::File::Image'                => CI::File::Image,
      'MFS::File::Audio'                => CI::File::Audio,
      'MFS::ContextualMethod'           => CI::ContextualMethod,
      'MediaAPI::Data::ReleaseBatch'    => CI::Data::ReleaseBatch,
      'MediaAPI::Data::ImportRequest'   => CI::Data::ImportRequest,
      'MediaAPI::Data::Delivery'        => CI::Data::Delivery,
      'MediaAPI::Data::Offer'           => CI::Data::Offer,
      'MediaAPI::Data::Offer::Terms'    => CI::Data::Offer::Terms
    }

    def parse_json(json)
      instantiate_classes_in_parsed_json(JSON.parse(json))
    end

    def instantiate_classes_in_parsed_json(data)
      case data
      when Hash
        ci_class = data.delete('__CLASS__')
        mapped_data = {}
        data.each {|key,value| mapped_data[key] = instantiate_classes_in_parsed_json(value)}

        if ci_class
          klass = CLASS_MAPPING[ci_class]
          if klass
            klass.json_create(mapped_data)
          else
            warn("Unknown class in CI json: #{ci_class}")
            mapped_data
          end
        else
          mapped_data
        end

      when Array
        data.map {|item| instantiate_classes_in_parsed_json(item)}

      else
        data
      end
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

      log :debug,  "  #{response.body}"
    end

    def log(level, msg)
      @logger and @logger.send(level, msg)
    end

    def log_debug?
      @logger && @logger.debug?
    end
  end
end
