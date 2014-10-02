module Cyoi::Cli::Addresses; end
class Cyoi::Cli::Addresses::AddressCliAws
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
        vpc = select_vpc
        subnet = select_subnet_for_vpc(vpc)
        choose_address_from_subnet(subnet)
      else
        puts "Using EC2 as region #{region} has no VPCs"
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

  def select_vpc
    vpcs = provider_client.vpcs
    vpc = if vpcs.size == 1
      vpcs.first
    else
      hl.choose do |menu|
        menu.prompt = "Choose a VPC: "
        vpcs.each do |vpc|
          menu.choice("#{pretty_vpc_name(vpc)}") { vpc }
        end
      end
    end
    attributes["vpc_id"] = vpc.id
    vpc

  end

  def select_subnet_for_vpc(vpc)
    subnets = provider_client.subnets.select {|subnet|  subnet.vpc_id = vpc.id}
    subnet = if subnets.size == 0
      $stderr.puts "ERROR: VPC #{pretty_vpc_name(vpc)} has no subnets yet."
      exit 1
    elsif subnets.size == 1
      subnets.first
    else
      hl.choose do |menu|
        menu.prompt = "Choose a subnet: "
        subnets.each do |subnet|
          menu.choice("#{pretty_subnet_name(subnet)}") { subnet }
        end
      end
    end
    attributes["subnet_id"] = subnet.subnet_id
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

  def pretty_vpc_name(vpc)
    if name = vpc.tags["Name"]
      "#{name} (#{vpc.cidr_block})"
    else
      "#{vpc.id} (#{vpc.cidr_block})"
    end
  end

  def pretty_subnet_name(subnet)
    if name = subnet.tag_set["Name"]
      "#{name} (#{subnet.cidr_block})"
    else
      "#{subnet.subnet_id} (#{subnet.cidr_block})"
    end
  end
end

Cyoi::Cli::Address.register_address_cli("aws", Cyoi::Cli::Addresses::AddressCliAws)
