# frozen_string_literal: true

SimpleCov.start do
  if ENV['SIMPLECOV_ROOT']
    SimpleCov.root(ENV['SIMPLECOV_ROOT'])

    filters.clear # This will remove the :root_filter and :bundler_filter that come via simplecov's defaults

    # Because simplecov filters everything outside of the SimpleCov.root
    # This should be added, cf.
    # https://github.com/colszowka/simplecov#default-root-filter-and-coverage-for-things-outside-of-it
    add_filter do |src|
      src.filename !~ /^#{SimpleCov.root}/
    end
  end

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
    src.filename !~ %r{^#{SimpleCov.root}/(lib|spec|features)}
  end

  track_files '**/*.rb'
end

if ENV['CODECOV'] == 'yes'
  require 'simplecov-console'
  require 'codecov'

  SimpleCov.formatters = [
    SimpleCov::Formatter::Console,
    SimpleCov::Formatter::Codecov,
  ]
end

# vim: filetype=ruby
