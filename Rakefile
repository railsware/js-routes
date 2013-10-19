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
require 'bundler/gem_tasks'
require 'rspec/core'
require 'rspec/core/rake_task'
require 'appraisal'

RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.pattern =  FileList['spec/**/*_spec.rb'].sort_by do|n|
    # we need to run post_rails_init_spec as the latest
    # because it cause unrevertable changes to runtime
    n.include?("post_rails_init_spec") ? 1 : 0
  end
end

task :test_all => :appraisal # test all rails

task :default => :spec