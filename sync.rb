#!/usr/bin/env ruby

require 'erb'
require 'find'
require 'git'
require 'yaml'
require 'optparse'

MODULE_FILES_DIR     = 'moduleroot/'
CONF_FILE    = 'config_defaults.yml'
MODULE_CONF_FILE     = '.sync.yml'
MANAGED_MODULES_CONF = 'managed_modules.yml'

PROJ_ROOT = './modules'

class ForgeModuleFile
  def initialize(configs= {})
    @configs = configs
  end
end

def parse_config(config_file)
  if File.exist?(config_file)
    YAML.load_file(config_file)
  else
    {}
  end
end

def parse_opts(args)
  options = {}
  opt_parser = OptionParser.new do |opts|
    opts.banner = "Usage: sync.rb -m <commit message> [--noop]"
    opts.on('-m', '--message <msg>',
            'Commit message to apply to updated modules') do |msg|
      options[:message] = msg
    end
    opts.on('--noop',
            'No-op mode') do |msg|
      options[:noop] = true
    end
    options[:help] = opts.help
  end.parse!

  options.fetch(:message) do
    if ! options[:noop]
      puts options[:help]
      puts "A commit message is required."
      exit
    end
  end

  options
end

def build(from_erb_template)
  erb_obj = ERB.new(File.read(from_erb_template), nil, '-')
  erb_obj.filename = from_erb_template.chomp('.erb')
  erb_obj.def_method(ForgeModuleFile, 'render()')
  erb_obj
end

def render(template, configs = {})
  ForgeModuleFile.new(configs).render()
end

def sync(template, to_file)
  File.open(to_file, 'w') do |file|
    file.write(template)
  end
end

def pull_repo(name)
  if ! Dir.exists?(PROJ_ROOT)
    Dir.mkdir(PROJ_ROOT)
  end
  # Repo needs to be cloned in the cwd
  if ! Dir.exists?("#{PROJ_ROOT}/#{name}") || ! Dir.exists?("#{PROJ_ROOT}/#{name}/.git")
    puts "Cloning repository fresh"
    repo = Git.clone("git@github.com:puppetlabs/#{name}.git", "#{PROJ_ROOT}/#{name}")
  # Repo already cloned, check out master and override local changes
  else
    puts "Overriding any local changes to repositories in #{PROJ_ROOT}"
    repo = Git.open("#{PROJ_ROOT}/#{name}")
    repo.branch('master').checkout
    repo.reset_hard
    repo.pull
  end
end

def update_repo(name, files, message)
  repo = Git.open("#{PROJ_ROOT}/#{name}")
  # master branch will already be checked out after pull_repo
  repo.add(files)
  begin
    repo.commit(message)
    # TODO: repo.push
  rescue Git::GitExecuteError => git_error
    if git_error.message.include? "nothing to commit, working directory clean"
      puts "There were no files to update in #{name}. Not committing."
    else
      puts git_error
      exit
    end
  end
end

def update_repo_noop(name)
  repo = Git.open("#{PROJ_ROOT}/#{name}")
  repo.branch('master').checkout
  puts "Files changed: "
  repo.diff('HEAD', '--').each do |diff|
    puts diff.patch
  end
  puts "Files added: "
  repo.status.untracked.each do |file,_|
    puts file
  end
end

def local_file(file)
  MODULE_FILES_DIR + file
end

options  = parse_opts(ARGV)
defaults  = parse_config(CONF_FILE)

local_files = Find.find(MODULE_FILES_DIR).collect { |file| file if !File.directory?(file) }.compact
module_files = local_files.map { |file| file.sub(/#{MODULE_FILES_DIR}/, '') }

managed_modules = parse_config(MANAGED_MODULES_CONF)
managed_modules.each do |puppet_module|
  puts "Syncing #{puppet_module}"
  pull_repo(puppet_module)
  module_configs = parse_config("#{PROJ_ROOT}/#{puppet_module}/#{MODULE_CONF_FILE}")
  module_files.each do |file|
    if module_configs[file] && module_configs[file]['unmanaged'] == true
      puts "Not managing #{file} in #{puppet_module}"
    else
      module_configs[file] = defaults[file].merge(module_configs[file] || {}) if defaults[file]
      erb = build(local_file(file))
      template = render(erb, module_configs[file] || {})
      sync(template, "#{PROJ_ROOT}/#{puppet_module}/#{file}")
    end
  end
  if options[:noop]
    puts "Using no-op. Files in #{puppet_module} may be changed but will not be committed."
    update_repo_noop(puppet_module)
  else
    update_repo(puppet_module, module_files, options[:message])
  end
end
