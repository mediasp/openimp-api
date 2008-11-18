_mypath = File.dirname(__FILE__)
$:.unshift(_mypath) unless $:.include?(_mypath) || $:.include?(File.expand_path(_mypath))
_mypath = nil

require 'rubygems'
require 'json'
require 'uri'
require 'net/http'
require 'net/https'
require 'rexml/document'
require 'activesupport'
require 'core_extensions.rb'
require 'singleton'

#Your username and password for the CI api should be set with:
#* CI::MediaFileServer.configure 'username', 'password'
#
#More details about all the properties of each Class of object are available at https://mfs.ci-support.com/v1/docs

module CI
  class MediaFileServer
    include Singleton

    PROTOCOL = :https
    PORT = 443
    HOST = 'mfs.ci-support.com'
    VERSION = 'v1'
    API_ATTRIBUTES = SymmetricTranslationTable.new(:api, :ruby)
    BOOLEAN_ATTRIBUTES = []
    
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
      @port = options[:port] || 443
      @version = 'v1'
    end

    def resolve asset, id = nil, action = nil
      path = "/#{@version}/#{asset}"
      if id then
        path += "/#{id}"
        if action then
          path += "/#{action}"
        end
      end
    end

    def get url
      json_query(url) { |url, p| Net::HTTP::Get.new(url) }
    end

    def get_octet_stream url
      Net::HTTP.start(@host, @port) do |connection|
        if @protocol == :https then
          connection.use_ssl = true
          connection.verify_mode = OpenSSL::SSL::VERIFY_NONE
        end
        request = Net::HTTP::Get.new(url)
        request[:accept] = 'application/json'
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

    def head url
      json_query(url) { |url, p| Net::HTTP::Head.new(url) }
    end

    def post url, properties
      json_query(url, properties) { |url, p| Net::HTTP::Post.new(url, p.to_query) }
    end

    def put url, content_type, data
      json_query(url, data) { |url, p| Net::HTTP::Put.new(url, p, {'Content-Length' => p.length, 'Content-Type' => content_type}) }
    end

    def delete url
      if block_given? then
        yield(json_request(url) { |url| get(url) })
      end
      json_query(url) { |url, p| Net::HTTP::Delete.new(url) }
    end

  private
    # The API uses a custom JSON format for encoding class data. A +json_query+ automatically takes
    # care of the necessary translation to return a response object of the correct class.
    def json_query url, attributes = {}, &block
      # Preprocess data before sending it to the server
      a = attributes.inject({}) do |h, (k, v)|
        # Boolean values are treated as true = 1 and false = 0 by the CI API
        h[k] = if BOOLEAN_ATTRIBUTES.include?(k) then
          v ? 1 : 0
        else v
        end
      end
      Net::HTTP.start(@host, @port) do |connection|
        if @protocol == :https then
          connection.use_ssl = true
          connection.verify_mode = OpenSSL::SSL::VERIFY_NONE
        end
        request = yield(url, a)
        request[:accept] = 'application/json'
        request.basic_auth(@username, @password)
        case response = connection.request(request)
        when nil
          raise "No response received!"
        when Net::HTTPClientError, Net::HTTPServerError
          raise "HTTP ERROR #{Net::HTTPResponse::CODE_TO_OBJ.find { |k, v| v == response.class }[0]}: #{response.body}"
        else
          JSON.instance_variable_set "@#{create_id}", '__CLASS__'
          result = JSON.parse(response.body)
          JSON.instance_variable_set "@#{create_id}", 'json_class'
          result
        end
      end
    end
  end
end

def load_files(dir) #:nodoc:
  Dir.new(dir).each do |f|
    if f =~ /\.rb$/
      require "#{dir}/#{f}"
      folder = "#{dir}/#{f.sub(/\.rb$/, '/')}"
      load_files(folder) if File.exists?(folder) 
    end
  end
end
load_files(File.dirname(__FILE__) + '/ci/')