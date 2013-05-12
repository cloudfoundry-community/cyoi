require "cyoi/cli/providers/provider_cli"
class Cyoi::Cli::Providers::ProviderCliAws < Cyoi::Cli::Providers::ProviderCli
  def perform_and_return_attributes
    puts "\nUsing provider AWS\n"
    setup_credentials
    choose_region
    export_attributes
  end

  def setup_credentials
    puts "\n"
    attributes.set_default("credentials", {})
    attributes.credentials["aws_access_key_id"] = hl.ask("Access key: ")
    attributes.credentials["aws_secret_access_key"] = hl.ask("Secret key: ")
  end

  def choose_region
    puts "\n"
    hl.choose do |menu|
      menu.prompt = "Choose AWS region: "
      default_menu_item = nil
      region_labels.each do |region_info|
        label, code = region_info[:label], region_info[:code]
        menu_item = "#{label} (#{code})"
        if code == default_region_code
          menu_item = "*#{menu_item}"
          default_menu_item = menu_item 
        end
        menu.choice(menu_item) do
          attributes["region"] = code
        end
      end
      menu.default = default_menu_item if default_menu_item
    end
  end

  def valid_infrastructure?
    attributes.exists?("credentials.aws_access_key_id") &&
    attributes.exists?("credentials.aws_secret_access_key") &&
    attributes.exists?("region")
  end

  def display_confirmation
    puts "\n"
    puts "Confirming: Using AWS/#{attributes.region}"
  end

  protected
  # http://docs.aws.amazon.com/general/latest/gr/rande.html#region
  def region_labels
    [
      { label: "US East (Northern Virginia) Region", code: "us-east-1" },
      { label: "US West (Oregon) Region", code: "us-west-2" },
      { label: "US West (Northern California) Region", code: "us-west-1" },
      { label: "EU (Ireland) Region", code: "eu-west-1" },
      { label: "Asia Pacific (Singapore) Region", code: "ap-southeast-1" },
      { label: "Asia Pacific (Sydney) Region", code: "ap-southeast-2" },
      { label: "Asia Pacific (Tokyo) Region", code: "ap-northeast-1" },
      { label: "South America (Sao Paulo) Region", code: "sa-east-1" },
    ]
  end

  def default_region_code
    "us-east-1"
  end
end

Cyoi::Cli::Provider.register_provider_cli("aws", Cyoi::Cli::Providers::ProviderCliAws)