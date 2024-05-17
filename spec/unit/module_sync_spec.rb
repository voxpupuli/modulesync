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
  end
end
