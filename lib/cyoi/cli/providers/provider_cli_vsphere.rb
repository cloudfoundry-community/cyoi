require "cyoi/cli/providers/provider_cli"
class Cyoi::Cli::Providers::ProviderCliVsphere < Cyoi::Cli::Providers::ProviderCli
  def perform_and_return_attributes
    unless valid_infrastructure?
      puts "\nUsing provider vSphere\n"
      setup_credentials
    end
    export_attributes
  end

  def setup_credentials
    puts "\n"
    attributes.set_default("credentials", {})
    credentials = attributes.credentials
    credentials["vsphere_username"] = hl.ask("Username: ").to_s unless credentials.exists?("vsphere_username")
    credentials["vsphere_password"] = hl.ask("Password: ").to_s unless credentials.exists?("vsphere_password")
    credentials["vsphere_server"] = hl.ask("Server: ").to_s unless credentials.exists?("vsphere_server")
    credentials["vsphere_expected_pubkey_hash"] = h1.ask("Expected public key hash: ").to_s unless credentials.exists?("vsphere_expected_pubkey_hash")
  end

  def valid_infrastructure?
    attributes.exists?("credentials.vsphere_username") &&
    attributes.exists?("credentials.vsphere_password") &&
    attributes.exists?("credentials.vsphere_server") &&
    attributes.exists?("credentials.vsphere_expected_pubkey_hash")
  end

  def display_confirmation
    puts "\n"
    puts "Confirming: Using vSphere"
  end
end

Cyoi::Cli::Provider.register_provider_cli("vsphere", Cyoi::Cli::Providers::ProviderCliVsphere)
