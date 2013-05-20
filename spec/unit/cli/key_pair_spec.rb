require "fog"
require "cyoi/cli/key_pair"

describe "cyoi key_pair aws" do
  include Cyoi::Cli::Helpers::Settings
  include SettingsHelper
  include StdoutCapture
  include Aruba::Api
  before { @settings_dir = File.expand_path("~/.cyoi_client_lib") }
  before { Fog.mock!; Fog::Mock.reset }
  before do
    setting "provider.name", "aws"
    setting "provider.credentials.aws_access_key_id", "aws_access_key_id"
    setting "provider.credentials.aws_secret_access_key", "aws_secret_access_key"
    setting "provider.region", "us-west-2"
  end

  subject { Cyoi::Cli::KeyPair.new(["test-bosh", settings_dir]) }

  let(:fog_compute) { subject.key_pair_cli.provider_client.fog_compute }

  it "creates new key pair if not already valid in settings" do
    capture_stdout { subject.execute! }
    reload_settings!
    settings.key_pair.name.should == "test-bosh"
    settings.key_pair.fingerprint.should_not be_nil
    settings.key_pair.private_key.should_not be_nil
  end

  it "creates new key pair, first destroying existing key pair of same name" do
    old_key = fog_compute.key_pairs.create(name: "test-bosh")
    capture_stdout { subject.execute! }
    reload_settings!
    settings.key_pair.name.should == "test-bosh"
    settings.key_pair.fingerprint.should_not be_nil
    settings.key_pair.private_key.should_not be_nil

    new_key = fog_compute.key_pairs.get("test-bosh")
    settings.key_pair.fingerprint.should == new_key.fingerprint
    settings.key_pair.fingerprint.should_not == old_key.fingerprint
  end

  it "does nothing if key pair already in settings and matches fingerprint with AWS" do
    capture_stdout { subject.execute! }
    reload_settings!
    fingerprint = settings.key_pair.fingerprint

    capture_stdout { subject.execute! }
    reload_settings!
    settings.key_pair.fingerprint.should == fingerprint
  end

  it "recreates key pair if fingerprint mismatch" do
    old_key = fog_compute.key_pairs.create(name: "test-bosh")
    capture_stdout { subject.execute! }
    reload_settings!

    setting "key_pair.fingerprint", "xxxx"
    capture_stdout { subject.execute! }
    reload_settings!

    new_key = fog_compute.key_pairs.get("test-bosh")
    settings.key_pair.fingerprint.should_not == "xxxx"
    settings.key_pair.fingerprint.should_not == old_key.fingerprint
    settings.key_pair.fingerprint.should == new_key.fingerprint
  end

  it "recreates key pair if there is no record of key pair with AWS" do
    setting "key_pair.name", "test-bosh"
    setting "key_pair.fingerprint", "xxxx"
    capture_stdout { subject.execute! }
    reload_settings!

    new_key = fog_compute.key_pairs.get("test-bosh")
    settings.key_pair.fingerprint.should_not == "xxxx"
    settings.key_pair.fingerprint.should == new_key.fingerprint
  end

end