require 'fileutils'
require 'modulesync/cli'
require 'modulesync/git'
require 'modulesync/hook'
require 'modulesync/renderer'
require 'modulesync/util'
require 'modulesync/config'

module ModuleSync
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

  def self.managed_modules(path, filter)
    managed_modules = Util.parse_config(path)
    if managed_modules.empty?
      puts "No modules found at #{path}. Check that you specified the right configs directory containing managed_modules.yml."
      exit
    end
    managed_modules.select! { |m| m =~ Regexp.new(filter) } unless filter.nil?
    managed_modules
  end

  def self.module_name(module_name, default_namespace)
    return [default_namespace, module_name] unless module_name.include?('/')
    ns, mod = module_name.split('/')
  end

  def self.hook(config)
    hook = Hook.new(config[:hook_file], config)

    case config[:hook]
    when 'activate'
      hook.activate
    when 'deactivate'
      hook.deactivate
    end
  end

  def self.update(config)
    defaults = Util.parse_config(config[:defaults_file])

    path = config[:moduleroot_dir]
    local_files = self.local_files(path)
    module_files = self.module_files(local_files, path)

    managed_modules = self.managed_modules(config[:managed_modules_file], config[:filter])

    # managed_modules is either an array or a hash
    managed_modules.each do |puppet_module, opts|
      puts "Syncing #{puppet_module}"
      namespace, module_name = self.module_name(puppet_module, config[:namespace])
      unless config[:offline]
        git_base = "#{config[:git_base]}#{namespace}"
        Git.pull(git_base, module_name, config[:branch], config[:modules_dir], opts || {})
      end
      module_configs = Util.parse_config("#{config[:modules_dir]}/#{module_name}/#{config[:module_conf_file]}")
      global_defaults_key = config[:global_defaults_key]
      global_defaults = defaults[global_defaults_key] || {}
      module_defaults = module_configs[global_defaults_key] || {}
      files_to_manage = (module_files | defaults.keys | module_configs.keys) - [global_defaults_key]
      files_to_delete = []
      files_to_manage.each do |file|
        file_configs = global_defaults.merge(defaults[file] || {}).merge(module_defaults).merge(module_configs[file] || {})
        file_configs[:puppet_module] = module_name
        if file_configs['unmanaged']
          puts "Not managing #{file} in #{module_name}"
          files_to_delete << file
        elsif file_configs['delete']
          Renderer.remove(File.join(config[:modules_dir], module_name, file))
        else
          erb = Renderer.build(File.join(config[:moduleroot_dir], file))
          template = Renderer.render(erb, file_configs)
          Renderer.sync(template, File.join(config[:modules_dir], module_name, file))
        end
      end
      files_to_manage -= files_to_delete
      if config[:noop]
        Git.update_noop(module_name, config)
      elsif !config[:offline]
        Git.update(module_name, files_to_manage, config)
      end
    end
  end
end
