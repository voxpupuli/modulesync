require 'spec_helper'

describe ModuleSync::Settings do
  subject do
    described_class.new(
      {},
      {},
      {},
      { 'Rakefile' => { 'unmanaged' => true },
        :global => { 'global' => 'value' },
        'Gemfile' => { 'key' => 'value' }, },
      {},
    )
  end

  it { is_expected.not_to eq nil }
  it { expect(subject.managed?('Rakefile')).to eq false }
  it { expect(subject.managed?('Rakefile/foo')).to eq false }
  it { expect(subject.managed?('Gemfile')).to eq true }
  it { expect(subject.managed?('Gemfile/foo')).to eq true }
  it { expect(subject.managed_files([])).to eq ['Gemfile'] }
  it { expect(subject.managed_files(%w[Rakefile Gemfile other_file])).to eq %w[Gemfile other_file] }
  it { expect(subject.unmanaged_files([])).to eq ['Rakefile'] }
  it { expect(subject.unmanaged_files(%w[Rakefile Gemfile other_file])).to eq ['Rakefile'] }
end
