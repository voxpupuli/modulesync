require 'erb'
require 'fileutils'
require 'modulesync'

module ModuleSync
  class ModuleFile
    attr_reader :template, :configs, :destination

    def initialize(mod, file)
      @destination = File.join(mod.path, file)
      @template_name = file
      @template = File.join(mod.project.moduleroot.path, file)
      @configs = mod.configs[file] || {}
    end

    def output
      render_erb
    end

    def delete!
      File.delete(destination) if File.exist?(destination)
    end

    def render_erb
      if File.exist?(template)
        erb = ERB.new(File.read(template), nil, '-')
        erb.filename = @template_name.chomp('.erb')
        erb.def_method(ModuleFile, 'render()')
        begin
          render
        rescue StandardError => e
          raise ParseError, "Could not parse ERB template: #{File.expand_path template}: #{e}"
        end
      else
        warn "Was asked to manage #{File.basename(template)}, but couldn't find a template."
      end
    end

    def write
      parent_dir = destination.rpartition('/').first
      FileUtils.mkdir_p(parent_dir) unless File.exist?(parent_dir)
      File.open(destination, 'w') do |f|
        f.write output
      end
      return destination
    end
  end
end
