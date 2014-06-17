require "fog"
require "fog/openstack"
require "fog/openstack/models/compute/security_groups"
require "fog/openstack/models/compute/security_group_rule"
require "fog/openstack/models/compute/security_group_rules"
require 'fog/openstack/models/network/subnets'
require "cyoi/providers"

describe "cyoi address openstack" do
  before { Fog.mock!; Fog::Mock.reset }
  let(:provider_attributes) do
    {
      "name" => "openstack",
      "credentials" => {
        "openstack_username" => "USERNAME",
        "openstack_api_key" => "PASSWORD",
        "openstack_tenant" => "TENANT",
        "openstack_auth_url" => "http://someurl.com/v2/tokens",
        "openstack_region" => "REGION"
      },
      "skip_fog_setup" => true
    }
  end

  let(:fog_compute) { instance_double("Fog::Compute::OpenStack::Real") }
  let(:fog_network_const) { class_double("Fog::Network").as_stubbed_const(:transfer_nested_constants => [:OpenStack]) }
  let(:fog_network) { instance_double("Fog::Network::OpenStack::Real") }
  let(:addresses) { instance_double("Fog::Compute::OpenStack::Addresses") }
  let(:address) { instance_double("Fog::Compute::OpenStack::Address", ip: '1.2.3.4') }
  let(:unallocated_address) { instance_double("Fog::Compute::OpenStack::Address", ip: '1.2.3.4', instance_id: nil, pool: 'INTERNET') }
  let(:allocated_address) { instance_double("Fog::Compute::OpenStack::Address", ip: '1.2.3.4', instance_id: 'XXX', pool: 'INTERNET') }
  let(:subnets) { instance_double("Fog::Network::OpenStack::Subnets") }
  let(:networks) {}

  subject { Cyoi::Providers.provider_client(provider_attributes) }

  it "is an OpenStack provider" do
    expect(subject).to be_instance_of(Cyoi::Providers::Clients::OpenStackProviderClient)
  end

  context "provision_public_ip_address" do
    it "defaults to pool: 'nova' for nova" do
      expect(subject).to receive(:fog_compute).exactly(2).times.and_return(fog_compute)
      expect(fog_compute).to receive(:addresses).exactly(2).times.and_return(addresses)
      expect(addresses).to receive(:get_address_pools).and_return([{"name"=>"nova"}])
      expect(addresses).to receive(:create).with(pool: "nova").and_return(address)
      expect(subject.provision_public_ip_address).to eq('1.2.3.4')
    end

    it "specify a pool name" do
      expect(subject).to receive(:fog_compute).and_return(fog_compute)
      expect(fog_compute).to receive(:addresses).and_return(addresses)
      expect(addresses).to receive(:create).with(pool: "INTERNET").and_return(address)
      expect(subject.provision_public_ip_address("pool_name" => "INTERNET")).to eq('1.2.3.4')
    end
  end

  it "returns unallocated floating IPs for a pool" do
    expect(subject).to receive(:fog_compute).and_return(fog_compute)
    expect(fog_compute).to receive(:addresses).and_return([unallocated_address, allocated_address])
    expect(subject.unallocated_floating_ip_addresses("pool_name" => "INTERNET")).to eq(['1.2.3.4'])
  end

  context "networks" do
    it "has no networks" do
        expect(subject).to receive(:fog_network).and_return(nil)
      expect(subject.networks?).to be_nil
    end

    context "has networks" do
      before do
      end

      it "for sure" do
        expect(subject).to receive(:fog_network).and_return(fog_network)
        expect(subject.networks?).to_not be_nil
      end

      it "available subnets" do
        expect(subject).to receive(:fog_network).and_return(fog_network)
        expect(fog_network).to receive(:subnets).and_return(subnets)
        expect(subject.subnets).to eq(subnets)
      end
    end

    context 'next_available_ip_in_subnet' do
      let(:subnet) { Fog::Network::OpenStack::Subnet.new(
        "cidr" => "192.168.101.0/24",
        "gateway_ip" => "192.168.101.1",
        "allocation_pools" => [{"start"=>"192.168.101.2", "end"=>"192.168.101.254"}]
      ) }
      it "returns next IP in allocation pools" do
        expect(subject.next_available_ip_in_subnet(subnet)).to eq("192.168.101.2")
      end

      it "avoids IP addresses already allocated to other servers" do
        expect(subject).to receive(:ip_addresses_assigned_to_servers).and_return(["192.168.101.2", "192.168.101.3"])
        expect(subject.next_available_ip_in_subnet(subnet)).to eq("192.168.101.4")
      end
    end

    context 'ip_addresses_assigned_to_servers' do
      let(:addresses) do
        {"Internet Access "=>[{"OS-EXT-IPS-MAC:mac_addr"=>"fa:16:3e:c0:4b:b3", "version"=>4, "addr"=>"192.168.101.2", "OS-EXT-IPS:type"=>"fixed"}, {"OS-EXT-IPS-MAC:mac_addr"=>"fa:16:3e:c0:4b:b3", "version"=>4, "addr"=>"174.128.50.11", "OS-EXT-IPS:type"=>"floating"}]}
      end
      let(:servers) { [instance_double("Fog::Compute::OpenStack::Server", addresses: addresses)] }
      it "list of IPs" do
        expect(subject).to receive(:fog_compute).and_return(fog_compute)
        expect(fog_compute).to receive(:servers).and_return(servers)
        expect(subject.ip_addresses_assigned_to_servers).to eq(["192.168.101.2", "174.128.50.11"])
      end
    end
  end

  describe "create_security_group" do
    let(:security_groups) { instance_double("Fog::Compute::OpenStack::SecurityGroups") }
    let(:security_group) { instance_double("Fog::Compute::OpenStack::SecurityGroup", id: 1234) }
    let(:security_group_rules) { instance_double("Fog::Compute::OpenStack::SecurityGroupRules") }
    let(:security_group_rule) { instance_double("Fog::Compute::OpenStack::SecurityGroupRule",
      from_port: 22, to_port: 22, ip_range: [{"cidrIp" => "0.0.0.0/0"}], ip_protocol: "tcp") }

    before do
      expect(subject).to receive(:fog_compute).at_least(1).times.and_return(fog_compute)
    end

    it "add new single port to new SecurityGroup" do
      expect(fog_compute).to receive(:security_groups).twice.and_return(security_groups)
      expect(security_groups).to receive(:find).and_return(nil)
      expect(security_groups).to receive(:create).with(name: "foo", description: "foo").and_return(security_group)
      expect(subject).to receive(:puts).with("Created security group foo")
      expect(security_group).to receive(:security_group_rules).twice.and_return(security_group_rules)
      expect(security_group_rules).to receive(:find)
      expect(security_group_rules).to receive(:create).with(parent_group_id: 1234, from_port: 22, to_port: 22, ip_protocol: "tcp", ip_range: {"cidr" => "0.0.0.0/0"})
      expect(subject).to receive(:puts).with(" -> opened foo ports TCP 22..22 from IP range 0.0.0.0/0")

      subject.create_security_group("foo", "foo", 22)
    end

    it "add new single port by integer to existing SecurityGroup" do
      expect(fog_compute).to receive(:security_groups).and_return(security_groups)
      expect(security_groups).to receive(:find).and_return(security_group)
      expect(subject).to receive(:puts).with("Reusing security group foo")
      expect(security_group).to receive(:security_group_rules).twice.and_return(security_group_rules)
      expect(security_group_rules).to receive(:find)
      expect(security_group_rules).to receive(:create).with(parent_group_id: 1234, from_port: 22, to_port: 22, ip_protocol: "tcp", ip_range: {"cidr" => "0.0.0.0/0"})
      expect(subject).to receive(:puts).with(" -> opened foo ports TCP 22..22 from IP range 0.0.0.0/0")

      subject.create_security_group("foo", "foo", 22)
    end

    context 'legacy API used by old bosh-bootstrap - allow :ports key' do
      it "add new single port by :ports key to existing SecurityGroup" do
        expect(fog_compute).to receive(:security_groups).and_return(security_groups)
        expect(security_groups).to receive(:find).and_return(security_group)
        expect(subject).to receive(:puts).with("Reusing security group foo")
      expect(security_group).to receive(:security_group_rules).twice.and_return(security_group_rules)
      expect(security_group_rules).to receive(:find)
      expect(security_group_rules).to receive(:create).with(parent_group_id: 1234, from_port: 22, to_port: 22, ip_protocol: "tcp", ip_range: {"cidr" => "0.0.0.0/0"})
        expect(subject).to receive(:puts).with(" -> opened foo ports TCP 22..22 from IP range 0.0.0.0/0")

        subject.create_security_group("foo", "foo", ports: 22)
      end

    it "add UDP ports by :ports key" do
      expect(fog_compute).to receive(:security_groups).and_return(security_groups)
      expect(security_groups).to receive(:find).and_return(security_group)
      expect(subject).to receive(:puts).with("Reusing security group foo")
      expect(security_group).to receive(:security_group_rules).twice.and_return(security_group_rules)
      expect(security_group_rules).to receive(:find)
      expect(security_group_rules).to receive(:create).with(parent_group_id: 1234, from_port: 53, to_port: 53, ip_protocol: "udp", ip_range: {"cidr" => "0.0.0.0/0"})
      expect(subject).to receive(:puts).with(" -> opened foo ports UDP 53..53 from IP range 0.0.0.0/0")

      subject.create_security_group("foo", "foo", ports: { protocol: "udp", ports: (53..53) })
    end
    end

    it "add skip existing single port on existing SecurityGroup" do
      expect(fog_compute).to receive(:security_groups).and_return(security_groups)
      expect(security_groups).to receive(:find).and_return(security_group)
      expect(subject).to receive(:puts).with("Reusing security group foo")
      expect(security_group).to receive(:security_group_rules).and_return(security_group_rules)
      expect(security_group_rules).to receive(:find).and_return(security_group_rule)
      expect(subject).to receive(:puts).with(" -> no additional ports opened")

      subject.create_security_group("foo", "foo", 22)
    end

    it "add new range of ports" do
      expect(fog_compute).to receive(:security_groups).and_return(security_groups)
      expect(security_groups).to receive(:find).and_return(security_group)
      expect(subject).to receive(:puts).with("Reusing security group foo")
      expect(security_group).to receive(:security_group_rules).twice.and_return(security_group_rules)
      expect(security_group_rules).to receive(:find)
      expect(security_group_rules).to receive(:create).with(parent_group_id: 1234, from_port: 60000, to_port: 60050, ip_protocol: "tcp", ip_range: {"cidr" => "0.0.0.0/0"})
      expect(subject).to receive(:puts).with(" -> opened foo ports TCP 60000..60050 from IP range 0.0.0.0/0")

      subject.create_security_group("foo", "foo", ports: 60000..60050)
    end

    it "add UDP ports" do
      expect(fog_compute).to receive(:security_groups).and_return(security_groups)
      expect(security_groups).to receive(:find).and_return(security_group)
      expect(subject).to receive(:puts).with("Reusing security group foo")
      expect(security_group).to receive(:security_group_rules).twice.and_return(security_group_rules)
      expect(security_group_rules).to receive(:find)
      expect(security_group_rules).to receive(:create).with(parent_group_id: 1234, from_port: 53, to_port: 53, ip_protocol: "udp", ip_range: {"cidr" => "0.0.0.0/0"})
      expect(subject).to receive(:puts).with(" -> opened foo ports UDP 53..53 from IP range 0.0.0.0/0")

      subject.create_security_group("foo", "foo", { protocol: "udp", ports: (53..53) })
    end

    it "add list of unrelated ports" do
      expect(fog_compute).to receive(:security_groups).and_return(security_groups)
      expect(security_groups).to receive(:find).and_return(security_group)
      expect(subject).to receive(:puts).with("Reusing security group foo")
      expect(security_group).to receive(:security_group_rules).at_least(1).times.and_return(security_group_rules)
      expect(security_group_rules).to receive(:find).at_least(1).times
      expect(security_group_rules).to receive(:create).with(parent_group_id: 1234, from_port: 22, to_port: 22, ip_protocol: "tcp", ip_range: {"cidr" => "0.0.0.0/0"})
      expect(security_group_rules).to receive(:create).with(parent_group_id: 1234, from_port: 443, to_port: 443, ip_protocol: "tcp", ip_range: {"cidr" => "0.0.0.0/0"})
      expect(security_group_rules).to receive(:create).with(parent_group_id: 1234, from_port: 4443, to_port: 4443, ip_protocol: "tcp", ip_range: {"cidr" => "0.0.0.0/0"})
      expect(subject).to receive(:puts).with(" -> opened foo ports TCP 22..22 from IP range 0.0.0.0/0")
      expect(subject).to receive(:puts).with(" -> opened foo ports TCP 443..443 from IP range 0.0.0.0/0")
      expect(subject).to receive(:puts).with(" -> opened foo ports TCP 4443..4443 from IP range 0.0.0.0/0")

      subject.create_security_group("foo", "foo", [22, 443, 4443])
    end
  end
end
