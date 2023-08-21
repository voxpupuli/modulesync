require 'erb'
require 'find'

module ModuleSync
  module Renderer
    class ForgeModuleFile
      def initialize(configs = {}, metadata = {})
        @configs = configs
        @metadata = metadata
      end
    end

    def self.build(template_file)
      template = File.read(template_file)
      erb_obj = ERB.new(template, trim_mode: '-')
      erb_obj.filename = template_file
      erb_obj.def_method(ForgeModuleFile, 'render()', template_file)
      erb_obj
    end

    def self.remove(file)
      FileUtils.rm_f(file)
    end

    def self.render(_template, configs = {}, metadata = {})
      ForgeModuleFile.new(configs, metadata).render
    end

    def self.sync(template, target_name, mode = nil)
      FileUtils.mkdir_p(File.dirname(target_name))
      File.write(target_name, template)
      File.chmod(mode, target_name) unless mode.nil?
    end
  end
end
