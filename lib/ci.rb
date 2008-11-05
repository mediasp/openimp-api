$:.unshift(File.dirname(__FILE__)) unless
  $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

require 'rubygems'
require 'json'
require 'uri'
require 'net/http'
require 'net/https'
require 'rexml/document'
require 'activesupport'
require 'enumerable_extensions'
require 'singleton'

#This class holds configuration information for the entire app as class instance variables, and subclasses inherit common functionality from it. It is abstract and therefore cannot be instantiated.
#
#Your username and password for the CI api should be set with:
#* CI.username='username'
#* CI.password='password'
#Each subclass instance has a .__representation__, .__class__ and errormessage property, corresponding to the __REPRESENTATION__, __CLASS__ and errormessage properties of the API.
#
#More details about all the properties of each Class of object are available at https://mfs.ci-support.com/v1/docs

module CI
  class MediaFileServer
    include Singleton

    PROTOCOL = :https
    PORT = 443
    HOST = 'mfs.ci-support.com'
    VERSION = 'v1'

    def self.methodize hash #:nodoc:
      hash.map_to_hash do |k, v|
        method_name = CIMediaFileServer.method_name(k)
        value = if v.is_a?(Hash) then
          (v['__CLASS__'] ? v['__CLASS__'].sub('API', 'CI').constantize : self).methodize(v)
        else
          v
        end
        { method_name => value }
      end
    end

    def self.property_name method_name #:nodoc:
      method_name = method_name.to_s
      property_name = exceptional_property_name_mappings && exceptional_property_name_mappings.find{|k,v| v == method_name }
      case
      when property_name then property_name.to_s
      when method_name =~ /^\_\_/ then method_name.upcase
      else method_name.camelize
      end
    end

    def self.method_name property #:nodoc:
      property = property.to_s
      method_name = exceptional_property_name_mappings && exceptional_property_name_mappings[property]
      case
      when method_name then method_name.to_s
      when property =~ /^\_\_/ then property.downcase
      else property.underscore
      end
    end

    def self.properties *properties #:nodoc:
      exceptional_property_name_mappings ||= HashWithIndifferentAccess.new
      properties = [properties] unless properties.is_a?(Array)
      properties.each do |property|
        method = if property.is_a?(Array) then
          property.map_to_hash(exceptional_property_name_mappings)
          property[1].to_s
        else
          CIMediaFileServer.method_name property
        end
        define_method method, lambda { @params[method] }
        define_method "#{method}=", lambda { |value| @params[method] = value }
      end
    end

    def self.propertyize_hash hash #:nodoc: 
      hash.map_to_hash { |k, v| { self.property_name(k) => (v.is_a?(Hash) ? self.methodize(v) : v) } }
    end

    def self.method_missing method, *arguments, &block  # :nodoc:
      # A dirty little hack to obviate the need of writing MediaFileServer.instance.method
      # to access instance methods
      instance.send method, *arguments, &block
    end

    def initialize username, password, options = {}
      @username = username
      @password = password
      @protocol = options[:protocol] || :https
      @host = options[:host] || 'mfs.ci-support.com'
      @port = options[:port] || 443
      @version = 'v1'
    end

    def request_uri asset, id = nil, action = nil
      path = "/#{@version}/#{asset}"
      if id then
        path += "/#{id}"
        if action then
          path += "/#{action}"
        end
      end
    end

    def get resource, headers = {}
      query Net::HTTP::Get.new(resource, headers)
    end

    def head resource, headers = {}
      query Net::HTTP::Head.new(resource, headers)
    end

    def post resource, properties, headers = {}
      query Net::HTTP::Post.new(resource, properties.map_to_hash { |k, v| { CIMediaFileServer.property_name(k) => v }}.to_query, headers)
    end

    def put resource, data, headers = {}
      raise "You must supply a Content-Type to perform a PUT request" unless headers['Content-Type']
      query Net::HTTP::Put.new(resource, data, headers.merge('Content-Length' => data.length))
    end

    # remove the object from the CI platform.
    def delete resource
      query Net::HTTP::Delete.new(resource)
    end

  private
    def query request
      Net::HTTP.start(@host, @port) do |connection|
        if @protocol == :https then
          connection.use_ssl = true
          connection.verify_mode = OpenSSL::SSL::VERIFY_NONE
        end
        request['Accept'] = 'application/json'
        request.basic_auth(@username, @password)
        case response = connection.request(request)
        when nil
          raise "No response received!"
        when Net::HTTPClientError, Net::HTTPServerError
          raise "HTTP ERROR #{Net::HTTPResponse::CODE_TO_OBJ.find { |k, v| v == response.class }[0]}: #{response.body}"
        else
          if block_given? then
            yield response
          else
            # @parameters.merge!(methodize(JSON.parse(response.body)))
            response
          end
        end
      end
    end
  end

  class Asset
    class_inheritable_accessor  :server
    class_inheritable_accessor  :asset_url
    self.server = MediaFileServer.instance

    attr_accessor   :id

    def initialize id = nil
      if id then
        @id = id
        load_meta_data
      end
    end

  private
    def request_uri action
      MediaFileServer.request_uri self.class.asset_url, @id, action
    end

    def load_meta_data
      
    end
  end

  class Release < Asset
    self.asset_url = "release/upc"
  end
