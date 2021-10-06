SimpleCov.start do
  track_files 'lib/**/*.rb'

  add_filter '/spec'

  enable_coverage :branch

  # do not track vendored files
  add_filter '/vendor'
  add_filter '/.vendor'
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
