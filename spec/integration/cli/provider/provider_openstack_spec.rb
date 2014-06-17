describe "cyoi provider openstack" do
  include Cyoi::Cli::Helpers::Settings
  include SettingsHelper
  include Aruba::Api
  before { @settings_dir = File.expand_path("~/.cyoi_client_lib") }

  it "provider choices already made" do
    setting "provider.name", "openstack"
    setting "provider.credentials.openstack_username", "USERNAME"
    setting "provider.credentials.openstack_api_key", "PASSWORD"
    setting "provider.credentials.openstack_tenant", "TENANT"
    setting "provider.credentials.openstack_auth_url", "TOKENURL"
    setting "provider.credentials.openstack_region", "REGION"
    setting "provider.options.boot_from_volume", false
    run_interactive(unescape("cyoi provider #{settings_dir}"))
    assert_passing_with("Confirming: Using OpenStack/REGION (user: USERNAME)")
  end

  it "prompts for everything (no region)" do
    run_interactive(unescape("cyoi provider #{settings_dir}"))
    type("2")
    type("USERNAME")
    type("PASSWORD")
    type("TENANT")
    type("TOKENURL")
    type("")
    type("")
    type("")
    assert_passing_with(<<-OUT.strip + " \n")
1. AWS
2. OpenStack
3. vSphere
Choose your infrastructure:
    OUT

    assert_passing_with(<<-OUT.strip)
Using provider OpenStack
Username: Password: Tenant: Authorization Token URL: OpenStack Region (optional):
    OUT

    assert_passing_with(<<-OUT.strip + " \n")
1. QCOW2*
2. RAW
Image format to be used:
    OUT

    assert_passing_with("Confirming: Using OpenStack (user: USERNAME)")

    reload_settings!
    settings.to_nested_hash.should == {
      "provider" => {
        "name" => "openstack",
        "credentials"=>{
          "openstack_username"=>"USERNAME", "openstack_api_key"=>"PASSWORD",
          "openstack_tenant"=>"TENANT", "openstack_auth_url"=>"TOKENURL/tokens",
          "openstack_region"=>""
        },
        "options"=>{"boot_from_volume"=>false}
      }
    }
  end

  xit "prompts for everything (with region)" do
    run_interactive(unescape("cyoi provider #{settings_dir}"))
    type("2")
    type("USERNAME")
    type("PASSWORD")
    type("TENANT")
    type("TOKENURL")
    type("REGION")
    type("") # TODO: BROKEN
    type("")

    assert_passing_with(<<-OUT.strip + " \n")
1. AWS
2. OpenStack
3. vSphere
Choose your infrastructure:
    OUT

    assert_passing_with(<<-OUT.strip)
Using provider OpenStack
Username: Password: Tenant: Authorization Token URL: OpenStack Region (optional):
    OUT

    assert_passing_with(<<-OUT.strip + " \n")
1. QCOW2*
2. RAW
Image format to be used:
    OUT

    assert_passing_with("Confirming: Using OpenStack/REGION (user: USERNAME)")
  end

  xit "auto-detects several openstack options in ~/.fog" do
    setup_home_dir
    setup_fog_with_various_accounts_setup
    run_interactive(unescape("cyoi provider #{settings_dir}"))
    type("4")
    type("")
    type("")
    assert_passing_with(<<-OUT)
Auto-detected infrastructure API credentials at ~/.fog (override with $FOG)
1. AWS (default)
2. OpenStack (default)
3. AWS (starkandwayne)
4. OpenStack (personal)
5. Alternate credentials
Choose an auto-detected infrastructure:
Using provider OpenStack
OpenStack Region (optional):
Confirming: Using OpenStack (user: USERNAME)
    OUT
  end
end
