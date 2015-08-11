require 'simplecov'
require 'modulesync'

SimpleCov.command_name 'rspec'
SimpleCov.start

def fixture_path
  File.expand_path(File.join(__FILE__, '..', 'fixtures'))
end

RSpec.configure do |c|
  c.formatter = 'documentation'
  c.color = true
end
