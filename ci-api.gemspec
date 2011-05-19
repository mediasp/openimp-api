# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

require 'ci/version'

spec = Gem::Specification.new do |s|
  s.name = "ci-api"
  s.version = CI::VERSION
  s.authors = ["Media Service Provider Ltd", "Tim Cowlishaw", "Eleanor McHugh", "Matthew Willson"]
  s.email = "help@playlouder.com"
  s.homepage = "http://dev.playlouder.com"
  s.platform = Gem::Platform::RUBY
  s.summary = "A client library for Consolidated Independent's (http://ci-info.com) Media Fulfilment API"
  s.files = Dir.glob("{lib,test}/**/*")
  s.require_path = 'lib'
  s.add_development_dependency('rake')
  s.add_dependency('json', '1.5.1')
  s.test_files = Dir.glob("test/**/test_*.rb")
  s.has_rdoc = false
end
