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

  context "networks" do
    it "has no networks" do
      expect(fog_network_const).to receive(:[]).with("openstack").
        and_raise(Fog::Errors::NotFound)
      expect(subject.networks?).to be_nil
    end

    context "has networks" do
      before do
      end

      it "for sure" do
        expect(fog_network_const).to receive(:[]).with("openstack").
          and_return(fog_network)
        expect(subject.networks?).to_not be_nil
      end

      it "available subnets" do
        expect(subject).to receive(:fog_network).and_return(fog_network)
        expect(fog_network).to receive(:subnets).and_return(subnets)
        expect(subject.subnets).to eq(subnets)
      end
    end
  end
end
