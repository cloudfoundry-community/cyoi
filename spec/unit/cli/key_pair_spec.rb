require "fog"
require "cyoi/cli/key_pair"

describe "cyoi key_pair aws" do
  include Cyoi::Cli::Helpers::Settings
  include SettingsHelper
  include Aruba::Api
  before { @settings_dir = File.expand_path("~/.cyoi_client_lib") }
  before { Fog.mock! }
  before do
    setting "provider.name", "aws"
    setting "provider.credentials.aws_access_key_id", "aws_access_key_id"
    setting "provider.credentials.aws_secret_access_key", "aws_secret_access_key"
    setting "provider.region", "us-west-2"
  end

  subject { Cyoi::Cli::KeyPair.new(["test-bosh", settings_dir]) }

  it "create new key pair (didn't already exist in AWS)" do
    subject.execute!
    reload_settings!
    settings.key_pair.name.should == "test-bosh"
    settings.key_pair.fingerprint.should_not be_nil
    settings.key_pair.private_key.should_not be_nil
  end

  xit "create new key pair (already exists on AWS)" do
  end

  xit "existing key pair (matches fingerprint on AWS)" do
  end

  xit "existing key pair (fingerprint mismatch)" do
  end

  xit "existing key pair (doesn't exist on AWS)" do
  end

end