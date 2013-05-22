describe "cyoi key_pair openstack" do
  include Cyoi::Cli::Helpers::Settings
  include SettingsHelper
  include Aruba::Api
  before { @settings_dir = File.expand_path("~/.cyoi_client_lib") }

  it "fails nicely if provider.name missing" do
    run_interactive(unescape("cyoi key_pair testname #{settings_dir}"))
    assert_failing_with("Please run 'cyoi provider' first")
  end

  describe "name & provider setup and" do
    before do
      setting "provider.name", "openstack"
      setting "provider.credentials.openstack_username", "USERNAME"
      setting "provider.credentials.openstack_api_key", "PASSWORD"
      setting "provider.credentials.openstack_tenant", "TENANT"
      setting "provider.credentials.openstack_auth_url", "TOKENURL"
      setting "provider.credentials.openstack_region", "REGION"
      setting "name", "test-bosh"
    end

    it "create new key pair (didn't already exist in OpenStack)" do
      run_interactive(unescape("cyoi key_pair testname #{settings_dir}"))
      assert_passing_with(<<-OUT)
Acquiring a key pair testname... done

Confirming: Using key pair testname
      OUT
    end
  end

end