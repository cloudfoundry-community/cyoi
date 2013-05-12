require "cyoi/cli/providers/provider_cli"
class Cyoi::Cli::Providers::ProviderCliOpenStack < Cyoi::Cli::Providers::ProviderCli
  def perform_and_return_attributes
    puts "\nUsing provider OpenStack\n"
    setup_credentials
    attributes["region"] = nil
    export_attributes
  end

  def setup_credentials
    puts "\n"
    attributes.set_default("credentials", {})
    attributes.credentials["aws_access_key_id"] = hl.ask("Access key: ")
    attributes.credentials["aws_secret_access_key"] = hl.ask("Secret key: ")
  end

end

Cyoi::Cli::Provider.register_provider_cli("openstack", Cyoi::Cli::Providers::ProviderCliOpenStack)