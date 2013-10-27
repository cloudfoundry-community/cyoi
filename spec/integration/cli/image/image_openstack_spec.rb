describe "cyoi image openstack" do
  include Cyoi::Cli::Helpers::Settings
  include SettingsHelper
  include Aruba::Api
  before { @settings_dir = File.expand_path("~/.cyoi_client_lib") }

  it "provider choices already made" do
    setting "provider.name", "openstack"
    setting "provider.credentials.openstack_username", "username"
    setting "provider.credentials.openstack_api_key", "password"
    setting "provider.credentials.openstack_tenant", "tenant"
    setting "provider.credentials.openstack_auth_url", "http://1.2.3.4:5000/v2.0/tokens"
    setting "provider.credentials.openstack_region", ""

    run_interactive(unescape("cyoi image #{settings_dir}"))
    type("1")
    assert_passing_with(<<-OUT)
1. cirros-0.3.0-x86_64-blank
Choose image: 
Confirming: Using image 0e09fbd6-43c5-448a-83e9-0d3d05f9747e
    OUT

    reload_settings!
    settings.image.to_nested_hash.should == {
      "image_id" => "0e09fbd6-43c5-448a-83e9-0d3d05f9747e"
    }
  end
end
