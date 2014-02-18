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
      if networks?
        subnet = select_subnet
        choose_address_from_subnet(subnet)
      else
        provision_address
      end
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

  def networks?
    provider_client.networks?
  end

  def select_subnet
    subnets = provider_client.subnets
    subnet = if subnets.size == 0
      $stderr.puts "ERROR: Your OpenStack is configured for Neutron networking but you have not yet created any subnets."
      exit 1
    elsif subnets.size == 1
      subnets.first
    else
      hl.choose do |menu|
        menu.prompt = "Choose a subnet: "
        # menu.choice("AWS") { "aws" }
        subnets.each do |subnet|
          menu.choice("#{pretty_subnet_name(subnet)}") { subnet }
        end
      end
    end
    attributes["subnet_id"] = subnet.network_id
    subnet
  end

  def choose_address_from_subnet(subnet)
    default_ip = provider_client.next_available_ip_in_subnet(subnet)
    puts "\n"
    ip = hl.ask("Choose IP ") { |q| q.default = default_ip }.to_s
    attributes["ip"] = ip
  end

  def pretty_ip_pool_ranges(subnet)
    ranges = subnet.allocation_pools.map do |pool|
      "#{pool['start']}-#{pool['end']}"
    end
    ranges.join(',')
  end

  def pretty_subnet_name(subnet)
    "#{subnet.name} (#{subnet.cidr})"
  end
end

Cyoi::Cli::Address.register_address_cli("openstack", Cyoi::Cli::Addresses::AddressCliOpenstack)