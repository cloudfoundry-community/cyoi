require "fog"
require "fog/openstack"
require "cyoi/providers"

describe "cyoi address openstack" do
  let(:provider_attributes) do
    {
      "name" => "openstack",
      "credentials" => {
        "openstack_username" => "USERNAME",
        "openstack_api_key" => "PASSWORD",
        "openstack_tenant" => "TENANT",
        "openstack_auth_url" => "TOKENURL",
        "openstack_region" => "REGION"
      }
    }
  end

  let(:fog_compute) { instance_double("Fog::Compute::OpenStack::Real") }
  let(:fog_network_const) { class_double("Fog::Network").as_stubbed_const(:transfer_nested_constants => [:OpenStack]) }
  let(:fog_network) { instance_double("Fog::Network::OpenStack::Real") }
  let(:addresses) { instance_double("Fog::Compute::OpenStack::Addresses") }
  let(:address) { instance_double("Fog::Compute::OpenStack::Address", ip: '1.2.3.4') }
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
  end

  context "networks" do
    it "has no networks" do
      expect(fog_network_const).to receive(:[]).
        with("openstack").and_raise(Fog::Errors::NotFound)
      expect(subject.networks?).to be_nil
    end

    it "has networks" do
      expect(fog_network_const).to receive(:[]).
        with("openstack").and_return(fog_network)
      expect(subject.networks?).to_not be_nil
    end
  end
end
