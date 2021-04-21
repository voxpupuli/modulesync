require 'spec_helper'

describe ModuleSync do
  context '::update' do
    it 'loads the managed modules from the specified :managed_modules_conf' do
      allow(ModuleSync).to receive(:find_template_files).and_return([])
      allow(ModuleSync::Util).to receive(:parse_config).with('./config_defaults.yml').and_return({})
      expect(ModuleSync).to receive(:managed_modules).with(no_args).and_return([])

      options = { managed_modules_conf: 'test_file.yml' }
      ModuleSync.update(options)
    end
  end

  context '::pr' do
    describe "Raise Error" do
      let(:puppet_module) do
        ModuleSync::PuppetModule.new 'puppet-test', remote: 'dummy'
      end

      it 'raises an error when neither GITHUB_TOKEN nor GITLAB_TOKEN are set for PRs' do
        expect { ModuleSync.pr(puppet_module) }.to raise_error(RuntimeError).and output(/No GitHub or GitLab token specified for --pr/).to_stderr
      end
    end
  end
end
