class Cyoi::Cli::Image
  include Cyoi::Cli::Helpers

  def initialize(argv, stdin=STDIN, stdout=STDOUT, stderr=STDERR, kernel=Kernel)
    @argv, @stdin, @stdout, @stderr, @kernel = argv, stdin, stdout, stderr, kernel
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
      settings["image"] = image_cli.perform_and_return_attributes
    end
    save_settings!
    image_cli.display_confirmation
  end

  # Continue the interactive session with the user
  # specific to the infrastructure they have chosen.
  #
  # The returned object is a class from cyoi/cli/provider_image/provier_cli_INFRASTRUCTURE.rb
  # The class loads itself into `@image_clis` via `register_image_cli`
  #
  # Returns nil if settings.key_pair.name not set
  def image_cli
    @image_cli ||= begin
      provider_name = settings.exists?("provider.name")
      return nil unless provider_name
      require "cyoi/cli/provider_image/image_#{settings.provider.name}"
      settings["image"] ||= {}
      klass = self.class.image_cli(settings.provider.name)
      klass.new(provider_client, settings.image, hl)
    end
  end

  def self.register_image_cli(name, klass)
    @image_clis ||= {}
    @image_clis[name] = klass
  end

  def self.image_cli(name)
    @image_clis[name]
  end

  protected
  def valid?
    settings["image"] && settings["image"]["image_id"]
  end
end