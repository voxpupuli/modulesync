SimpleCov.start do
  add_group 'Source code', 'lib'

  add_group 'Unit tests', 'spec'

  add_group 'Behavior tests', 'features'
  add_filter '/features/support/env.rb'

  enable_coverage :branch

  # do not track vendored files
  add_filter '/vendor'
  add_filter '/.vendor'

  # exclude anything that is not in lib, spec or features directories
  add_filter do |src|
    !(src.filename =~ /^#{SimpleCov.root}\/(lib|spec|features)/)
  end

  track_files '**/*.rb'
end

if ENV['CODECOV']
  require 'simplecov-console'
  require 'codecov'

  SimpleCov.formatters = [
    SimpleCov::Formatter::Console,
    SimpleCov::Formatter::Codecov,
  ]
end

# vim: filetype=ruby
