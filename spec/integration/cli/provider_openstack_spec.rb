describe "cyoi openstack" do
  include Cyoi::Cli::Helpers::Settings
  include SettingsHelper
  include Aruba::Api
  before { @settings_dir = File.expand_path("~/.cyoi_client_lib") }

  it "prompts for everything (no region)" do
    run_interactive(unescape("cyoi #{settings_dir}"))
    type("2")
    type("USERNAME")
    type("PASSWORD")
    type("TENANT")
    type("TOKENURL")
    type("")
    type("2")
    type("")
    assert_passing_with(<<-OUT)
1. AWS
2. OpenStack
Choose your infrastructure: 
Using provider OpenStack

Username: Password: Tenant: Authorization Token URL: 
OpenStack Region (optional): 
Confirming: Using OpenStack
    OUT
  end

  it "prompts for everything (with region)" do
    run_interactive(unescape("cyoi #{settings_dir}"))
    type("2")
    type("USERNAME")
    type("PASSWORD")
    type("TENANT")
    type("TOKENURL")
    type("REGION")
    type("2")
    type("")
    assert_passing_with(<<-OUT)
1. AWS
2. OpenStack
Choose your infrastructure: 
Using provider OpenStack

Username: Password: Tenant: Authorization Token URL: 
OpenStack Region (optional): 
Confirming: Using OpenStack/REGION
    OUT
  end
end