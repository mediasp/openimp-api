$:.unshift(File.dirname(__FILE__)) unless
  $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

require 'rubygems'
require 'json'
require 'uri'
require 'net/http'
require 'net/https'
require 'active_support/core_ext/string/inflections'
require 'active_support/core_ext/class'

class CI
  PRTOCOL = Net::HTTPS
  HOST = 'mfs.ci-support.com'
  BASE_PATH = '/v1'

  class_inheritable_array :allowed_requests
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
    
    def do_request(http_method, path_pattern=[], post_params=[], post_data=nil, &callback)
      raise "CI.username not set" unless CI.username
      raise "CI.password not set" unless CI.password
      multipart = post_data && !post_params.empty?
      post_params = @params.select {|k,v| post_params.include?[k]}
      path = path_pattern.shift
      while path =~ /\?/ && !path_pattern.empty?
        path.sub!('?', path_pattern.shift.to_s)
      end
      path = "#{BASE_PATH}#{resource_class.uri_path}#{path}"
      PROTOCOL.start(url) do |session|
        session.send(http_method)
        #this is what needs fleshing out now.
      end
      response = JSON.parse(response)
      return callback ? callback.call(response) : self.new(response)
    end
     
  end
  
  
  def initialize(params={})
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

