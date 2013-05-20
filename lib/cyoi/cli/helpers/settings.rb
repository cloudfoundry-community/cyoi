require "readwritesettings"
require "fileutils"

module Cyoi::Cli::Helpers::Settings
  include FileUtils

  # The base directory for holding the manifest settings file
  # and private keys
  #
  # Defaults to ~/.bosh_inception; and can be overridden with either:
  # * $SETTINGS - to a folder (supported method)
  def settings_dir
    @settings_dir ||= ENV['SETTINGS'] || raise("please assign @settings_dir or $SETTINGS first")
  end

  def settings_ssh_dir
    File.join(settings_dir, "ssh")
  end

  def settings_path
    @settings_path ||= File.join(settings_dir, "settings.yml")
  end

  def settings
    @settings ||= begin
      unless File.exists?(settings_path)
        mkdir_p(settings_dir)
        File.open(settings_path, "w") { |file| file << "--- {}" }
      end
      chmod(0600, settings_path)
      chmod(0700, settings_ssh_dir) if File.directory?(settings_ssh_dir)
      ReadWriteSettings.new(settings_path)
    end
  end

  # Saves current nested ReadWriteSettings into pure Hash-based YAML file
  # Recreates accessors on ReadWriteSettings object (since something has changed)
  def save_settings!
    File.open(settings_path, "w") { |f| f << settings.to_nested_hash.to_yaml }
    settings.create_accessors!
  end

  def show_settings
    puts "Using settings file #{settings_path}"
  end

  def reload_settings!
    @settings = nil
    settings
  end

  def migrate_old_settings
  end
end
