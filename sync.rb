#!/usr/bin/env ruby

require 'erb'
require 'find'
require 'git'
require 'yaml'
require 'optparse'

MODULE_FILES_DIR     = 'moduleroot/'
CONF_FILE            = 'config_defaults.yml'
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
  options[:remote] = 'git@github.com:puppetlabs/'
  opt_parser = OptionParser.new do |opts|
    opts.banner = "Usage: sync.rb -m <commit message> [--noop]"
    opts.on('-m', '--message <msg>',
            'Commit message to apply to updated modules') do |msg|
      options[:message] = msg
    end
    opts.on('-r', '--remote <url>',
            'Remote github namespace to clone from and push to. Defaults to git@github.com:puppetlabs/') do |remote|
      options[:remote] = remote
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

def remove(file)
  if File.exists?(file)
    File.delete(file)
  end
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

def pull_repo(org, name)
  if ! Dir.exists?(PROJ_ROOT)
    Dir.mkdir(PROJ_ROOT)
  end
  # Repo needs to be cloned in the cwd
  if ! Dir.exists?("#{PROJ_ROOT}/#{name}") || ! Dir.exists?("#{PROJ_ROOT}/#{name}/.git")
    puts "Cloning repository fresh"
    repo = Git.clone("#{org}/#{name}.git", "#{PROJ_ROOT}/#{name}")
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
  files.each do |file|
    if repo.status.deleted.include?(file)
      repo.remove(file)
    else
      repo.add(file)
    end
  end
  begin
    repo.commit(message)
    repo.push
  rescue Git::GitExecuteError => git_error
    if git_error.message.include? "nothing to commit, working directory clean"
      puts "There were no files to update in #{name}. Not committing."
    else
      puts git_error
      exit
    end
  end
end

# Needed because of a bug in the git gem that lists ignored files as untracked under some circumstances
# https://github.com/schacon/ruby-git/issues/130
def untracked_unignored_files(repo)
  ignored = File.open("#{repo.dir.path}/.gitignore").read.split
  repo.status.untracked.keep_if{|f,_| !ignored.any?{|i| f.match(/#{i}/)}}
end

def update_repo_noop(name)
  repo = Git.open("#{PROJ_ROOT}/#{name}")
  repo.branch('master').checkout
  puts "Files changed: "
  repo.diff('HEAD', '--').each do |diff|
    puts diff.patch
  end
  puts "Files added: "
  untracked_unignored_files(repo).each do |file,_|
    puts file
  end
end

def local_file(file)
  MODULE_FILES_DIR + file
end

def module_file(puppet_module, file)
  "#{PROJ_ROOT}/#{puppet_module}/#{file}"
end

options  = parse_opts(ARGV)
defaults  = parse_config(CONF_FILE)

local_files = Find.find(MODULE_FILES_DIR).collect { |file| file if !File.directory?(file) }.compact
module_files = local_files.map { |file| file.sub(/#{MODULE_FILES_DIR}/, '') }

managed_modules = parse_config(MANAGED_MODULES_CONF)
managed_modules.each do |puppet_module|
  puts "Syncing #{puppet_module}"
  pull_repo(options[:remote], puppet_module)
  module_configs = parse_config("#{PROJ_ROOT}/#{puppet_module}/#{MODULE_CONF_FILE}")
  files_to_manage = module_files | defaults.keys | module_configs.keys
  files_to_manage.each do |file|
    file_configs = (defaults[file] || {}).merge(module_configs[file] || {})
    if file_configs['unmanaged']
      puts "Not managing #{file} in #{puppet_module}"
    elsif file_configs['delete']
      remove(module_file(puppet_module, file))
    else
      erb = build(local_file(file))
      template = render(erb, file_configs)
      sync(template, "#{PROJ_ROOT}/#{puppet_module}/#{file}")
    end
  end
  if options[:noop]
    puts "Using no-op. Files in #{puppet_module} may be changed but will not be committed."
    update_repo_noop(puppet_module)
    puts "\n\n"
    puts '--------------------------------'
  else
    update_repo(puppet_module, files_to_manage, options[:message])
  end
end
