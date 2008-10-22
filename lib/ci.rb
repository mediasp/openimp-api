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

# This class holds configuration information for the entire app as class instance variables, and subclasses inherit common functionality from it. It is abstract and therefore cannot be instantiated.
# Your username and password for the CI api should be set with.
#CI.username='username'
#CI.password='password'
#Each subclass instance has a .__representation__, .__class__ and errormessage property, corresponding to the __REPRESENTATION__, __CLASS__ and errormessage properties of the API.
#More details about all the properties of each Class of object are available at https://mfs.ci-support.com/v1/docs

class CI
  PROTOCOL = :http
  PORT = 80 
  HOST = 'api.stage'
  BASE_PATH = '/v1'

  class_inheritable_accessor :uri_path
  class_inheritable_accessor :exceptional_property_name_mappings
  
  class << self

    attr_accessor :username, :password   
   #Find  a resource by its id. Will return an instance of the appropriate subclass.
    def find(id)
      do_request(:get, "/#{id}") do |response|
        json = methodize_hash(JSON.parse(response.body))
        klass = json['__class__'].sub('API', 'CI').constantize
        klass.new(json)
      end
    end
   
   #:nodoc:
    def ci_property_to_method_name(property)
      property = property.to_s
      if method_name = exceptional_property_name_mappings && exceptional_property_name_mappings[property]
        method_name.to_s
      elsif property =~ /^\_\_/
        property.downcase
      else
        property.underscore
      end
    end
    
   #:nodoc:  
    def method_name_to_ci_property(method_name)
      method_name = method_name.to_s
      if property_name = exceptional_property_name_mappings && exceptional_property_name_mappings.find{|k,v| v == method_name }
        property_name.to_s
      elsif method_name =~ /^\_\_/
        method_name.upcase
      else
        method_name.camelize
      end
    end
    
    #:nodoc:
    def ci_properties(*properties)
      exceptional_property_name_mappings ||= HashWithIndifferentAccess.new
      properties = [properties] unless properties.is_a?(Array)
      properties.each do |property|
        if property.is_a?(Array)
          exceptional_property_name_mappings.merge!({property[0] => property[1]})
          method = property[1].to_s
        else
          method = CI.ci_property_to_method_name(property)
        end
        define_method(method, lambda {
            @params[method]
        })
        define_method(method + '=', lambda{ |value|
          @params[method] = value
        })
      end
    end
    
    #:nodoc:
    def methodize_hash(hash)
      hash.map_to_hash do |k,v|
        if v.is_a?(Hash)
          klass = v['__CLASS__'] ? v['__CLASS__'].sub('API', 'CI').constantize : self
          [self.ci_property_to_method_name(k), klass.methodize_hash(v)]
        else
          [self.ci_property_to_method_name(k), v]
        end
      end
    end
    
    
    #:nodoc: 
    def propertyize_hash(hash)
      hash.map_to_hash do |k, v|
        if v.is_a?(Hash)
          [self.method_name_to_ci_property(k), self.methodize_hash(v)]
        else
          [self.method_name_to_ci_property(k), v]
        end
      end
    end
    
    #:nodoc:
    def do_request(http_method, path, headers=nil, put_data=nil, post_params=nil, calling_instance=nil, &callback)
      raise "do_request cannot be called with class CI as the explicit reciever" if self == CI
      raise "CI.username not set" unless CI.username
      raise "CI.password not set" unless CI.password
      path = "#{BASE_PATH}#{(calling_instance ? calling_instance.class : self).uri_path}#{path}"
      headers = (headers || {}).merge('Accept' => 'application/json')
      connection = Net::HTTP.new(HOST, PORT)
      if PROTOCOL == :https
        connection.use_ssl = true
        connection.verify_mode = OpenSSL::SSL::VERIFY_NONE
      end
      req = case http_method
      when :get
        Net::HTTP::Get.new(path, headers)
      when :head
       Net::HTTP::Head.new(path, headers)
      when :post
        post_params = (@params.map_to_hash {|k,v| [method_name_to_ci_property(k), v]} || {}) if !post_params
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
  
  attr_accessor :params
  ci_properties :__REPRESENTATION__, :__CLASS__, [:errormessage, :errormessage]
  
  #Instantiate a subclass of CI with an ActiveRecord-ish hash of properties syntax.
  def initialize(params={})
    raise "class CI is abstract" if self.class == CI
    @params = HashWithIndifferentAccess.new
    params.each { |method_name, value| self.send("#{method_name}=".to_sym, value)} #so overridden accessors wil work
  end
  
  #:nodoc:
  def errormessage=(string)
    raise "Error from CI API - #{__class__}: #{string}"
  end
  
  #:nodoc:
  def do_request(http_method, path, headers=nil, put_data=nil, post_params=nil, &callback)
    self.class.do_request(http_method, path, headers, put_data, post_params, self, &callback)
  end
  
  # remove the object from the CI platform.
  def delete
    do_request(:delete, "/#{id}")
    self.data = nil
  end
   
end


#:load the useful stuff here:
def load_files(dir)
  Dir.new(dir).each do |f|
    if f =~ /\.rb$/
      require "#{dir}/#{f}"
      folder = "#{dir}/#{f.sub(/\.rb$/, '/')}"
      load_files(folder) if File.exists?(folder) 
    end
  end
end
load_files(File.dirname(__FILE__) + '/ci/')

