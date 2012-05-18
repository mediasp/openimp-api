require 'rubygems'
begin
  require 'json'
rescue LoadError
  raise LoadError, "You need to install either the json or json-jruby gem, as appropriate"
end
require 'uri'
require 'date'
require 'time'
require 'cgi'
require 'net/http'
require 'net/https'
require 'singleton'
require 'thread' # for Thread.exclusive

module CI

  # This is useful to expose for (eg) integration tests that want to load
  # fixtures from json without hitting the API
  def self.parse_json(json)
    deserializer = Object.new.extend(CI::Deserializer)
    deserializer.parse_json(json)
  end

end

require 'ci/version'
require 'ci/assets'
require 'ci/files'
require 'ci/pager'
require 'ci/recording'
require 'ci/release'
require 'ci/track'
require 'ci/artist_appearance'
require 'ci/data'
require 'ci/deserializer'
require 'ci/client'
require 'ci/repository'
