source ENV['GEM_SOURCE'] || 'https://rubygems.org'

gemspec

group :release do
  gem 'github_changelog_generator', require: false
end

group :coverage, optional: ENV['CODECOV'] != 'yes' do
  gem 'codecov', require: false
  gem 'simplecov-console', require: false
end
