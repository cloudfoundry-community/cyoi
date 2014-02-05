require "fog"
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
        "openstack_auth_url" => "TOKENURL",
        "openstack_region" => "REGION"
      }
    }
  end

  subject { Cyoi::Providers.provider_client(provider_attributes) }

  it "is an OpenStack provider" do
    expect(subject).to be_instance_of(Cyoi::Providers::Clients::OpenStackProviderClient)
  end
end
