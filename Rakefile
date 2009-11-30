require 'rubygems'
require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'
require 'rake/gempackagetask'

Rake::TestTask.new do |t|
  t.verbose = true
end

Rake::RDocTask.new do |t|
  t.rdoc_dir = 'rdoc'
end

spec = Gem::Specification.new do |s|
  s.name = "ci-api"
  s.version = "0.1.5"
  s.authors = ["Media Service Provider Ltd", "Tim Cowlishaw", "Eleanor McHugh"]
  s.email = "help@playlouder.com"
  s.homepage = "http://dev.playlouder.com"
  s.platform = Gem::Platform::RUBY
  s.summary = "A client library for Consolidated Independent's (http://ci-info.com) Media Fulfilment API"
  s.files = FileList["{doc,lib,test}/**/*"].to_a
  s.require_path = 'lib'
  s.test_files = FileList["test/**/test_*.rb"].to_a - ['test/test_helper.rb']
  s.has_rdoc = false
end

Rake::GemPackageTask.new(spec) do |pkg|
  pkg.need_tar = true
end

