require "cyoi/cli"
require "cyoi/cli/auto_detection"
require "cyoi/cli/helpers"
class Cyoi::Cli::KeyPair
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
  end
end