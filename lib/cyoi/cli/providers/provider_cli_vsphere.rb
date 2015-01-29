require "cyoi/cli/providers/provider_cli"
class Cyoi::Cli::Providers::ProviderCliVsphere < Cyoi::Cli::Providers::ProviderCli
  def perform_and_return_attributes
    unless valid_infrastructure?
      puts "\nUsing provider vSphere\n"
      setup_credentials
      setup_networking
      setup_resources
      setup_ntp
      setup_vcenter
    end
    export_attributes
  end

  def setup_credentials
    puts "\n"
    attributes.set_default("credentials", {})
    credentials = attributes.credentials
    credentials["vsphere_username"] = hl.ask("Username: ").to_s unless credentials.exists?("vsphere_username")
    credentials["vsphere_password"] = (hl.ask("Password: ") { |q| q.echo = 'x' }).to_s unless credentials.exists?("vsphere_password")
    credentials["vsphere_server"] = hl.ask("Server: ").to_s unless credentials.exists?("vsphere_server")
    credentials["vsphere_expected_pubkey_hash"] = hl.ask("Expected public key hash: ").to_s unless credentials.exists?("vsphere_expected_pubkey_hash")
  end

  def setup_networking
    puts "\n"
    attributes.set_default("network", {})
    network = attributes.network
    network["netmask"] = hl.ask("Netmask: ").to_s unless network.exists?("netmask")
    network["gateway"] = hl.ask("Gateway: ").to_s unless network.exists?("gateway")
    network["dns"] = hl.ask("DNS Server: ").to_s unless network.exists?("dns")
    network["name"] = hl.ask("vCenter Port Group: ").to_s unless network.exists?("name")
  end

  def setup_resources
    puts "\n"
    attributes.set_default("resources", {})
    resources = attributes.resources
    resources["persistent_disk"] = hl.ask("Size of Persistent Volume (MB): ", Integer) unless resources.exists?("persistent_disk")
    resources["ram"] = hl.ask("MicroBOSH Memory (MB): ", Integer) unless resources.exists?("ram")
    resources["disk"] = hl.ask("MicroBOSH Local Disk (MB): ", Integer) unless resources.exists?("disk")
    resources["cpu"] = hl.ask("MicroBOSH vCPUs: ", Integer) unless resources.exists?("cpu")
  end

  def setup_ntp
    puts "\n"
    attributes["ntps"] = hl.ask("NTP Server: ").to_s unless attributes.exists?("ntps")
  end

  def setup_vcenter
    puts "\n"
    attributes.set_default("datacenter", {})
    datacenter = attributes.datacenter
    datacenter["name"] = hl.ask("Datacenter: ").to_s unless datacenter.exists?("name")
    datacenter["vm_folder"] = hl.ask("VM Folder: ").to_s unless datacenter.exists?("vm_folder")
    datacenter["template_folder"] = hl.ask("Template Folder: ").to_s unless datacenter.exists?("template_folder")
    datacenter["disk_path"] = hl.ask("Disk Path: ").to_s unless datacenter.exists?("disk_path")
    datacenter["datastore_pattern"] = hl.ask("Datastore Pattern: ").to_s unless datacenter.exists?("datastore_pattern")
    datacenter["persistent_datastore_pattern"] = hl.ask("Persistent Datastore Pattern: ").to_s unless datacenter.exists?("persistent_datastore_pattern")
    datacenter["allow_mixed_datastores"] = hl.agree("Allow mixed datastores? (y/n): ") unless datacenter.exists?("allow_mixed_datastores")
    datacenter["clusters"] = hl.ask("Clusters: ").to_s unless datacenter.exists?("clusters")
  end

  def valid_infrastructure?
    attributes.exists?("credentials.vsphere_username") &&
    attributes.exists?("credentials.vsphere_password") &&
    attributes.exists?("credentials.vsphere_server") &&
    attributes.exists?("credentials.vsphere_expected_pubkey_hash") &&
    attributes.exists?("network.netmask") &&
    attributes.exists?("network.gateway") &&
    attributes.exists?("network.dns") &&
    attributes.exists?("network.name") &&
    attributes.exists?("ntps") &&
    attributes.exists?("datacenter.name") &&
    attributes.exists?("datacenter.vm_folder") &&
    attributes.exists?("datacenter.template_folder") &&
    attributes.exists?("datacenter.disk_path") &&
    attributes.exists?("datacenter.datastore_pattern") &&
    attributes.exists?("datacenter.persistent_datastore_pattern") &&
    attributes.exists?("datacenter.allow_mixed_datastores") &&
    attributes.exists?("datacenter.clusters") &&
    attributes.exists?("resources.persistent_disk") &&
    attributes.exists?("resources.ram") &&
    attributes.exists?("resources.disk") &&
    attributes.exists?("resources.cpu")
  end

  def display_confirmation
    puts "\n"
    puts "Confirming: Using vSphere"
  end
end

Cyoi::Cli::Provider.register_provider_cli("vsphere", Cyoi::Cli::Providers::ProviderCliVsphere)
