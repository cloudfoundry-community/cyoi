require "cyoi/cli/providers/provider_cli"
class Cyoi::Cli::Providers::ProviderCliOpenStack < Cyoi::Cli::Providers::ProviderCli
  def perform_and_return_attributes
    puts "\nUsing provider OpenStack\n"
    setup_credentials
    choose_region
    export_attributes
  end

  def setup_credentials
    puts "\n"
    attributes.set_default("credentials", {})
    attributes.credentials["openstack_username"] = hl.ask("Username: ")
    attributes.credentials["openstack_api_key"] = hl.ask("Password: ")
    attributes.credentials["openstack_tenant"] = hl.ask("Tenant: ")
    attributes.credentials["openstack_auth_url"] = hl.ask("Authorization Token URL: ")
  end

  def choose_region
    puts "\n"
    attributes["region"] = hl.ask("OpenStack Region (optional): ")
  end
end

Cyoi::Cli::Provider.register_provider_cli("openstack", Cyoi::Cli::Providers::ProviderCliOpenStack)