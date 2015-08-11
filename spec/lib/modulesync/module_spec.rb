require 'spec_helper'
require 'modulesync/module'
require 'modulesync/project'

describe ModuleSync::Module do
  let(:project) { ModuleSync::Project.new(fixture_path) }
  subject { ModuleSync::Module.new('mockmod', project) }

  context 'when setting configs to a valid project root' do
    it 'should find the files in the moduleroot' do
      expect(subject.files).not_to be_empty
    end

    it 'should return all configurations for all files' do
      expect(subject.module_defaults).to be_a Hash
      expect(subject.module_configs).to be_a Hash
      expect(subject.module_configs).not_to be_empty
    end
  end
end
