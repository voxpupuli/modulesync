lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name                  = 'modulesync'
  spec.version               = '1.0.0'
  spec.authors               = ['Vox Pupuli']
  spec.email                 = ['voxpupuli@groups.io']
  spec.summary               = 'Puppet Module Synchronizer'
  spec.description           = 'Utility to synchronize common files across puppet modules in Github.'
  spec.homepage              = 'http://github.com/voxpupuli/modulesync'
  spec.license               = 'Apache-2.0'
  spec.required_ruby_version = '>= 2.0.0'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_development_dependency 'aruba'
  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'rubocop', '~> 0.50.0'

  spec.add_runtime_dependency 'git', '~>1.3'
  spec.add_runtime_dependency 'octokit', '~>4.0'
  spec.add_runtime_dependency 'puppet-blacksmith', '~>3.0'
  spec.add_runtime_dependency 'thor'
end
