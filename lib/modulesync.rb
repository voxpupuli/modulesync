require 'fileutils'
require 'octokit'
require 'pathname'
require 'modulesync/cli'
require 'modulesync/constants'
require 'modulesync/git'
require 'modulesync/hook'
require 'modulesync/renderer'
require 'modulesync/settings'
require 'modulesync/util'
require 'monkey_patches'

GITHUB_TOKEN = ENV.fetch('GITHUB_TOKEN', '')
GITHUB_ORGANIZATION = ENV.fetch('GITHUB_ORGANIZATION', '')

Octokit.configure do |c|
  c.api_endpoint = ENV.fetch('GITHUB_BASE_URL', 'https://api.github.com')
  c.auto_paginate = true

  # We use a different Accept header by default here so we can get access
  # to the developer's preview that enables repository topics.
  c.default_media_type = ::Octokit::Preview::PREVIEW_TYPES[:topics]
end

GITHUB = Octokit::Client.new(:access_token => GITHUB_TOKEN)

module ModuleSync
  include Constants

  def self.config_defaults
    {
      :project_root         => 'modules/',
      :managed_modules_conf => 'managed_modules.yml',
      :configs              => '.',
      :tag_pattern          => '%s'
    }
  end

  def self.local_file(config_path, file)
    "#{config_path}/#{MODULE_FILES_DIR}/#{file}"
  end

  def self.module_file(project_root, puppet_module, file)
    "#{project_root}/#{puppet_module}/#{file}"
  end

  def self.local_files(path)
    if File.exist?(path)
      # only select *.erb files, and strip the extension. This way all the code will only have to handle bare paths, except when reading the actual ERB text
      local_files = Find.find(path).find_all { |p| p =~ /.erb$/ && !File.directory?(p) }.collect { |p| p.chomp('.erb') }.to_a
    else
      puts "#{path} does not exist. Check that you are working in your module configs directory or that you have passed in the correct directory with -c."
      exit
    end
  end

  def self.module_files(local_files, path)
    local_files.map { |file| file.sub(/#{path}/, '') }
  end

  def self.managed_modules(config_file, filter, negative_filter, topic)
    if topic
      managed_modules = []
      GITHUB.org_repos(GITHUB_ORGANIZATION).each do |repo|
        managed_modules.push(repo.name) if repo.topics.include?(topic)
      end
    else
      managed_modules = Util.parse_config(config_file)
    end

    if managed_modules.empty?
      puts "No modules found in #{config_file}. Check that you specified the right :configs directory and :managed_modules_conf file."
      exit
    end
    managed_modules.select! { |m| m =~ Regexp.new(filter) } unless filter.nil?
    managed_modules.reject! { |m| m =~ Regexp.new(negative_filter) } unless negative_filter.nil?
    managed_modules
  end

  def self.module_name(module_name, default_namespace)
    return [default_namespace, module_name] unless module_name.include?('/')
    ns, mod = module_name.split('/')
  end

  def self.hook(options)
    hook = Hook.new(HOOK_FILE, options)

    case options[:hook]
    when 'activate'
      hook.activate
    when 'deactivate'
      hook.deactivate
    end
  end

  def self.manage_file(filename, settings, options)
    module_name = settings.additional_settings[:puppet_module]
    configs = settings.build_file_configs(filename)
    if configs['delete']
      Renderer.remove(module_file(options[:project_root], module_name, filename))
    else
      templatename = local_file(options[:configs], filename)
      begin
        erb = Renderer.build(templatename)
        template = Renderer.render(erb, configs)
        Renderer.sync(template, module_file(options[:project_root], module_name, filename))
      rescue # rubocop:disable Lint/RescueWithoutErrorClass
        STDERR.puts "Error while rendering #{filename}"
        raise
      end
    end
  end

  def self.manage_module(puppet_module, module_files, module_options, defaults, options)
    if options[:pr] && !GITHUB_TOKEN
      STDERR.puts 'Environment variable GITHUB_TOKEN must be set to use --pr!'
      raise unless options[:skip_broken]
    end

    puts "Syncing #{puppet_module}"
    namespace, module_name = module_name(puppet_module, options[:namespace])
    unless options[:offline]
      git_base = options[:git_base]
      git_uri = "#{git_base}#{namespace}"
      Git.pull(git_uri, module_name, options[:branch], options[:project_root], module_options || {})
    end
    module_configs = Util.parse_config("#{options[:project_root]}/#{module_name}/#{MODULE_CONF_FILE}")
    settings = Settings.new(defaults[GLOBAL_DEFAULTS_KEY] || {},
                            defaults,
                            module_configs[GLOBAL_DEFAULTS_KEY] || {},
                            module_configs,
                            :puppet_module => module_name,
                            :git_base => git_base,
                            :namespace => namespace)
    settings.unmanaged_files(module_files).each do |filename|
      puts "Not managing #{filename} in #{module_name}"
    end

    files_to_manage = settings.managed_files(module_files)
    files_to_manage.each { |filename| manage_file(filename, settings, options) }

    if options[:noop]
      Git.update_noop(module_name, options)
    elsif !options[:offline]
      # Git.update() returns a boolean: true if files were pushed, false if not.
      pushed = Git.update(module_name, files_to_manage, options)
      return nil unless pushed && options[:pr]

      # We only do GitHub PR work if the GITHUB_TOKEN variable is set in the environment.
      repo_path = "#{namespace}/#{module_name}"
      puts "Submitting PR '#{options[:pr_title]}' on GitHub to #{repo_path} - merges #{options[:branch]} into master"
      pr = GITHUB.create_pull_request(repo_path, 'master', options[:branch], options[:pr_title], options[:message])
      puts "PR created at #{pr['html_url']}"

      # PR labels can either be a list in the YAML file or they can pass in a comma
      # separated list via the command line argument.
      pr_labels = Util.parse_list(options[:pr_labels])

      # We only assign labels to the PR if we've discovered a list > 1. The labels MUST
      # already exist. We DO NOT create missing labels.
      unless pr_labels.empty?
        puts "Attaching the following labels to PR #{pr['number']}: #{pr_labels.join(', ')}"
        GITHUB.add_labels_to_an_issue(repo_path, pr['number'], pr_labels)
      end
    end
  end

  def self.update(options)
    options = config_defaults.merge(options)
    defaults = Util.parse_config("#{options[:configs]}/#{CONF_FILE}")

    path = "#{options[:configs]}/#{MODULE_FILES_DIR}"
    local_files = self.local_files(path)
    module_files = self.module_files(local_files, path)

    managed_modules = self.managed_modules("#{options[:configs]}/#{options[:managed_modules_conf]}", options[:filter], options[:negative_filter], options[:topic])

    errors = false
    # managed_modules is either an array or a hash
    managed_modules.each do |puppet_module, module_options|
      begin
        manage_module(puppet_module, module_files, module_options, defaults, options)
      rescue # rubocop:disable Lint/RescueWithoutErrorClass
        STDERR.puts "Error while updating #{puppet_module}"
        raise unless options[:skip_broken]
        errors = true
        puts "Skipping #{puppet_module} as update process failed"
      end
    end
    exit 1 if errors && options[:fail_on_warnings]
  end
end
