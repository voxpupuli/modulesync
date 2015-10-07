require 'rake/clean'
require 'cucumber/rake/task'
require 'rubocop/rake_task'

RuboCop::RakeTask.new

CLEAN.include('pkg/', 'tmp/')

Cucumber::Rake::Task.new do |t|
  t.cucumber_opts = ''
  t.cucumber_opts << '--format pretty'
end

task :test => [:clean, :cucumber, :rubocop]
