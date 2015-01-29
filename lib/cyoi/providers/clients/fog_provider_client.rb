# Copyright (c) 2012-2013 Stark & Wayne, LLC

require "fog"
module Cyoi; module Providers; module Clients; end; end; end

class Cyoi::Providers::Clients::FogProviderClient
  attr_reader :fog_compute
  attr_reader :attributes

  def initialize(attributes)
    @attributes = attributes.is_a?(Hash) ? ReadWriteSettings.new(attributes) : attributes
    raise "@attributes must be ReadWriteSettings (or Hash)" unless @attributes.is_a?(ReadWriteSettings)
    setup_fog_connection unless attributes.delete("skip_fog_setup")
  end

  # Implement in subclasses
  def setup_fog_connection
  end

  def supports_blobstore_service?
    fog_storage
  rescue
    false
  end

  # Creates a bucket/object-store/directory/blobstore
  # To be overridden to make the bucket publicly read-only
  # per IaaS.
  def create_blobstore(blobstore_name)
    unless supports_blobstore_service?
      puts "Provider does not support blobstore service"
      false
    else
      print "Creating publicly readable blobstore #{blobstore_name}... "
      blobstore = fog_storage.directories.create(key: blobstore_name)
      puts "done"
      blobstore
    end
  rescue Excon::Errors::Forbidden => e
    puts "failed: credentials do not allow blobstore to be created"
    false
  rescue Excon::Errors::Conflict => e
    puts "failed: blobstore already exists but owned by someone else"
    false
  end

  def create_key_pair(key_pair_name)
    print "Acquiring a key pair #{key_pair_name}... "
    key_pair = fog_compute.key_pairs.create(:name => key_pair_name)
    puts "done"
    key_pair
  end

  def valid_key_pair_fingerprint?(key_pair_name, fingerprint)
    if fog_key_pair = fog_compute.key_pairs.get(key_pair_name)
      fog_key_pair.fingerprint == fingerprint
    else
      false
    end
  end

  # set_resource_name(fog_server, "inception")
  # set_resource_name(volume, "inception-root")
  # set_resource_name(volume, "inception-store")
  def set_resource_name(resource, name)
    fog_compute.tags.create :key => "Name", :value => name, :resource_id => resource.id
  end

  def delete_key_pair_if_exists(key_pair_name)
    if fog_key_pair = fog_compute.key_pairs.get(key_pair_name)
      print "Destroying key pair #{key_pair_name}... "
      fog_key_pair.destroy
      puts "done"
    end
  end

  def delete_servers_with_name(name)
    fog_compute.servers.select {|s| s.tags["Name"].downcase == name.downcase }.each do |server|
      print "Destroying server #{server.id}... "
      server.destroy
      puts "done"
    end
  end

  def delete_volumes_with_name(name)
    fog_compute.volumes.select do |v|
      volume_name = v.tags["Name"]
      volume_name && volume_name.downcase == name.downcase
    end.each do |volume|
      print "Destroying volume #{volume.id}... "
      volume.destroy
      puts "done"
    end
  end

  # Destroy all IP addresses that aren't bound to a server
  def cleanup_unused_ip_addresses
    fog_compute.addresses.each do |a|
      unless a.server
        print "Deleting unused IP address #{a.public_ip}... "
        a.destroy
        puts "done"
      end
    end
  end

  # Creates or reuses an security group and opens ports.
  #
  # +security_group_name+ is the name to be created or reused
  # +ports+ is a hash of name/port for ports to open
  #
  # protocol defaults to TCP
  # You can also use a more verbose +ports+ using the format:
  # * 22,
  # * { ports: (80..82) },
  # * { protocol: "udp", ports: (60000..60050) }
  # * { protocol: "rdp", ports: (3398..3398), ip_ranges: [ { cidrIp: "196.212.12.34/32" } ] }
  #
  # In this example,
  #  * TCP 22 will be opened for ssh from any ip_range,
  #  * TCP ports 80, 81, 82 for http from any ip_range,
  #  * UDP 60000 -> 60050 for mosh from any ip_range and
  #  * TCP 3398 for RDP from ip range: 96.212.12.34/32
  def create_security_group(security_group_name, description, defns, extra_attributes={})
    security_groups = fog_compute.security_groups
    sg = security_groups.find do |s|
      if extra_attributes[:vpc_id]
        s.name == security_group_name && s.vpc_id == extra_attributes[:vpc_id]
      else
        s.name == security_group_name
      end
    end

    suffix = extra_attributes[:vpc_id] ? " for the VPC" : ""
    unless sg
      attributes = {name: security_group_name, description: description}.merge(extra_attributes)
      sg = fog_compute.security_groups.create(attributes)
      puts "Created security group #{security_group_name}#{suffix}"
    else
      puts "Reusing security group #{security_group_name}#{suffix}"
    end
    ip_permissions = ip_permissions(sg)
    ports_opened = 0

    # Unnest { ports: 22 } and { ports: { ports: 22..22 }} legacy inputs
    if defns.is_a?(Hash) && defns[:ports].is_a?(Hash)
      defns = defns[:ports]
    end

    # If we are passed an array of ports, preserve that
    if defns.is_a?(Hash) && defns[:ports].is_a?(Array)
      defns = defns[:ports]
    end

    unless defns.is_a?(Array)
      defns = [defns]
    end
    defns.each do |port_defn|
      port_defns = port_defn.is_a?(Array) ? port_defn : [port_defn]
      port_defns.each do |port_defn|
        (protocol, port_range, ip_range) = extract_port_definition(port_defn)
        unless port_open?(ip_permissions, port_range, protocol, ip_range)
          authorize_port_range(sg, port_range, protocol, ip_range)
          puts " -> opened #{security_group_name} ports #{protocol.upcase} #{port_range.min}..#{port_range.max} from IP range #{ip_range}"
          ports_opened += 1
        end
      end
    end
    puts " -> no additional ports opened" if ports_opened == 0
    true
  end

  def port_open?(ip_permissions, port_range, protocol, ip_range)
    raise "must implement"
  end

  def authorize_port_range(sg, port_range, protocol, ip_range)
    raise "must implement"
  end

  def ip_permissions(sg)
    raise "must implement"
  end

  # Any of the following +port_defn+ can be used:
  # {
  #   ssh: 22,
  #   http: { ports: (80..82) },
  #   mosh: { protocol: "udp", ports: (60000..60050) }
  #   mosh: { protocol: "rdp", ports: (3398..3398), ip_range: "196.212.12.34/32" }
  # }
  # In this example,
  #  * TCP 22 will be opened for ssh from any ip_range,
  #  * TCP ports 80, 81, 82 for http from any ip_range,
  #  * UDP 60000 -> 60050 for mosh from any ip_range and
  #  * TCP 3398 for RDP from ip range: 96.212.12.34/32
  def extract_port_definition(port_defn)
    protocol = "tcp"
    ip_range = "0.0.0.0/0"
    if port_defn.is_a? Integer
      port_range = (port_defn..port_defn)
    elsif port_defn.is_a? Range
      port_range = port_defn
    elsif port_defn.is_a? Hash
      protocol = port_defn[:protocol] if port_defn[:protocol]
      port_range = port_defn[:ports]  if port_defn[:ports]
      if port_range.is_a? Integer
        port_range = (port_range..port_range)
      end
      ip_range = port_defn[:ip_range] if port_defn[:ip_range]
    end
    [protocol, port_range, ip_range]
  end

  def provision_or_reuse_public_ip_address(options={})
    provision_public_ip_address(options) || find_unused_public_ip_address(options)
  end

  def find_unused_public_ip_address(options={})
    if address = fog_compute.addresses.find { |s| s.server_id.nil? }
      address.public_ip
    end
  end
end
