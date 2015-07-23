require 'rake'
require 'rake/clean'
require 'cucumber'
require 'rubocop/rake_task'
require 'bundler/gem_tasks'
require 'cucumber/rake/task'
require 'rspec/core/rake_task'

CLEAN.include('pkg/', 'tmp/')

$LOAD_PATH.unshift(File.expand_path('../lib', __FILE__))

RSpec::Core::RakeTask.new(:spec)
Cucumber::Rake::Task.new(:cucumber)
RuboCop::RakeTask.new

task :test => [:spec, :cucumber]
