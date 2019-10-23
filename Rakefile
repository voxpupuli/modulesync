require 'rake/clean'
require 'cucumber/rake/task'
require 'rubocop/rake_task'

begin
  require 'rspec/core/rake_task'
  RSpec::Core::RakeTask.new(:spec)
rescue LoadError
  puts 'rspec not installed - skipping unit test task setup'
end

RuboCop::RakeTask.new

CLEAN.include('pkg/', 'tmp/')

Cucumber::Rake::Task.new do |t|
  t.cucumber_opts = ''
  t.cucumber_opts << '--format pretty'
end

task :test => %i[clean spec cucumber rubocop]

task :default => ['test']
