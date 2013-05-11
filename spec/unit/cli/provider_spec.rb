require "cyoi/cli/provider"

describe Cyoi::Cli::Provider do
  let(:settings_dir) { "~/.cyoi_client_lib" }
  before { @cli ||= Cyoi::Cli::Provider.new(settings_dir) }
  include SettingsHelper
  include StdoutCapture

  it "provider choices already made" do
    setting "provider.name", "aws"
    setting "provider.credentials.aws_access_key_id", "aws_access_key_id"
    setting "provider.credentials.aws_secret_access_key", "aws_secret_access_key"
    setting "provider.region", "us-west-2"
    output = capture_stdout { cli.perform }
    output.should =~ %r{Confirming: Using aws/us-west-2}
  end
end