end


class CI
  @protocol = :https
  @port = 443
  @host = 'mfs.ci-support.com'
  @base_path = '/v1'

  class_inheritable_accessor :uri_path
  class_inheritable_accessor :method_paths
  class_inheritable_accessor :exceptional_property_name_mappings

  def self.path method, id = nil
    @method = method
    "#{CI.base_path}#{self.class.uri_path}#{self.class.method_paths[method].chomp('/')}/#{id}"
  end

  class << self
    attr_accessor :username, :password, :host, :port, :protocol, :base_path, :method_paths
    
    def ci_has_many(name)
      define_method(name, lambda {
        @params[name] || []
      })
      define_method("#{name}=", lambda {|hashes|
        @params[name] = hashes.map {|hash| CI.instantiate_subclass_from_hash(hash)}
      })
    end

    def ci_has_one(name)
      define_method("#{name}=", lambda { |hash|
        @params[name] = CI.instantiate_subclass_from_hash(hash)
      })
    end
    
    def instantiate_subclass_from_hash(hash, klass=nil)
      klass ||= hash['__class__'].sub('API', 'CI').constantize
      return klass.new(hash)
    end
    
    def ci_property_to_method_name(property) #:nodoc:
      property = property.to_s
      if method_name = exceptional_property_name_mappings && exceptional_property_name_mappings[property]
        method_name.to_s
      elsif property =~ /^\_\_/
        property.downcase
      else
        property.underscore
      end
    end

    def method_name_to_ci_property(method_name) #:nodoc:  
      method_name = method_name.to_s
      if property_name = exceptional_property_name_mappings && exceptional_property_name_mappings.find{|k,v| v == method_name }
        property_name.to_s
      elsif method_name =~ /^\_\_/
        method_name.upcase
      else
        method_name.camelize
      end
    end

    def ci_properties(*properties) #:nodoc:
      exceptional_property_name_mappings ||= HashWithIndifferentAccess.new
      properties = [properties] unless properties.is_a?(Array)
      properties.each do |property|
        if property.is_a?(Array)
          exceptional_property_name_mappings.merge!({property[0] => property[1]})
          method = property[1].to_s
        else
          method = CI.ci_property_to_method_name(property)
        end
        define_method(method, lambda { @params[method] })
        define_method(method + '=', lambda{ |value| @params[method] = value })
      end
    end

    def method_paths paths = {}
      { :get => '', :head => '', :post => '', :put => '', :delete => '' }.merge!(paths).with_indifferent_access
    end
    
    def propertyize_hash(hash) #:nodoc: 
      hash.map_to_hash do |k, v|
        { self.property_name(k) => v.is_a?(Hash) ? self.methodize(v) : v }
      end
    end

