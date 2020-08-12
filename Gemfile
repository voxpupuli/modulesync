source ENV['GEM_SOURCE'] || 'https://rubygems.org'

gemspec

gem 'cucumber', '< 3.0' if RUBY_VERSION < '2.1'
gem 'octokit', '~> 4.9'

group :release do
  gem 'github_changelog_generator', :require => false, :git => 'https://github.com/voxpupuli/github-changelog-generator', :branch => 'voxpupuli_essential_fixes'
end
