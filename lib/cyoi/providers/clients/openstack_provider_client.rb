# Copyright (c) 2012-2013 Stark & Wayne, LLC

module Cyoi; module Providers; module Clients; end; end; end

require "cyoi/providers/clients/fog_provider_client"
require "cyoi/providers/constants/openstack_constants"

class Cyoi::Providers::Clients::OpenStackProviderClient < Cyoi::Providers::Clients::FogProviderClient
  # @return [String] provisions a new public IP address in target region
  def provision_public_ip_address(options={})
    begin
    pool = fog_compute.addresses.get_address_pools.first
    address = fog_compute.addresses.create(:pool => pool["name"])
    address.ip
    rescue NoMethodError
      print "No Public IP Found"
    end
  end

  def associate_ip_address_with_server(ip_address, server)
    address = fog_compute.addresses.find { |a| a.ip == ip_address }
    address.server = server
  end

  # Hook method for FogProviderClient#create_security_group
  def ip_permissions(sg)
    sg.rules
  end

  # Hook method for FogProviderClient#create_security_group
  def port_open?(ip_permissions, port_range, protocol, ip_range)
    ip_permissions && ip_permissions.find do |ip|
      ip["ip_protocol"] == protocol \
      && ip["ip_range"].select { |range| range["cidr"] == ip_range } \
      && ip["from_port"] <= port_range.min \
      && ip["to_port"] >= port_range.max
    end
  end

  # Hook method for FogProviderClient#create_security_group
  def authorize_port_range(sg, port_range, protocol, ip_range)
    sg.create_security_group_rule(port_range.min, port_range.max, protocol, ip_range)
  end

  def find_server_device(server, device)
    va = fog_compute.get_server_volumes(server.id).body['volumeAttachments']
    va.find { |v| v["device"] == device }
  end

  def create_and_attach_volume(name, disk_size, server, device)
    volume = fog_compute.volumes.create(:name => name,
                                        :description => "",
                                        :size => disk_size,
                                        :availability_zone => server.availability_zone)
    volume.wait_for { volume.status == 'available' }
    volume.attach(server.id, device)
    volume.wait_for { volume.status == 'in-use' }
  end

  def delete_security_group_and_servers(sg_name)
    raise "not implemented yet"
  end

  # Construct a Fog::Compute object
  # Uses +attributes+ which normally originates from +settings.provider+
  def setup_fog_connection
    configuration = Fog.symbolize_credentials(attributes.credentials)
    configuration[:provider] = "OpenStack"
    if attributes.credentials.openstack_region && attributes.credentials.openstack_region.empty?
      configuration.delete(:openstack_region)
    end
    @fog_compute = Fog::Compute.new(configuration)
  end

  def openstack_constants
    Cyoi::Providers::Constants::OpenStackConstants
  end
end
