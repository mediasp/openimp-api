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

    MIME_DELIMITER_CHARS = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ'()+_-./:=?" # "," RFC valid character but not supported by MFS parser
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
      start_http_connection do |connection|
        request = yield(url, attributes, payload)
        request['Accept'] = 'application/json'
        request.basic_auth(@username, @password)
        case response = connection.request(request)
        when nil
          raise "No response received!"
        when Net::HTTPClientError, Net::HTTPServerError
          raise "HTTP ERROR #{Net::HTTPResponse::CODE_TO_OBJ.find { |k, v| v == response.class }[0]}: #{response.body}"
        else
          parse_json(response.body)
        end
      end
    end

    # This is a monstous hack to automatically have the JSON parser construct classes
    # corresponding to the class names in the __CLASS__ attributes in the JSON, /except/
    # using 'CI' as the namespace rather than (variously) 'MFS' or 'MediaAPI' as they do.
    #
    # Suffice to say it's not threadsafe, or rather it is but only thanks to the 'Thread.exclusive'
    def parse_json(json)
      Thread.exclusive do
        old_mfs = (Object.const_get(:MFS) rescue nil)
        Object.send(:remove_const, :MFS) if old_mfs
        Object.const_set(:MFS, CI)

        old_media_api = (Object.const_get(:MediaAPI) rescue nil)
        Object.send(:remove_const, :MediaAPI) if old_media_api
        Object.const_set(:MediaAPI, CI)

        old_json_create_id = JSON.create_id
        JSON.create_id = '__CLASS__'

        begin
          JSON.parse(json)
        ensure
          Object.send(:remove_const, :MFS)
          Object.const_set(:MFS, old_mfs) if old_mfs
          Object.send(:remove_const, :MediaAPI)
          Object.const_set(:MediaAPI, old_media_api) if old_media_api
          JSON.create_id = old_json_create_id
        end
      end
    end
  end

  # This is useful to expose for (eg) integration tests that want to load fixtures from json without hitting the API
  def self.parse_json(json)
    MediaFileServer.instance.send(:parse_json, json)
  end

end

require 'ci/version'
require 'ci/assets'
require 'ci/files'
require 'ci/pager'
require 'ci/recording'
require 'ci/release'
require 'ci/track'
require 'ci/data'
