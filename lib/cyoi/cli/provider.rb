require "cyoi/cli"
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
      choose_provider_if_necessary
      settings["provider"] = provider_cli.perform_and_return_attributes
      save_settings!
    end
    @stdout.puts "Confirming: Using #{settings.provider.name}/#{settings.provider.region}"
    @kernel.exit(0)
  end

  # Continue the interactive session with the user
  # specific to the provider/infrastructure they have
  # chosen.
  #
  # The returned object is a class from cyoi/cli/providers/provier_cli_NAME.rb
  # The class loads itself into `@provider_clis` via `register_provider_cli`
  def provider_cli
    @provider_cli ||= begin
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
    settings.exists?("provider.name") &&
    settings.exists?("provider.region") &&
    settings.exists?("provider.credentials") &&
    settings.provider
  end

  # Prompts user to pick from the supported regions
  def choose_provider_if_necessary
    hl.choose do |menu|
      menu.prompt = "Choose your infrastructure: "
      menu.choice("AWS") do
        settings.provider["name"] = "aws"
      end
      menu.choice("OpenStack") do
        settings.provider["name"] = "openstack"
      end
    end
  end
end