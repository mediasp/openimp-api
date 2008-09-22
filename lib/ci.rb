$:.unshift(File.dirname(__FILE__)) unless
  $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

require 'rubygems'
require 'json'
require 'uri'
require 'net/http'
require 'rexml/document'
require 'activesupport'

module CI
  HOST = 'mfs.ci-support.com'
  BASE_PATH = '/v1/'

  class << self
    attr_accessor :username, :password
   
    def ci_property_to_method_name(property)
      case property
      when /\_\_[A-Z]+\_\_/
        property.downcase
      else
        property.underscore
      end
    end
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

