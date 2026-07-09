# frozen_string_literal: true

require 'spec_helper'

describe ModuleSync::SourceCode do
  subject do
    described_class.new('namespace/name', nil)
  end

  let(:repository) { instance_double(ModuleSync::Repository, default_branch: 'main') }

  before do
    options = ModuleSync.config_defaults.merge({ git_base: 'file:///tmp/dummy' })
    ModuleSync.instance_variable_set :@options, options
    allow(ModuleSync::Repository).to receive(:new).and_return(repository)
  end

  it 'has a repository namespace sets to "namespace"' do
    expect(subject.repository_namespace).to eq 'namespace'
  end

  it 'has a repository name sets to "name"' do
    expect(subject.repository_name).to eq 'name'
  end

  it 'reports a remote source branch ahead of the PR target as ready' do
    ModuleSync.options[:branch] = 'modulesync'
    allow(repository).to receive(:remote_branch_ahead?).with('modulesync', 'main').and_return(true)

    expect(subject.pull_request_branch_ready?).to be true
  end
end
