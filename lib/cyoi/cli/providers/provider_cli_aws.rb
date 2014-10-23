require "cyoi/providers/constants/aws_constants"
require "cyoi/cli/providers/provider_cli"
class Cyoi::Cli::Providers::ProviderCliAws < Cyoi::Cli::Providers::ProviderCli
  def perform_and_return_attributes
    unless valid_infrastructure?
      puts "\nUsing provider AWS\n"
      setup_credentials
      choose_region
    end
    export_attributes
  end

  def setup_credentials
    puts "\n"
    attributes.set_default("credentials", {})
    credentials = attributes.credentials
    credentials["aws_access_key_id"] = hl.ask("Access key: ").to_s unless credentials.exists?("aws_access_key_id")
    credentials["aws_secret_access_key"] = hl.ask("Secret key: ").to_s unless credentials.exists?("aws_secret_access_key")
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
          attributes["region"] = code.to_s
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
    type = attributes.exists?("vpc") ? "VPC" : "EC2"
    puts "Confirming: Using AWS #{type}/#{attributes.region}"
  end

  protected
  # http://docs.aws.amazon.com/general/latest/gr/rande.html#region
  def region_labels
    Cyoi::Providers::Constants::AwsConstants.region_labels
  end

  def default_region_code
    "us-east-1"
  end
end

Cyoi::Cli::Provider.register_provider_cli("aws", Cyoi::Cli::Providers::ProviderCliAws)
