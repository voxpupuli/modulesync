require 'simplecov'
root = File.expand_path('../../../', __FILE__)
SimpleCov.command_name(ENV['SIMPLECOV_COMMAND_NAME'])
SimpleCov.root(root)
load File.join(root, '.simplecov')
