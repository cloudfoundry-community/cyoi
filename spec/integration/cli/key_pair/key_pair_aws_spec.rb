describe "cyoi key_pair aws" do
  include Cyoi::Cli::Helpers::Settings
  include SettingsHelper
  include Aruba::Api
  before { @settings_dir = File.expand_path("~/.cyoi_client_lib") }

  it "fails nicely if provider.name missing" do
    run_interactive(unescape("cyoi key_pair #{settings_dir}"))
    assert_failing_with("Please run 'cyoi provider' first")
  end

  describe "name & provider setup and" do
    before do
      setting "provider.name", "aws"
      setting "provider.credentials.aws_access_key_id", "aws_access_key_id"
      setting "provider.credentials.aws_secret_access_key", "aws_secret_access_key"
      setting "provider.region", "us-west-2"
      setting "name", "test-bosh"
    end

    it "create new key pair (didn't already exist in AWS)" do
      assert_passing_with(<<-OUT)
Provisioning new key pair microbosh-test-bosh... done

Confirm: Using key pair microbosh-test-bosh
      OUT
    end
  end

end