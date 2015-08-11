module ModuleSync
  class FileNotFound < StandardError; end
  class ParseError < StandardError; end

  def self.validate_hooks(hooks, project_root)
    valid_hooks = {}
    hooks.each do |k, v|
      next unless k.match(/pre_(commit|push)/) # Skip the unimplemented hooks
      script_path = File.join(project_root, v)
      fail FileNotFound, "No #{k} script found at #{script_path}" unless File.exist?(script_path)
      fail "The script #{v} is not executable" unless File.executable?(script_path)
      valid_hooks[k] = script_path
    end
    return valid_hooks
  end
end
