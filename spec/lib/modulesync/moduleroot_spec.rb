require 'spec_helper'
require 'modulesync'
require 'modulesync/moduleroot'

describe ModuleSync::ModuleRoot do
  subject { ModuleSync::ModuleRoot.new(moduleroot) }

  context 'with a valid moduleroot' do
    let(:moduleroot) { fixture_path }

    describe '#source_files' do
      it "should contain a list of source files" do
        expect(subject.source_files).to include File.expand_path("#{fixture_path}/moduleroot/.travis.yml")
      end
    end
  end

  context 'with a nonexistent moduleroot' do
    let(:moduleroot) { '/tmp/nonexistent' }
    it "should raies an error when the moduleroot doesn't exist" do
      expect{subject.source_files}.to raise_error ModuleSync::FileNotFound
    end
  end
end
