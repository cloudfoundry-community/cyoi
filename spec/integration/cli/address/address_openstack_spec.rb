describe "cyoi address openstack" do
  include Cyoi::Cli::Helpers::Settings
  include SettingsHelper
  include Aruba::Api
  before { @settings_dir = File.expand_path("~/.cyoi_client_lib") }

  it "fails nicely if provider.name missing" do
    run_interactive(unescape("cyoi address #{settings_dir}"))
    assert_failing_with("Please run 'cyoi provider' first")
  end

  describe "provider setup and" do
    before do
      setting "provider.name", "openstack"
      setting "provider.credentials.openstack_username", "USERNAME"
      setting "provider.credentials.openstack_api_key", "PASSWORD"
      setting "provider.credentials.openstack_tenant", "TENANT"
      setting "provider.credentials.openstack_auth_url", "TOKENURL"
      setting "provider.credentials.openstack_region", "REGION"
    end

    it "address aleady assigned" do
      skip("Fog::Compute::OpenStack.list_address_pools does not provide a mock test")
      setting "provider.name", "openstack"
      setting "provider.credentials.openstack_username", "USERNAME"
      setting "provider.credentials.openstack_api_key", "PASSWORD"
      setting "provider.credentials.openstack_tenant", "TENANT"
      setting "provider.credentials.openstack_auth_url", "TOKENURL"
      setting "provider.credentials.openstack_region", "REGION"
      setting "address.ip", "1.2.3.4"
      run_interactive(unescape("cyoi address #{settings_dir}"))
      assert_passing_with("Confirming: Using address 1.2.3.4")
    end

    it "address is provisioned from OpenStack" do
      skip("Fog::Compute::OpenStack.list_address_pools does not provide a mock test")
      run_interactive(unescape("cyoi address #{settings_dir}"))
      assert_passing_with("Confirming: Using address")
    end
  end

end
