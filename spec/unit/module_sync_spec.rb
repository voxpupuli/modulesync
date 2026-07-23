# frozen_string_literal: true

require 'spec_helper'

describe ModuleSync do
  context '::update' do
    it 'loads the managed modules from the specified :managed_modules_conf' do
      allow(described_class).to receive(:find_template_files).and_return([])
      allow(ModuleSync::Util).to receive(:parse_config).with('./config_defaults.yml').and_return({})
      expect(described_class).to receive(:managed_modules).with(no_args).and_return([])

      options = { managed_modules_conf: 'test_file.yml' }
      described_class.update(options)
    end

    it 'validates PR credentials for every module before managing any module' do
      allow(ModuleSync::Util).to receive(:parse_config).with('./config_defaults.yml').and_return({})
      puppet_module = double
      allow(described_class).to receive_messages(find_template_files: [], managed_modules: [puppet_module])

      expect(puppet_module).to receive(:git_service).ordered
      expect(described_class).to receive(:manage_module).with(puppet_module, [], {}).ordered

      described_class.update(pr: true)
    end

    it 'does not manage modules when PR credentials are missing' do
      allow(ModuleSync::Util).to receive(:parse_config).with('./config_defaults.yml').and_return({})
      puppet_module = double
      allow(described_class).to receive_messages(find_template_files: [], managed_modules: [puppet_module])
      allow(puppet_module).to receive(:git_service)
        .and_raise(ModuleSync::GitService::MissingCredentialsError, 'missing token')
      expect(described_class).not_to receive(:manage_module)

      expect { described_class.update(pr: true) }
        .to raise_error(ModuleSync::GitService::MissingCredentialsError, 'missing token')
    end
  end

  context '::manage_module' do
    let(:repository) { instance_double(ModuleSync::Repository) }
    let(:settings) { instance_double(ModuleSync::Settings) }
    let(:puppet_module) do
      instance_double(ModuleSync::PuppetModule,
                      given_name: 'puppet-test',
                      repository: repository,
                      repository_name: 'puppet-test',
                      repository_namespace: 'example')
    end

    before do
      described_class.instance_variable_set(:@options, described_class.config_defaults.merge(pr: true))
      allow(repository).to receive_messages(prepare_workspace: nil, submit_changes: false)
      allow(puppet_module).to receive(:path).with(ModuleSync::MODULE_CONF_FILE).and_return('module-config.yml')
      allow(ModuleSync::Util).to receive(:parse_config).with('module-config.yml').and_return({})
      allow(ModuleSync::Settings).to receive(:new).and_return(settings)
      allow(settings).to receive_messages(unmanaged_files: [], managed_files: [])
      allow(puppet_module).to receive(:pull_request_branch_ready?).and_return(true)
    end

    it 'opens a requested PR for an unchanged branch that is ahead of its target' do
      expect(puppet_module).to receive(:open_pull_request)

      described_class.manage_module(puppet_module, [], {})
    end

    it 'requests a rebase before syncing when enabled' do
      described_class.instance_variable_set(:@options, described_class.config_defaults.merge(rebase: true))
      expect(repository).to receive(:prepare_workspace).with(branch: nil, operate_offline: false, rebase: true)

      described_class.manage_module(puppet_module, [], {})
    end

    it 'passes signing options to a release commit and tag' do
      options = described_class.config_defaults.merge(message: 'Update', bump: true, tag: true, sign: true, signoff: true)
      described_class.instance_variable_set(:@options, options)
      allow(repository).to receive(:submit_changes).and_return(true)
      expect(puppet_module).to receive(:bump)
        .with('Update', nil, { sign: true, signoff: true })
        .and_return('1.2.3')
      expect(repository).to receive(:tag).with('1.2.3', '%s', sign: true)

      described_class.manage_module(puppet_module, [], {})
    end
  end
end
