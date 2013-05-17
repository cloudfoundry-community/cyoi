require "cyoi/cli"
require "cyoi/cli/auto_detection"
require "cyoi/cli/helpers"
class Cyoi::Cli::Address
  include Cyoi::Cli::Helpers

  def initialize(argv, stdin=STDIN, stdout=STDOUT, stderr=STDERR, kernel=Kernel)
    @argv, @stdin, @stdout, @stderr, @kernel = argv, stdin, stdout, stderr, kernel
    @settings_dir = @argv.shift || "/tmp/provider_settings"
    @settings_dir = File.expand_path(@settings_dir)
  end

  def execute!
    unless valid_address?
      settings["address"] = address_cli.perform_and_return_attributes
      save_settings!
    end
    address_cli.display_confirmation
  end

  # Continue the interactive session with the user
  # specific to the address/infrastructure they have
  # chosen.
  #
  # The returned object is a class from cyoi/cli/addresss/provier_cli_NAME.rb
  # The class loads itself into `@address_clis` via `register_address_cli`
  #
  # Returns nil if settings.address.name not set
  def address_cli
    @address_cli ||= begin
      provider_name = settings.exists?("provider.name")
      return nil unless provider_name
      require "cyoi/cli/provider_addresses/address_cli_#{settings.provider.name}"
      klass = self.class.address_cli(settings.provider.name)
      settings["address"] ||= {}
      klass.new(settings.address, hl)
    end
  end

  def self.register_address_cli(name, klass)
    @address_clis ||= {}
    @address_clis[name] = klass
  end

  def self.address_cli(name)
    @address_clis[name]
  end

  protected
  def valid_address?
    address_cli && address_cli.valid_address?
  end

end