require "cyoi/cli"
require "cyoi/cli/auto_detection"
require "cyoi/cli/helpers"
class Cyoi::Cli::Provider
  include Cyoi::Cli::Helpers

  def initialize(argv, stdin=STDIN, stdout=STDOUT, stderr=STDERR, kernel=Kernel)
    @argv, @stdin, @stdout, @stderr, @kernel = argv, stdin, stdout, stderr, kernel
    @settings_dir = @argv.shift || "/tmp/provider_settings"
    @settings_dir = File.expand_path(@settings_dir)
  end

  def execute!
    unless valid_infrastructure?
      settings["provider"] ||= {}
      auto_detection unless settings.exists?("provider.name")
      choose_provider unless settings.exists?("provider.name")
      settings["provider"] = provider_cli.perform_and_return_attributes
      save_settings!
    end
    provider_cli.display_confirmation
  end

  # Continue the interactive session with the user
  # specific to the provider/infrastructure they have
  # chosen.
  #
  # The returned object is a class from cyoi/cli/providers/provier_cli_NAME.rb
  # The class loads itself into `@provider_clis` via `register_provider_cli`
  #
  # Returns nil if settings.provider.name not set
  def provider_cli
    @provider_cli ||= begin
      return nil unless name = settings.exists?("provider.name")
      require "cyoi/cli/providers/provider_cli_#{settings.provider.name}"
      klass = self.class.provider_cli(settings.provider.name)
      klass.new(settings.provider, hl)
    end
  end

  def self.register_provider_cli(name, klass)
    @provider_clis ||= {}
    @provider_clis[name] = klass
  end

  def self.provider_cli(name)
    @provider_clis[name]
  end

  protected
  def valid_infrastructure?
    provider_cli && provider_cli.valid_infrastructure?
  end

  def auto_detection
    ui = Cyoi::Cli::AutoDetection::UI.new(settings.provider, hl)
    if ui.perform
      settings["provider"] = ui.export_attributes
      save_settings!
    end
  end

  # Prompts user to pick from the supported regions
  def choose_provider
    settings.provider["name"] = hl.choose do |menu|
      menu.prompt = "Choose your infrastructure: "
      menu.choice("AWS") { "aws" }
      menu.choice("OpenStack") { "openstack" }
    end
    save_settings!
  end
end