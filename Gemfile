source ENV['GEM_SOURCE'] || 'https://rubygems.org'

gemspec

group :release do
  gem 'github_changelog_generator', :require => false
end

group :coverage, optional: ENV['CODECOV']!='yes' do
  gem 'simplecov-console', :require => false
  gem 'codecov', :require => false
end
