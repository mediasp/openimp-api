require 'rubygems'
begin
  require 'json'
rescue LoadError
  raise LoadError, "You need to install either the json or json-jruby gem, as appropriate"
end
require 'uri'
require 'date'
require 'time'
require 'cgi'
require 'net/http'
require 'net/https'
require 'singleton'
require 'thread' # for Thread.exclusive

#Your username and password for the CI api should be set with:
#* CI::MediaFileServer.configure 'username', 'password'

module CI
  # TODO: get rid of the singleton here. If we're gonna do this as global state then
  # why not just put it directly on the CI module. Or if we want to avoid global state,
  # then a singleton is no use anyway.
  class MediaFileServer
    include Singleton

    def self.method_missing(method, *arguments, &block)  # :nodoc:
      # A dirty little hack to obviate the need of writing MediaFileServer.instance.method
      # to access instance methods
      instance.send method, *arguments, &block
    end

    def configure(username, password, options = {})
      @username   = username
      @password   = password
      @protocol   = options[:protocol]  || :https
      @host       = options[:host]      || 'api.cissme.com'
      @port       = options[:port]      || {:https => 443, :http => 80}[@protocol]
      @base_path  = options[:base_path] || '/media/v1'
      @logger     = options[:logger]
      @open_timeout = options[:open_timeout]
      @read_timeout = options[:read_timeout]
    end

    def path(path_components)
      [@base_path, *path_components].join('/')
    end

    def get(path_components, options={})
      path = path(path_components)
      query = options[:query] and begin
        path << '?'
        path << query.map {|k,v| "#{CGI.escape(k.to_s)}=#{CGI.escape(v.to_s)}"}.join("&")
      end
      json_query(path) { |url, p| Net::HTTP::Get.new(url) }
    end

    def get_octet_stream(path_components, overrides={})
      start_http_connection(overrides) do |connection|
        request = Net::HTTP::Get.new(path(path_components))
        request.basic_auth(@username, @password)
        response = connection.request(request) do |response|
          raise "Bad HTTP response from CI: #{response.class}" unless Net::HTTPSuccess === response
          yield response if block_given?
        end
        response.body
      end
    end

    def head(path_components)
      json_query(path(path_components)) { |url, p| @request = Net::HTTP::Head.new(url) }
    end

    def post(path_components, values, headers = {})
      json_query(path(path_components), values) { |url, v|
        request = Net::HTTP::Post.new(url)
        request.set_form_data v
        headers.each { |header, setting| request[header] = setting }
        request
        }
    end

    MIME_DELIMITER_CHARS = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ()+_-./:=?'" # "," RFC valid character but not supported by MFS parser

    def create_mime_delimiter(length = 30)
      srand; result = ''; raise 'too long' if length > 70
      random_range = MIME_DELIMITER_CHARS.length
      length.times { result << MIME_DELIMITER_CHARS[rand(random_range), 1] }
      result
    end

    def multipart_post(path_components, sub_type = "form-data")
      json_query(path(path_components)) do |url, p|
        request = Net::HTTP::Post.new(url)
        bodies = [yield(url)]
        delimiter = create_mime_delimiter
        request['Content-Type'] = "multipart/#{sub_type}; boundary=\"#{delimiter}\""
        separator = "\r\n--#{delimiter}\r\n"
        request.body = "\r\n#{separator}#{bodies.join(separator)}\r\n--#{delimiter}--\r\n"
        request['Content-Length'] = request.body.length.to_s # will need to change to bytesize for 1.9
        request
      end
    end

    def put(path_components, content_type, payload)
      json_query(path(path_components), {'Content-Length' => payload.length.to_s, 'Content-Type' => content_type}, payload) do |url, p, data|
        request = Net::HTTP::Put.new(url, p)
        request.body = data
        request
      end
    end

    def delete(path_components)
      if block_given? then
        yield(json_request(path(path_components)) { |url| get(url) })
      end
      json_query(path(path_components)) { |url, p| Net::HTTP::Delete.new(url) }
    end

    def base_uri
      @base_uri ||= begin
        klass = {:http => URI::HTTP, :https => URI::HTTPS}[@protocol]
        user = URI.escape(@username, /[^-_.!~*'()a-zA-Z\d;\/?&=+$,\[\]]/n) #URI::REGEXP::UNSAFE but disallowing @ and :
        pass = URI.escape(@password, /[^-_.!~*'()a-zA-Z\d;\/?&=+$,\[\]]/n)
        klass.build(:host => @host, :port => @port, :userinfo => "#{user}:#{pass}")
      end
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
    def start_http_connection(overrides={}, &block)
      connection = Net::HTTP.new(overrides[:host] || @host, overrides[:port] || @port)
      connection.open_timeout = @open_timeout if @open_timeout
      connection.read_timeout = @read_timeout if @read_timeout
      if (overrides[:protocol] || @protocol) == :https then
        connection.use_ssl = true
        connection.verify_mode = OpenSSL::SSL::VERIFY_NONE
      end
      connection.start(&block)
    end

    # The API uses a custom JSON format for encoding class data. A +json_query+ automatically takes
    # care of the necessary translation to return a response object of the correct class.
    #
    # TODO: Improve error handling to be useful.
    def json_query(url, attributes = {}, payload = nil)
      start_time = Time.now

      start_http_connection do |connection|
        request = yield(url, attributes, payload)
        request['Accept'] = 'application/json'
        request.basic_auth(@username, @password)

        log_http_request(request, attributes, payload)

        case response = connection.request(request)
        when nil
          log :warn, "No response received"
          raise "No response received!"
        when Net::HTTPClientError, Net::HTTPServerError
          log_http_response(start_time, request, response)

          http_error = Net::HTTPResponse::CODE_TO_OBJ.
            find { |k, v| v == response.class }[0]
          raise "HTTP ERROR #{http_error}: #{response.body}"
        else
          log_http_response(start_time, request, response)
          parse_json(response.body)
        end
      end
    end

    require 'ci/version'
    require 'ci/assets'
    require 'ci/files'
    require 'ci/pager'
    require 'ci/recording'
    require 'ci/release'
    require 'ci/track'
    require 'ci/artist_appearance'
    require 'ci/data'

    # Classes must respond to .json_create.
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
    def log_http_request(request, attributes, payload)
      log :info,    "Starting request: #{request.method} #{request.path}"

      return unless log_debug?

      log :debug,   "  attributes : #{attributes.inspect}"
      log :debug,   "  payload    : #{payload.inspect}"
      log :debug,   "  headers    :"
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

  # This is useful to expose for (eg) integration tests that want to load fixtures from json without hitting the API
  def self.parse_json(json)
    MediaFileServer.instance.send(:parse_json, json)
  end

end