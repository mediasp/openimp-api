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

class CI
  PROTOCOL = :http
  PORT = 80 
  HOST = 'api.stage'
  BASE_PATH = '/v1'

  class_inheritable_accessor :uri_path
  class_inheritable_accessor :exceptional_property_name_mappings
  
  class << self
    attr_accessor :username, :password
   
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
        }) unless method =~ /^\_\_/
      end
    end
    
    
    def parse_json_response(response)
      response = JSON.parse(response)
      response.map_to_hash {|k,v|  [ci_property_to_method_name(k), v]}
    end
    
    def do_request(http_method, path, headers=nil, put_data=nil, restrict_post_params_to=nil, calling_instance=nil, &callback)
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
        post_params = restrict_post_params_to ? @params.select {|k,v| restrict_post_params_to.include?[k]} : @params
        post_data = post_params.map {|k,v| "#{method_name_to_ci_property(k)}=#{v}"}.join('&')
        headers.merge!('application/x-www-form-urlencoded')
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
        calling_instance.params=calling_instance.params.merge(parse_json_response(response.body))
        true
      else
        self.new(parse_json_response(response.body))
      end
      return result
    end
  end
  
  attr_accessor :params
  
  def initialize(params={})
    raise "class CI is abstract" if self.class == CI
    @params = HashWithIndifferentAccess.new.merge(params)
  end
  
  def do_request(http_method, path, headers=nil, put_data=nil, restrict_post_params_to=nil, &callback)
    self.class.do_request(http_method, path, headers, put_data, restrict_post_params_to, self, &callback)
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

