# frozen_string_literal: true

require 'puppet_blacksmith'

require 'modulesync/source_code'

module ModuleSync
  # Provide methods to manipulate puppet module code
  class PuppetModule < SourceCode
    def update_changelog(version, message)
      changelog = path('CHANGELOG.md')
      if File.exist?(changelog)
        puts "Updating #{changelog} for version #{version}"
        changes = File.readlines(changelog)
        File.open(changelog, 'w') do |f|
          date = Time.now.strftime('%Y-%m-%d')
          f.puts "## #{date} - Release #{version}\n\n"
          f.puts "#{message}\n\n"
          # Add old lines again
          f.puts changes
        end
        repository.git.add('CHANGELOG.md')
      else
        puts 'No CHANGELOG.md file found, not updating.'
      end
    end

    def bump(message, changelog = false)
      m = Blacksmith::Modulefile.new path('metadata.json')
      new = m.bump!
      puts "Bumped to version #{new}"
      repository.git.add('metadata.json')
      update_changelog(new, message) if changelog
      repository.git.commit("Release version #{new}")
      repository.git.push
      new
    end
  end
end
