require "cyoi/cli"
require "cyoi/cli/helpers"
class Cyoi::Cli::Provider
  include Cyoi::Cli::Helpers::Settings
  def initialize(argv, stdin=STDIN, stdout=STDOUT, stderr=STDERR, kernel=Kernel)
    @argv, @stdin, @stdout, @stderr, @kernel = argv, stdin, stdout, stderr, kernel
    @settings_dir = File.expand_path(@argv.shift)
  end

  def execute!
    @stdout.puts "Confirming: Using aws/us-west-2"
    @kernel.exit(0)
  end
end