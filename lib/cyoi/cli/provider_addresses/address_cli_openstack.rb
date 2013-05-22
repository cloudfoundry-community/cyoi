module Cyoi::Cli::Addresses; end
class Cyoi::Cli::Addresses::AddressCliOpenstack
  attr_reader :provider_client
  attr_reader :attributes
  attr_reader :hl

  def initialize(provider_client, attributes, highline)
    @provider_client = provider_client
    @hl = highline
    @attributes = attributes.is_a?(Hash) ? ReadWriteSettings.new(attributes) : attributes
    raise "@attributes must be ReadWriteSettings (or Hash)" unless @attributes.is_a?(ReadWriteSettings)
  end

  def perform_and_return_attributes
    unless valid_address?
      provision_address
    end
    export_attributes
  end

  # helper to export the complete nested attributes.
  def export_attributes
    attributes.to_nested_hash
  end


  def valid_address?
    attributes["ip"]
  end

  def display_confirmation
    puts "\n"
    puts "Confirming: Using address #{attributes.ip}"
  end

  protected
  def provision_address
    print "Acquiring a public IP address... "
    attributes["ip"] = provider_client.provision_public_ip_address
    puts attributes.ip
  end
end

Cyoi::Cli::Address.register_address_cli("openstack", Cyoi::Cli::Addresses::AddressCliOpenstack)