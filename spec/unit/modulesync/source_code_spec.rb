require 'spec_helper'

describe ModuleSync::SourceCode do
  before do
    options = ModuleSync.config_defaults.merge({
      git_base: 'file:///tmp/dummy',
    })
    ModuleSync.instance_variable_set '@options', options
  end

  subject do
    ModuleSync::SourceCode.new('namespace/name', nil)
  end

  it 'has a repository namespace sets to "namespace"' do
    expect(subject.repository_namespace).to eq 'namespace'
  end

  it 'has a repository name sets to "name"' do
    expect(subject.repository_name).to eq 'name'
  end
end
