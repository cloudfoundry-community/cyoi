# Copyright (c) 2012-2013 Stark & Wayne, LLC

module Cyoi; module Providers; module Clients; end; end; end

require "ipaddr"
require "cyoi/providers/clients/fog_provider_client"
require "cyoi/providers/constants/aws_constants"

class Cyoi::Providers::Clients::AwsProviderClient < Cyoi::Providers::Clients::FogProviderClient
  include Cyoi::Providers::Constants::AwsConstants

  # Creates a bucket and makes it publicly read-only
  def create_blobstore(blobstore_name)
    super
    policy = {
      "Version" => "2008-10-17",
      "Statement" => [
        {
          "Sid" => "AddPerm",
          "Effect" => "Allow",
          "Principal" => {
            "AWS" => "*"
          },
          "Action" => "s3:GetObject",
          "Resource" => "arn:aws:s3:::#{blobstore_name}/*"
        }
      ]
    }
    fog_storage.put_bucket_policy(blobstore_name, policy)
  end

  # @return [Integer] megabytes of RAM for requested flavor of server
  def ram_for_server_flavor(server_flavor_id)
    if flavor = fog_compute_flavor(server_flavor_id)
      flavor[:ram]
    else
      raise "Unknown AWS flavor '#{server_flavor_id}'"
    end
  end

  # @return [Hash] e.g. { :bits => 0, :cores => 2, :disk => 0,
  #   :id => 't1.micro', :name => 'Micro Instance', :ram => 613}
  # or nil if +server_flavor_id+ is not a supported flavor ID
  def fog_compute_flavor(server_flavor_id)
    aws_compute_flavors.find { |fl| fl[:id] == server_flavor_id }
  end

  # @return [Array] of [Hash] for each supported compute flavor
  # Example [Hash] { :bits => 0, :cores => 2, :disk => 0,
  #   :id => 't1.micro', :name => 'Micro Instance', :ram => 613}
  def aws_compute_flavors
    Fog::Compute::AWS::FLAVORS
  end

  def aws_compute_flavor_ids
    aws_compute_flavors.map { |fl| fl[:id] }
  end

  # Provision an EC2 or VPC elastic IP addess.
  # * VPC - provision_public_ip_address(vpc: true)
  # * EC2 - provision_public_ip_address
  # @return [String] provisions a new public IP address in target region
  # TODO nil if none available
  def provision_public_ip_address(options={})
    if options.delete(:vpc)
      options[:domain] = "vpc"
    else
      options[:domain] = options.delete(:domain) || "standard"
    end
    address = fog_compute.addresses.create(options)
    address.public_ip
    # TODO catch error and return nil
  end

  def associate_ip_address_with_server(ip_address, server)
    address = fog_compute.addresses.get(ip_address)
    address.server = server
  end

  # @return [String] IP that is available for a new VM to use in a subnet
  # AWS reserves both the first four IP addresses and the last IP address in each subnet CIDR block.
  # They're not available for you to use.
  def next_available_ip_in_subnet(subnet)
    return nil if subnet.available_ip_address_count.to_i < 1
    ip = IPAddr.new(subnet.cidr_block)
    4.times { ip = ip.succ }
    skip_ips = ip_addresses_assigned_to_servers
    while skip_ips.include?(ip.to_s)
      ip = ip.succ
    end
    ip.to_s
  end

  def ip_addresses_assigned_to_servers
    fog_compute.servers.map {|s| s.private_ip_address}
  end


  def create_vpc(name, cidr_block)
    vpc = fog_compute.vpcs.create(name: name, cidr_block: cidr_block)
    vpc.id
  end

  # @return [boolean] true if target OpenStack running Neutron networks
  def networks?
    vpcs.size > 0
  end

  def vpcs
    fog_compute.vpcs
  end

  def subnets
    fog_compute.subnets
  end

  # Creates a VPC subnet
  # @return [String] the subnet_id
  def create_subnet(vpc_id, cidr_block)
    subnet = fog_compute.subnets.create(vpc_id: vpc_id, cidr_block: cidr_block)
    subnet.subnet_id
  end

  def create_internet_gateway(vpc_id)
    gateway = fog_compute.internet_gateways.create(vpc_id: vpc_id)
    gateway.id
  end

  def ip_permissions(sg)
    sg.ip_permissions
  end

  def port_open?(ip_permissions, port_range, protocol, ip_range)
    ip_permissions && ip_permissions.find do |ip|
     ip["ipProtocol"] == protocol \
     && ip["ipRanges"].detect { |range| range["cidrIp"] == ip_range } \
     && ip["fromPort"] <= port_range.min \
     && ip["toPort"] >= port_range.max
    end
  end

  def authorize_port_range(sg, port_range, protocol, ip_range)
    sg.authorize_port_range(port_range, {:ip_protocol => protocol, :cidr_ip => ip_range})
  end

  def find_server_device(server, device)
    server.volumes.all.find {|v| v.device == device}
  end

  def create_and_attach_volume(name, disk_size, server, device)
    volume = fog_compute.volumes.create(
        size: disk_size,
        name: name,
        description: '',
        device: device,
        availability_zone: server.availability_zone)
    # TODO: the following works in fog 1.9.0+ (but which has a bug in bootstrap)
    # https://github.com/fog/fog/issues/1516
    #
    # volume.wait_for { volume.status == 'available' }
    # volume.attach(server.id, "/dev/vdc")
    # volume.wait_for { volume.status == 'in-use' }
    #
    # Instead, using:
    volume.server = server
  end

  # Ubuntu 14.04
  def trusty_image_id(region=nil)
    region = fog_compute.region
    # http://cloud-images.ubuntu.com/locator/ec2/
    # version: 14.04 LTS
    # arch: amd64
    # instance type: ebs-ssd (not hvm)
    # Using release 20140927
    image_id = case region.to_s
    when "ap-northeast-1"
      "ami-df4b60de"
    when "ap-southeast-1"
      "ami-2ce7c07e"
    when "eu-west-1"
      "ami-f6b11181"
    when "sa-east-1"
      "ami-71d2676c"
    when "us-east-1"
      "ami-98aa1cf0"
    when "us-west-1"
      "ami-736e6536"
    when "eu-central-1"
      "ami-423c0a5f"
    when "cn-north-1"
      "ami-e642d0df"
    when "ap-southeast-2"
      "ami-1f117325"
    when "us-west-2"
      "ami-37501207"
    end
    image_id || raise("Please add Ubuntu 14.04 64bit (EBS SSD) AMI image id to aws.rb#trusty_image_id method for region '#{region}'")
  end

  def bootstrap(new_attributes = {})
    new_attributes[:image_id] ||= trusty_image_id(fog_compute.region)
    vpc = new_attributes[:subnet_id]

    server = fog_compute.servers.new(new_attributes)

    unless new_attributes[:key_name]
      raise "please provide :key_name attribute"
    end
    unless private_key_path = new_attributes.delete(:private_key_path)
      raise "please provide :private_key_path attribute"
    end

    if vpc
      # TODO setup security group on new server
    else
      # make sure port 22 is open in the first security group
      security_group = fog_compute.security_groups.get(server.groups.first)
      authorized = security_group.ip_permissions.detect do |ip_permission|
        ip_permission['ipRanges'].first && ip_permission['ipRanges'].first['cidrIp'] == '0.0.0.0/0' &&
        ip_permission['fromPort'] == 22 &&
        ip_permission['ipProtocol'] == 'tcp' &&
        ip_permission['toPort'] == 22
      end
      unless authorized
        security_group.authorize_port_range(22..22)
      end
    end

    server.save
    unless Fog.mocking?
      server.wait_for { ready? }
      server.setup(:keys => [private_key_path])
    end
    server
  end

  def fog_storage
    @fog_storage ||= begin
      configuration = Fog.symbolize_credentials(attributes.credentials)
      configuration[:provider] = "AWS"
      Fog::Storage.new(configuration)
    end
  end

  # Fog::Network does not exist for aws, use Fog::Compute instead
  def fog_network
    fog_compute
  end

  # Construct a Fog::Compute object
  # Uses +attributes+ which normally originates from +settings.provider+
  def setup_fog_connection
    configuration = Fog.symbolize_credentials(attributes.credentials)
    configuration[:provider] = "AWS"
    configuration[:region] = attributes.region
    @fog_compute = Fog::Compute.new(configuration)
  end
end
