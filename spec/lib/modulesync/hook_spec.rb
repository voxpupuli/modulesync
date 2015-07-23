require 'spec_helper'
require 'modulesync/hook'
require 'tempfile'

describe ModuleSync::Hook do
  let(:temp) { Tempfile.new('hook') }
  let(:project_root) { File.dirname temp }
  let(:subject) { ModuleSync::Hook.new(temp.path, 'puppetlabs') }

  context 'when activating the hook' do
    it 'should create the hook' do
      expect(subject.activate).not_to be nil
      expect(temp.read).to match /msync -m \S+ -n puppetlabs/
      temp.close
      temp.unlink
    end
  end

  context 'when deactivating the hook' do
    it 'should delete the hook file' do
      subject.activate
      expect(File.exist?(temp.path)).to be true
      expect(subject.deactivate).not_to be nil
      expect(File.exist?(temp.path)).to be false
    end
  end
end
