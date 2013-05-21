describe "cyoi provider aws" do
  include Cyoi::Cli::Helpers::Settings
  include SettingsHelper
  include Aruba::Api
  before { @settings_dir = File.expand_path("~/.cyoi_client_lib") }

  it "provider choices already made" do
    setting "provider.name", "aws"
    setting "provider.credentials.aws_access_key_id", "aws_access_key_id"
    setting "provider.credentials.aws_secret_access_key", "aws_secret_access_key"
    setting "provider.region", "us-west-2"
    run_interactive(unescape("cyoi provider #{settings_dir}"))
    assert_passing_with("Confirming: Using AWS/us-west-2")
  end

  it "prompts for provider, user chooses aws" do
    run_interactive(unescape("cyoi provider #{settings_dir}"))
    type("1")
    type("ACCESS")
    type("SECRET")
    type("2")
    type("")
    assert_passing_with(<<-OUT)
1. AWS
2. OpenStack
Choose your infrastructure: 
Using provider AWS

Access key: Secret key: 
1. *US East (Northern Virginia) Region (us-east-1)
2. US West (Oregon) Region (us-west-2)
3. US West (Northern California) Region (us-west-1)
4. EU (Ireland) Region (eu-west-1)
5. Asia Pacific (Singapore) Region (ap-southeast-1)
6. Asia Pacific (Sydney) Region (ap-southeast-2)
7. Asia Pacific (Tokyo) Region (ap-northeast-1)
8. South America (Sao Paulo) Region (sa-east-1)
Choose AWS region: 
Confirming: Using AWS/us-west-2
    OUT

    reload_settings!
    settings.to_nested_hash.should == {
      "provider" => {
        "name" => "aws",
        "credentials"=>{"aws_access_key_id"=>"ACCESS", "aws_secret_access_key"=>"SECRET"},
        "region" => "us-west-2",
      }
    }
  end

  it "auto-detects aws options in ~/.fog" do
    setup_home_dir
    setup_fog_with_various_accounts_setup
    run_interactive(unescape("cyoi provider #{settings_dir}"))
    type("3")
    type("6")
    type("")
    assert_passing_with(<<-OUT)
Auto-detected infrastructure API credentials at ~/.fog (override with $FOG)
1. AWS (default)
2. OpenStack (default)
3. AWS (starkandwayne)
4. OpenStack (personal)
5. Alternate credentials
Choose an auto-detected infrastructure:  
Using provider AWS


1. *US East (Northern Virginia) Region (us-east-1)
2. US West (Oregon) Region (us-west-2)
3. US West (Northern California) Region (us-west-1)
4. EU (Ireland) Region (eu-west-1)
5. Asia Pacific (Singapore) Region (ap-southeast-1)
6. Asia Pacific (Sydney) Region (ap-southeast-2)
7. Asia Pacific (Tokyo) Region (ap-northeast-1)
8. South America (Sao Paulo) Region (sa-east-1)
Choose AWS region: 
Confirming: Using AWS/ap-southeast-2
    OUT

    settings.provider.region.should == "ap-southeast-2"
  end
end