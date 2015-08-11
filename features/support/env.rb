require 'aruba/cucumber'
require 'simplecov'

Before do |scenario|
  command_name = if scenario.respond_to?(:feature) && scenario.respond_to?(:name)
                 "#{scenario.feature.name} #{scenario.name}"
               else
                 raise TypeError.new("Don't know how to extract command name from #{scenario.class}")
               end

  # Used in simplecov_setup so that each scenario has a different name and their coverage results are merged instead
  # of overwriting each other as 'Cucumber Features'
  ENV['SIMPLECOV_COMMAND_NAME'] = command_name.to_s

  @aruba_timeout_seconds = 10
  simplecov_setup_pathname = Pathname.new(__FILE__).expand_path.parent.join('simplecov_setup')
  # set environment variable so child processes will merge their coverage data with parent process's coverage data.
  if RUBY_VERSION < '1.9'
    ENV['RUBYOPT'] = "-r rubygems -r#{simplecov_setup_pathname} #{ENV['RUBYOPT']}"
  else
    ENV['RUBYOPT'] = "-r#{simplecov_setup_pathname} #{ENV['RUBYOPT']}"
  end
end
