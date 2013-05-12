describe "cyoi openstack" do
  include Cyoi::Cli::Helpers::Settings
  include SettingsHelper
  include Aruba::Api
  before { @settings_dir = File.expand_path("~/.cyoi_client_lib") }

  it "prompts for everything" do
    run_interactive(unescape("cyoi #{settings_dir}"))
    type("2")
    type("ACCESS")
    type("SECRET")
    type("2")
    type("")
    assert_passing_with(<<-OUT)
1. AWS
2. OpenStack
Choose your infrastructure: 
Using provider OpenStack

Access key: Secret key: Confirming: Using openstack/
    OUT
  end
end