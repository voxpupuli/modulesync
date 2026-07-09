# frozen_string_literal: true

require 'spec_helper'

describe ModuleSync::Repository do
  subject(:repository) do
    described_class.new(directory: '/tmp/example', remote: 'https://github.com/example/repository.git')
  end

  let(:remote_branches) do
    [
      instance_double(Git::Branch, name: 'main'),
      instance_double(Git::Branch, name: 'modulesync'),
    ]
  end
  let(:branches) { instance_double(Git::Branches, remote: remote_branches) }
  let(:log) { instance_double(Git::Log) }
  let(:git) { instance_double(Git::Base, branches: branches, log: log) }

  before do
    repository.instance_variable_set(:@git, git)
  end

  it 'detects commits on a remote source branch that are missing from the target branch' do
    allow(log).to receive(:between).with('origin/main', 'origin/modulesync').and_return(log)
    allow(log).to receive(:execute).and_return([instance_double(Git::Object::Commit)])

    expect(repository.remote_branch_ahead?('modulesync', 'main')).to be true
  end

  it 'rejects a source branch that does not exist remotely' do
    remote_branches.pop

    expect(repository.remote_branch_ahead?('modulesync', 'main')).to be false
  end
end