=begin
    def do_request(http_method, path, headers=nil, put_data=nil, post_params=nil, calling_instance=nil, &callback) #:nodoc:
      raise "do_request cannot be called with class CI as the explicit reciever" if self == CI
      raise "CI.username not set" unless CI.username
      raise "CI.password not set" unless CI.password
      path = "#{CI.base_path}#{(calling_instance.class rescue self).uri_path}#{path}"
      (headers ||= {}).merge!('Accept' => 'application/json')
      connection = Net::HTTP.new(CI.host, CI.port)
      if CI.protocol == :https
        connection.use_ssl = true
        connection.verify_mode = OpenSSL::SSL::VERIFY_NONE
      end
      req = case http_method
      when :get
        Net::HTTP::Get.new(path, headers)
      when :head
        Net::HTTP::Head.new(path, headers)
      when :post
        post_params ||= (calling_instance.params.map_to_hash {|k,v| { method_name_to_ci_property(k) => v} }) if calling_instance
        post_data = post_params.map {|k,v| "#{k}=#{v}"}.join('&')
        headers.merge!('Content-Type' => 'application/x-www-form-urlencoded')
        r = Net::HTTP::Post.new(path, headers)
        r.body = post_data
        r
      when :put
        raise "You must supply a Content-type to perform a PUT request" unless headers['Content-type']
        headers.merge!('Content-length' => put_data.length.to_s)
        r = Net::HTTP::Put.new(path, headers)
        r.body = put_data
        r
      when :delete
        Net::HTTP::Delete.new(path, headers)
      end
      req.basic_auth(CI.username, CI.password)
      response = connection.request(req)
      raise "No response recieved!" if !response
      #TODO: deal with exceptional responses.
      case response
      when Net::HTTPClientError, Net::HTTPServerError
        raise "HTTP ERROR #{Net::HTTPResponse::CODE_TO_OBJ.find {|k,v| v == response.class}[0]}: #{response.body}"#how ugly.
      else
        result = if callback
          callback.call(response)
        elsif calling_instance
          calling_instance.params=calling_instance.params.merge(methodize_hash(JSON.parse(response.body)))
          true
        else
          self.new(methodize_hash(JSON.parse(response.body)))
        end
        return result
      end
    end
  end
=end

  ci_properties :__REPRESENTATION__, :__CLASS__, [:errormessage, :errormessage]
  method_paths :get => '/', :head => '/', :post => '/', :put => '/', :delete => '/'

  attr_accessor :headers, :parameters, :id
  attr_reader   :request, :response, :method
  
  def initialize id, parameters = {}
    @id = id
    @parameters = HashWithIndifferentAccess.new
    parameters.each { |method_name, value| self.send("#{method_name}=".to_sym, value) } #so overridden accessors wil work
    @headers = {}
  end

  def method_path method
    self.class.method_paths[method]
  end

  def execute request
    @request = request
    Net::HTTP.start(CI.host, CI.port) do |connection|
      if CI.protocol == :https then
        connection.use_ssl = true
        connection.verify_mode = OpenSSL::SSL::VERIFY_NONE
      end
      request['Accept'] = 'application/json'
      request.basic_auth(CI.username, CI.password)
      case @response = connection.request(request)
      when nil
        raise "No response received!"
      when Net::HTTPClientError, Net::HTTPServerError
        raise "HTTP ERROR #{Net::HTTPResponse::CODE_TO_OBJ.find { |k, v| v == response.class }[0]}: #{response.body}"
      else
        if block_given? then
          yield response
        else
          parameters.merge!(methodize(JSON.parse(response.body)))
          response
        end
      end
    end
  end

  def get
    execute Net::HTTP::Get.new(CI.path(:get, id), headers)
  end

  def head
    execute Net::HTTP::Head.new(CI.path(:head, id), headers)
  end

  def post form = nil
    @parameters = form || @parameters
    execute Net::HTTP::Post.new(CI.path(:post, id), parameters.map_to_hash { |k, v| { property_name(k) => v }}.to_query, headers)
  end

  def put data = nil
    raise "You must supply a Content-Type to perform a PUT request" unless headers['Content-Type']
    execute Net::HTTP::Put.new(CI.path(:put, id), data, headers.merge!('Content-Length' => put_data.length))
  end

  # remove the object from the CI platform.
  def delete
    execute Net::HTTP::Delete.new(CI.path(:delete, id), headers)
  end

  #Find a resource by its id. Will return an instance of the appropriate subclass.
  def find
    get("/#{id}") do |response|
      json = methodize(JSON.parse(response.body))
      klass = json['__class__'].sub('API', 'CI').constantize
      klass.new(json)
    end
  end

  # populate this object's attributes from the server
  def get_meta
    get
  end

  # save the contents of this object's attributes to the server
  def store_meta
    post
  end

  #override in subclasses that need to do something else
  def save
    store_meta
  end

  def errormessage = string #:nodoc:
    raise "Error from CI API - #{__class__}: #{string}"
  end

=begin  
  def do_request(http_method, path, headers=nil, put_data=nil, post_params=nil, &callback) #:nodoc:
    self.class.do_request(http_method, path, headers, put_data, post_params, self, &callback)
  end
=end
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