require "cyoi/cli"
require "cyoi/cli/auto_detection"
require "cyoi/cli/helpers"
class Cyoi::Cli::Blobstore
  include Cyoi::Cli::Helpers

  attr_reader :blobstore_name

  def initialize(argv, stdin=STDIN, stdout=STDOUT, stderr=STDERR, kernel=Kernel)
    @argv, @stdin, @stdout, @stderr, @kernel = argv, stdin, stdout, stderr, kernel
    unless @blobstore_name = @argv.shift
      raise "Please provide blobstore name as first argument"
    end
    @settings_dir = @argv.shift || "/tmp/provider_settings"
    @settings_dir = File.expand_path(@settings_dir)
  end

  # TODO run Cyoi::Cli::Provider first if settings.provider.name missing
  def execute!
    unless settings.exists?("provider.name") && settings.exists?("provider.credentials")
      $stderr.puts("Please run 'cyoi provider' first")
      exit 1
    end

    settings["blobstore"] = perform_and_return_attributes
    save_settings!

    blobstore_cli.display_confirmation
  end

  # Continue the interactive session with the user
  # specific to the infrastructure they have chosen.
  #
  # The returned object is a class from cyoi/cli/provider_blobstore/provier_cli_INFRASTRUCTURE.rb
  # The class loads itself into `@blobstore_clis` via `register_blobstore_cli`
  #
  # Returns nil if settings.key_pair.name not set
  def blobstore_cli
    @blobstore_cli ||= begin
      provider_name = settings.exists?("provider.name")
      return nil unless provider_name
      require "cyoi/cli/provider_blobstore/blobstore_cli_#{settings.provider.name}"

      settings["blobstore"] ||= {}
      settings.blobstore["name"] = blobstore_name

      klass = self.class.blobstore_cli(settings.provider.name)
      klass.new(provider_client, settings.blobstore, hl)
    end
  end

  def perform_and_return_attributes
    blobstore_cli.perform_and_return_attributes
  end

  def self.register_cli(name, klass)
    @blobstore_clis ||= {}
    @blobstore_clis[name] = klass
  end

  def self.blobstore_cli(name)
    @blobstore_clis[name]
  end

end
