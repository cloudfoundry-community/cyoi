# assumes @cmd is Cyoi::Cli instance
module SettingsHelper
  # Set a nested setting with "key1.key2.key3" notation
  def setting(nested_key, value)
    settings.set(nested_key, value)
    save_settings!
  end

end