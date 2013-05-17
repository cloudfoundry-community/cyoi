describe "cyoi address aws" do
  include Cyoi::Cli::Helpers::Settings
  include SettingsHelper
  include Aruba::Api
  before { @settings_dir = File.expand_path("~/.cyoi_client_lib") }

  it "fails nicely if provider.name missing" do
    run_interactive(unescape("cyoi address #{settings_dir}"))
    assert_failing_with("Please run 'cyoi provider' first")
  end

  it "provider choices already made" do
    setting "provider.name", "aws"
    setting "provider.credentials.aws_access_key_id", "aws_access_key_id"
    setting "provider.credentials.aws_secret_access_key", "aws_secret_access_key"
    setting "provider.region", "us-west-2"
    setting "address.ip", "1.2.3.4"
    run_interactive(unescape("cyoi address #{settings_dir}"))
    assert_passing_with("Confirming: Using address 1.2.3.4")
  end
end