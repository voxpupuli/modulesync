require 'spec_helper'

describe ModuleSync do
  context '::update' do
    it 'loads the managed modules from the specified :managed_modules_conf' do
      allow(ModuleSync).to receive(:find_template_files).and_return([])
      allow(ModuleSync::Util).to receive(:parse_config).with('./config_defaults.yml').and_return({})
      expect(ModuleSync).to receive(:managed_modules).with('./test_file.yml', nil, nil).and_return([])

      options = { managed_modules_conf: 'test_file.yml' }
      ModuleSync.update(options)
    end
  end

  context '::create_pr_manager' do
    describe "Raise Error" do
      it 'raises an error when neither GITHUB_TOKEN nor GITLAB_TOKEN are set for PRs' do
        expect { ModuleSync.create_pr_manager() }.to raise_error(RuntimeError).and output(/GITHUB_TOKEN/).to_stderr
      end
    end
  end
end
