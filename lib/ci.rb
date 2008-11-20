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
    end

    def resolve asset, id = nil, action = nil
      path = "/#{VERSION}/#{asset}"
      if id then
        path += "/#{id}"
        if action then
          path += "/#{action}"
        end
      end
      return path
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

    def head url
      json_query(url) { |url, p| Net::HTTP::Head.new(url) }
    end

    def post url, properties
      json_query(url, properties) { |url, p|
        request = Net::HTTP::Post.new(url)
        request.set_form_data p
        request
        }
    end

    def put url, content_type, payload
      json_query(url, {'Content-Length' => payload.length.to_s, 'Content-Type' => content_type}, payload) do |url, p, data|
        request = Net::HTTP::Put.new(url, p)
        request.body = data
        request
      end
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
    #
    # TODO: Improve error handling to be useful.
    def json_query url, attributes = {}, payload = nil, &block
      Net::HTTP.start(@host, @port) do |connection|
        if @protocol == :https then
          connection.use_ssl = true
          connection.verify_mode = OpenSSL::SSL::VERIFY_NONE
        end
        request = yield(url, attributes, payload)
        request['Accept'] = 'application/json'
        request.basic_auth(@username, @password)
        case response = connection.request(request)
        when nil
          raise "No response received!"
        when Net::HTTPClientError, Net::HTTPServerError
          raise "HTTP ERROR #{Net::HTTPResponse::CODE_TO_OBJ.find { |k, v| v == response.class }[0]}: #{response.body}"
        else
          alias_namespace(CI, :API) do
            JSON.instance_variable_set "@create_id", '__CLASS__'
            result = JSON.parse(response.body)
            JSON.instance_variable_set "@create_id", 'json_class'
            result
          end
        end
      end
    end

    # The API namespace is used by CI's server-side code but this is a fragile choice so we use CI locally
    # and perform some behind-the-scenes magic to make it look elegant
    def alias_namespace original, synonym, &block
      s = synonym.to_s.to_sym
      old_binding = Object.const_get(s) rescue nil
      Object.const_set(s, original)
      result = yield
      old_binding ? Object.const_set(s, old_binding) : Object.send(:remove_const, s)
      result
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