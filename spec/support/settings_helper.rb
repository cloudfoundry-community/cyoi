# assumes @cmd is Inception::Cli instance
module SettingsHelper
  attr_reader :cli

  # Set a nested setting with "key1.key2.key3" notation
  def setting(nested_key, value)
    settings.set(nested_key, value)
  end

  # used by +SettingsSetter+ to access the settings
  def settings
    cli.settings
  end
end