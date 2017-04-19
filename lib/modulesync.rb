require 'fileutils'
require 'pathname'
require 'modulesync/cli'
require 'modulesync/constants'
require 'modulesync/git'
require 'modulesync/hook'
require 'modulesync/renderer'
require 'modulesync/settings'
require 'modulesync/util'
require 'monkey_patches'

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
      local_files = Find.find(path).collect { |file| file unless File.directory?(file) }.compact
    else
      puts "#{path} does not exist. Check that you are working in your module configs directory or that you have passed in the correct directory with -c."
      exit
    end
  end

  def self.module_files(local_files, path)
    local_files.map { |file| file.sub(/#{path}/, '') }
  end

  def self.managed_modules(path, filter, negative_filter)
    managed_modules = Util.parse_config(path)
    if managed_modules.empty?
      puts "No modules found at #{path}. Check that you specified the right configs directory containing managed_modules.yml."
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
      rescue
        STDERR.puts "Error while rendering #{filename}"
        raise
      end
    end
  end

  def self.manage_module(puppet_module, module_files, module_options, defaults, options)
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
      Git.update(module_name, files_to_manage, options)
    end
  end

  def self.update(options)
    options = config_defaults.merge(options)
    defaults = Util.parse_config("#{options[:configs]}/#{CONF_FILE}")

    path = "#{options[:configs]}/#{MODULE_FILES_DIR}"
    local_files = self.local_files(path)
    module_files = self.module_files(local_files, path)

    managed_modules = self.managed_modules("#{options[:configs]}/managed_modules.yml", options[:filter], options[:negative_filter])

    # managed_modules is either an array or a hash
    managed_modules.each do |puppet_module, module_options|
      begin
        manage_module(puppet_module, module_files, module_options, defaults, options)
      rescue
        STDERR.puts "Error while updating #{puppet_module}"
        raise unless options[:skip_broken]
        puts "Skipping #{puppet_module} as update process failed"
      end
    end
  end
end
