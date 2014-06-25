require "cyoi/cli"
require "cyoi/cli/auto_detection"
require "cyoi/cli/helpers"
class Cyoi::Cli::KeyPair
  include Cyoi::Cli::Helpers

  attr_reader :key_pair_name

  def initialize(argv, stdin=STDIN, stdout=STDOUT, stderr=STDERR, kernel=Kernel)
    @argv, @stdin, @stdout, @stderr, @kernel = argv, stdin, stdout, stderr, kernel
    unless @key_pair_name = @argv.shift
      raise "Please provide key pair name as first argument"
    end
    @settings_dir = @argv.shift || "/tmp/provider_settings"
    @settings_dir = File.expand_path(@settings_dir)
  end

  # TODO run Cyoi::Cli::Provider first if settings.provider.name missing
  def execute!
    unless settings.exists?("provider.name")
      $stderr.puts("Please run 'cyoi provider' first")
      exit 1
    end
    unless valid?
      settings["key_pair"] = key_pair_cli.perform_and_return_attributes
    end
    save_settings!
    key_pair_cli.display_confirmation
  end

  # Continue the interactive session with the user
  # specific to the key_pair/infrastructure they have
  # chosen.
  #
  # The returned object is a class from cyoi/cli/key_pairs/provier_cli_NAME.rb
  # The class loads itself into `@key_pair_clis` via `register_key_pair_cli`
  #
  # Returns nil if settings.key_pair.name not set
  def key_pair_cli
    @key_pair_cli ||= begin
      provider_name = settings.exists?("provider.name")
      return nil unless provider_name
      require "cyoi/cli/provider_key_pair/key_pair_#{settings.provider.name}"

      settings["key_pair"] ||= {}
      settings.key_pair["name"] = key_pair_name

      klass = self.class.key_pair_cli(settings.provider.name)
      klass.new(provider_client, settings.key_pair, hl)
    end
  end

  def self.register_key_pair_cli(name, klass)
    @key_pair_clis ||= {}
    @key_pair_clis[name] = klass
  end

  def self.key_pair_cli(name)
    @key_pair_clis[name]
  end

  protected
  def valid?
    key_pair_cli && key_pair_cli.valid?
  end
end
