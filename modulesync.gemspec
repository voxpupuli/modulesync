# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = 'modulesync'
  spec.version       = '0.4.0'
  spec.authors       = ['Colleen Murphy']
  spec.email         = ['colleen@puppetlabs.com']
  spec.summary       = %q{Puppet Module Synchronizer}
  spec.description   = %q{Utility to synchronize common files across puppet modules in Github.}
  spec.homepage      = "http://github.com/puppetlabs/modulesync"
  spec.license       = "Apache 2"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.6"

  spec.add_runtime_dependency 'git', '~>1.2'
  spec.add_runtime_dependency 'puppet-blacksmith', '~>3.0'
end
