require "cyoi/cli"
require "cyoi/cli/helpers"
class Cyoi::Cli::Provider
  include Cyoi::Cli::Helpers::Settings
  def initialize(settings_dir)
    @settings_dir = File.expand_path(settings_dir)
  end

  def perform
    puts "Confirming: Using aws/us-west-2"
  end
end