require 'yaml'
require 'spec_helper'
require 'modulesync/project'
require 'modulesync/modulefile'

describe ModuleSync::ModuleFile do
  let(:project) { ModuleSync::Project.new(fixture_path) }
  let(:mod) { ModuleSync::Module.new('mockmod', project) }
  subject { ModuleSync::ModuleFile.new(mod, template) }

  context 'when generating a module file from a valid ERB template' do
    let(:template) { 'Rakefile' }

    it 'should have the expected output' do
      expect(subject.output).to match /PuppetLint.configuration.send\('disable_80chars'\)/
      expect(subject.output).to match /PuppetLint.configuration.send\('disable_class_inherits_from_params_class'\)/
      expect(subject.output).to match /PuppetLint.configuration.send\('disable_documentation'\)/
      expect(subject.output).to match /PuppetLint.configuration.send\('disable_single_quote_string_with_variables'\)/
    end
  end

  context 'when attempting to generate an invalid ERB template' do
    let(:template) { 'BadRakefile' }
    it 'should fail with a ParseError' do
      expect { subject.output }.to raise_error ModuleSync::ParseError
    end
  end
end
