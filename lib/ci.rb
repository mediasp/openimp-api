$:.unshift(File.dirname(__FILE__)) unless
  $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

require 'rubygems'
require 'json'
require 'uri'
require 'net/http'
require 'net/https'
require 'active_support/core_ext/string/inflections'
require 'active_support/core_ext/class'
require 'active_support/core_ext/hash/indifferent_access'

class CI
  PROTOCOL = Net::HTTPS
  HOST = 'mfs.ci-support.com'
  BASE_PATH = '/v1'

  class_inheritable_accessor :uri_path
  
  class << self
    attr_accessor :username, :password
   
    def ci_property_to_method_name(property)
      property = property.to_s
      case property
      when /^\_\_/
        property.downcase
      else
        property.underscore
      end
    end
     
    def method_name_to_ci_property(method_name)
      method_name = method_name.to_s
      case method_name
      when /^\_\_/
        property.upcase
      else
        property.camelize
      end
    end
        
    def ci_properties(*properties)
      properties = [properties] unless properties.is_a?(Array)
      properties.each do |property|
        method = CI.ci_property_to_method_name(property)
        self.define_method(method, lambda {
            self.params[method]
        })
        self.define_method(method + '=', lambda{ |value|
          self.params[method] = value
        }) unless method =~ /^\_\_/
      end
    end
    
    def do_request(http_method, path, headers=nil, put_data=nil, restrict_post_params_to=nil, &callback)
      raise "do_request cannot be called with class CI as the explicit reciever" if self == CI
      raise "CI.username not set" unless CI.username
      raise "CI.password not set" unless CI.password
      path = "#{BASE_PATH}#{resource_class.uri_path}#{path}"
      headers = (headers || {}).merge('Accept' => 'application/json')
      response = PROTOCOL.start(HOST) do |session|
        session.basic_auth(username, password)
        return case http_method
        when :get
          session.get(path, headers)
        when :head
          session.head(path, headers)
        when :post
          post_params = restrict_post_params_to ? @params.select {|k,v| restrict_post_params_to.include?[k]} : @params
          post_data = post_params.map {|k,v| "#{method_name_to_ci_property(k)}=#{v}"}.join('&')
          headers.merge!('application/x-www-form-urlencoded')
          session.post(path, post_data, headers)
        when :put
          raise "You must supply a Content-Type to perform a PUT request" unless headers['Content-Type']
          session.put(path, put_data, headers)
        when :delete
          session.delete(path, headers)
        end
      end
      response = response ? JSON.parse(response) : raise "No response recieved!"
      return callback ? callback.call(response) : self.new(response)
    end
  end
  
  
  def initialize(params={})
    raise "class CI is abstract" if self.class == CI
    @params = HashWithIndifferentAccess.merge(params)
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

