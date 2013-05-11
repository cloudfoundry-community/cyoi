require "cyoi/cli/provider"

describe Cyoi::Cli::Provider do
  include Cyoi::Cli::Helpers::Settings
  include SettingsHelper
  include Aruba::Api
  before { @settings_dir = File.expand_path("~/.cyoi_client_lib") }
  it "provider choices already made" do
    setting "provider.name", "aws"
    setting "provider.credentials.aws_access_key_id", "aws_access_key_id"
    setting "provider.credentials.aws_secret_access_key", "aws_secret_access_key"
    setting "provider.region", "us-west-2"
    run_interactive(unescape("cyoi #{settings_dir}"))
    assert_passing_with("Confirming: Using aws/us-west-2")
  end

  it "prompts for provider, user chooses aws" do
    run_interactive(unescape("cyoi #{settings_dir}"))
    assert_passing_with("Confirming: Using aws/us-west-2")
  end
end