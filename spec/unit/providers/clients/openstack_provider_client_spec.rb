require "fog"
require "fog/openstack"
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
      }
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
end
