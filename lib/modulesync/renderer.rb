require 'erb'
require 'find'

module ModuleSync
  module Renderer
    class ForgeModuleFile
      def initialize(configs = {})
        @configs = configs
      end
    end

    def self.build(target_name)
      template_file = if !File.exist?("#{target_name}.erb") && File.exist?(target_name)
                        STDERR.puts "Warning: using '#{target_name}' as template without '.erb' suffix"
                        target_name
                      else
                        "#{target_name}.erb"
                      end
      erb_obj = ERB.new(File.read(template_file), nil, '-')
      erb_obj.filename = template_file
      erb_obj.def_method(ForgeModuleFile, 'render()', template_file)
      erb_obj
    end

    def self.remove(file)
      File.delete(file) if File.exist?(file)
    end

    def self.render(_template, configs = {})
      ForgeModuleFile.new(configs).render
    end

    def self.sync(template, target_name, mode)
      path = target_name.rpartition('/').first
      FileUtils.mkdir_p(path) unless path.empty?
      File.open(target_name, 'w') do |file|
        file.write(template)
      end
      File.chmod(mode, target_name)
    end
  end
end
