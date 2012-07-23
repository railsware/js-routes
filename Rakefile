# encoding: utf-8

require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'rake'

require 'jeweler'
Jeweler::Tasks.new do |gem|
  # gem is a Gem::Specification... see http://docs.rubygems.org/read/chapter/20 for more options
  gem.name = "js-routes"
  gem.homepage = "http://github.com/railsware/js-routes"
  gem.license = "MIT"
  gem.summary = %Q{Brings Rails named routes to javascript}
  gem.description = %Q{Generates javascript file that defines all Rails named routes as javascript helpers}
  gem.email = "agresso@gmail.com"
  gem.authors = ["Bogdan Gusiev"]
  # dependencies defined in Gemfile
end
Jeweler::RubygemsDotOrgTasks.new

require 'rspec/core'
require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.pattern =  FileList['spec/**/*_spec.rb'].sort_by do|n|
    # we need to run post_rails_init_spec as the latest
    # because it cause unrevertable changes to runtime
    n.include?("post_rails_init_spec") ? 1 : 0
  end
end

task :default => :spec

