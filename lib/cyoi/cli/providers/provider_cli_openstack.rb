require "cyoi/cli/providers/provider_cli"
class Cyoi::Cli::Providers::ProviderCliOpenStack < Cyoi::Cli::Providers::ProviderCli
  def perform_and_return_attributes
    unless valid_infrastructure?
      puts "\nUsing provider OpenStack\n"
      setup_credentials
      setup_options
    end
    export_attributes
  end

  def setup_credentials
    attributes.set_default("credentials", {})
    credentials = attributes.credentials
    credentials["openstack_username"] = hl.ask("Username: ").to_s unless credentials.exists?("openstack_username")
    credentials["openstack_api_key"] = hl.ask("Password: ").to_s unless credentials.exists?("openstack_api_key")
    credentials["openstack_tenant"] = hl.ask("Tenant: ").to_s unless credentials.exists?("openstack_tenant")
    credentials["openstack_auth_url"] = hl.ask("Authorization Token URL: ").to_s unless credentials.exists?("openstack_auth_url")
    credentials["openstack_auth_url"] = credentials["openstack_auth_url"] + "/tokens" unless credentials["openstack_auth_url"].match(/\/tokens$/)
    unless credentials.has_key?("openstack_region")
      credentials["openstack_region"] = hl.ask("OpenStack Region (optional): ").to_s.strip
    end
    attributes["credentials"] = credentials # need to reassign changed value
  end

  def setup_options
    attributes.set_default("options", {})
    options = attributes.options

    unless options.has_key?("boot_from_volume")
      image_type = hl.choose do |menu|
        menu.prompt = "Image format to be used: "
        menu.choice("QCOW2*") { "qcow2" }
        menu.choice("RAW") { "raw" }
        menu.default ="QCOW2*"
      end
      options["boot_from_volume"] = (image_type && image_type.to_s == "raw")
    end
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
    region = attributes.credentials["openstack_region"]
    if region.size > 0
      puts "Confirming: Using OpenStack/#{region} (user: #{attributes.credentials.openstack_username})"
    else
      puts "Confirming: Using OpenStack (user: #{attributes.credentials.openstack_username})"
    end
  end
end

Cyoi::Cli::Provider.register_provider_cli("openstack", Cyoi::Cli::Providers::ProviderCliOpenStack)
