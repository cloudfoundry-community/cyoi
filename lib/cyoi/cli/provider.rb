require "cyoi/cli"
require "cyoi/cli/helpers"
class Cyoi::Cli::Provider
  include Cyoi::Cli::Helpers

  def initialize(argv, stdin=STDIN, stdout=STDOUT, stderr=STDERR, kernel=Kernel)
    @argv, @stdin, @stdout, @stderr, @kernel = argv, stdin, stdout, stderr, kernel
    @settings_dir = File.expand_path(@argv.shift)
  end

  def execute!
    unless valid_infrastructure?
      choose_provider
      settings.provider["region"] = "us-west-2"
      settings.provider["credentials"] = {}
      save_settings!
    end
    @stdout.puts "Confirming: Using #{settings.provider.name}/#{settings.provider.region}"
    @kernel.exit(0)
  end

  protected
  def valid_infrastructure?
    settings.exists?("provider.name") &&
    settings.exists?("provider.region") &&
    settings.exists?("provider.credentials") &&
    settings.provider
  end

  # Prompts user to pick from the supported regions
  def choose_provider
    hl.choose do |menu|
      menu.prompt = "Choose infrastructure:  "
      menu.choice("AWS") do
        settings.provider["name"] = "aws"
      end
      menu.choice("OpenStack") do
        settings.provider["name"] = "openstack"
      end
    end
  end
end