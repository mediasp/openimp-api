require 'rubygems'
require 'rake'
require 'rake/testtask'
require 'rdoc/task'

lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)
require 'ci/version'

Rake::TestTask.new do |t|
  t.verbose = true
end

RDoc::Task.new do |t|
  t.rdoc_dir = 'rdoc'
end

desc 'build a gem release and push it to dev'
task :release do
  sh 'gem build ci-api.gemspec'
  sh "scp ci-api-#{CI::VERSION}.gem dev.playlouder.com:/var/www/gems.playlouder.com/pending"
  sh "ssh dev.playlouder.com sudo include_gems.sh /var/www/gems.playlouder.com/pending"
end