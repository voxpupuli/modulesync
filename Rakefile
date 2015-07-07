require 'rake/clean'
require 'cucumber/rake/task'

CLEAN.include("pkg/", "tmp/")

Cucumber::Rake::Task.new do |t|
  t.cucumber_opts = ""
  t.cucumber_opts << "--format pretty"
end

task :test => [:clean, :cucumber]
