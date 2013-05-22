require "cyoi/cli/providers/provider_cli"
class Cyoi::Cli::Providers::ProviderCliOpenStack < Cyoi::Cli::Providers::ProviderCli
  def perform_and_return_attributes
    unless valid_infrastructure?
      puts "\nUsing provider OpenStack\n"
      setup_credentials
    end
    export_attributes
  end

  def setup_credentials
    puts "\n"
    attributes.set_default("credentials", {})
    credentials = attributes.credentials
    credentials["openstack_username"] = hl.ask("Username: ").to_s unless credentials.exists?("openstack_username")
    credentials["openstack_api_key"] = hl.ask("Password: ").to_s unless credentials.exists?("openstack_api_key")
    credentials["openstack_tenant"] = hl.ask("Tenant: ").to_s unless credentials.exists?("openstack_tenant")
    credentials["openstack_auth_url"] = hl.ask("Authorization Token URL: ").to_s unless credentials.exists?("openstack_auth_url")
    credentials["openstack_auth_url"] = credentials["openstack_auth_url"] + "/tokens" unless credentials["openstack_auth_url"].match(/\/tokens$/)
    credentials["openstack_region"] = hl.ask("OpenStack Region (optional): ").to_s unless credentials.exists?("openstack_region")
  end

  def valid_infrastructure?
    attributes.exists?("region") &&
    attributes.exists?("credentials.openstack_username") &&
    attributes.exists?("credentials.openstack_api_key") &&
    attributes.exists?("credentials.openstack_tenant") &&
    attributes.exists?("credentials.openstack_auth_url")
  end

  def display_confirmation
    puts "\n"
    puts "Confirming: Using OpenStack"
  end
end

Cyoi::Cli::Provider.register_provider_cli("openstack", Cyoi::Cli::Providers::ProviderCliOpenStack)