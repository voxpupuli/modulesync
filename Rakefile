# frozen_string_literal: true

require 'rake/clean'
require 'cucumber/rake/task'
require 'rubocop/rake_task'

begin
  require 'rspec/core/rake_task'
  RSpec::Core::RakeTask.new(:spec)
rescue LoadError
  puts 'rspec not installed - skipping unit test task setup'
end

begin
  require 'voxpupuli/rubocop/rake'
rescue LoadError
  # RuboCop is an optional group
end

CLEAN.include('pkg/', 'tmp/')

Cucumber::Rake::Task.new do |t|
  t.cucumber_opts = ''
  t.cucumber_opts << '--format pretty'
end

task test: %i[clean spec cucumber rubocop]
task default: %i[test]

begin
  require 'github_changelog_generator/task'
  GitHubChangelogGenerator::RakeTask.new :changelog do |config|
    config.header = "# Changelog\n\nAll notable changes to this project will be documented in this file."
    config.exclude_labels = %w[duplicate question invalid wontfix wont-fix modulesync skip-changelog github_actions]
    config.user = 'voxpupuli'
    config.project = 'modulesync'
    config.future_release = Gem::Specification.load("#{config.project}.gemspec").version
  end

  # Workaround for https://github.com/github-changelog-generator/github-changelog-generator/issues/715
  require 'rbconfig'
  if RbConfig::CONFIG['host_os'].include?('linux')
    task :changelog do
      puts 'Fixing line endings...'
      changelog_file = File.join(__dir__, 'CHANGELOG.md')
      changelog_txt = File.read(changelog_file)
      new_contents = changelog_txt.gsub("\r\n", "\n")
      File.open(changelog_file, 'w') { |file| file.puts new_contents }
    end
  end
rescue LoadError
end
