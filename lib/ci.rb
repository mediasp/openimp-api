$:.unshift(File.dirname(__FILE__)) unless
  $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

require 'rubygems'
require 'json'
require 'uri'
require 'net/http'
require 'rexml/document'
require 'activesupport'

class CI
  HOST = 'mfs.ci-support.com'
  BASE_PATH = '/v1/'

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
    
    def find(prms)
      params = CI.find(self, prms) if self.class.allowed_methods.include?(:get) #
      return self.new(params) if params
    end

    def create(prms)
      instance = self.new(prms)
      instance.save
      return instance
    end

    def uri_path
      ''
    end

  end
  
  
  def initialize(params={})
    @params = HashWithIndifferentAccess.merge(params)
  end
 
  def save
    #remove __ properties here - they never need be sent back to the server.
    CI.save(self) if self.class.allowed_methods.include?(:post)
  end
  
    
  
  
end


#:load the useful stuff here:
def load_files(dir)
  Dir.new(dir).each do |f|
    case f
    when /\.rb$/
      require "dir/f"
    when /\/$/
      load_files(dir + f)
    end
  end
end
load_files(File.dirname(__FILE__) + '/ci/')

