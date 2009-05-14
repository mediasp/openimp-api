_mypath = File.dirname(__FILE__)
$:.unshift(_mypath) unless $:.include?(_mypath) || $:.include?(File.expand_path(_mypath))
_mypath = nil

require 'rubygems'
begin
  require 'json'
rescue LoadError
  raise LoadError, "You need to install either the json or json-jruby gem, as appropriate"
end
require 'uri'
require 'net/http'
require 'net/https'
require 'core_extensions.rb'
require 'singleton'

#Your username and password for the CI api should be set with:
#* CI::MediaFileServer.configure 'username', 'password'
#
#More details about all the properties of each Class of object are available at https://mfs.ci-support.com/v1/docs

module CI
  # The +MediaFileServer+ uses a _singleton_ to wrap all access to the CI server into a single instance.
  class MediaFileServer
    include Singleton

    PROTOCOL = :https
    PORT = 443
    HOST = 'mfs.ci-support.com'
    VERSION = 'v1'

    def self.method_missing method, *arguments, &block  # :nodoc:
      # A dirty little hack to obviate the need of writing MediaFileServer.instance.method
      # to access instance methods
      instance.send method, *arguments, &block
    end

    def configure username, password, options = {}
      @username = username
      @password = password
      @protocol = options[:protocol] || :https
      @host = options[:host] || 'mfs.ci-support.com'
      @port = options[:port] || 44
    end

    def path(path_components)
      "/#{VERSION}/#{path_components.join('/')}"
    end

    def get(path_components, options={})
      json_query(path(path_components)) { |url, p| Net::HTTP::Get.new(url) }
    end

    def get_octet_stream(path_components)
      start_http_connection do |connection|
        request = Net::HTTP::Get.new(path(path_components))
        request['accept'] = 'application/json'
        request.basic_auth(@username, @password)
        case response = connection.request(request)
        when nil
          raise "No response received!"
        when Net::HTTPClientError, Net::HTTPServerError
          raise "HTTP ERROR #{Net::HTTPResponse::CODE_TO_OBJ.find { |k, v| v == response.class }[0]}: #{response.body}"
        else
          response.body
        end
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

    def multipart_post(path_components, sub_type = "form-data")
      json_query(path(path_components)) { |url, p|
        request = Net::HTTP::Post.new(url)
        request.multipart sub_type, Array.new(yield(url))
        request
        }
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

  private
    def start_http_connection(&block)
      connection = Net::HTTP.new(@host, @port)
      if @protocol == :https then
        connection.use_ssl = true
        connection.verify_mode = OpenSSL::SSL::VERIFY_NONE
      end
      connection.start(&block)
    end

    # The API uses a custom JSON format for encoding class data. A +json_query+ automatically takes
    # care of the necessary translation to return a response object of the correct class.
    #
    # TODO: Improve error handling to be useful.
    def json_query url, attributes = {}, payload = nil, &block
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
          # The MFS namespace is used by CI's server-side code but we use CI locally and perform some behind-the-scenes magic
          # to make it look elegant. This is a legacy of the API namespace previously used, but as it makes the namespace
          # conversion more explicit we'll keep it for the time being.
          with_aliased_namespace(CI, :MFS) do
            JSON.instance_variable_set "@create_id", '__CLASS__'
            result = JSON.parse(response.body)
            JSON.instance_variable_set "@create_id", 'json_class'
            result
          end
        end
      end
    end
  end
end

def load_files(dir) #:nodoc:
  Dir.new(dir).each do |f|
    if f =~ /\.rb$/ then
      require "#{dir}/#{f}"
      folder = "#{dir}/#{f.sub(/\.rb$/, '/')}"
      load_files(folder) if File.exists?(folder)
    end
  end
end
load_files(File.dirname(__FILE__) + '/ci/')
