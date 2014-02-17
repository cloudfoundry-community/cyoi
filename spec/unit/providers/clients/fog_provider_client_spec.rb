require "cyoi/providers/clients/fog_provider_client"
require "fog/openstack/models/compute/security_groups"

describe Cyoi::Providers::Clients::FogProviderClient do
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
  let(:security_groups) { instance_double("Fog::Compute::OpenStack::SecurityGroups") }
  let(:security_group) { instance_double("Fog::Compute::OpenStack::SecurityGroup") }
  subject { Cyoi::Providers::Clients::FogProviderClient.new(provider_attributes) }

  before do
    expect(subject).to receive(:fog_compute).at_least(1).times.and_return(fog_compute)
  end

  describe "create_security_group" do
    it "add new single port to new SecurityGroup" do
      expect(fog_compute).to receive(:security_groups).twice.and_return(security_groups)
      expect(security_groups).to receive(:find).and_return(nil)
      expect(security_groups).to receive(:create).with(name: "foo", description: "foo").and_return(security_group)
      expect(subject).to receive(:puts).with("Created security group foo")
      expect(security_group).to receive(:ip_permissions)
      expect(security_group).to receive(:authorize_port_range).with(22..22, {:ip_protocol=>"tcp", :cidr_ip=>"0.0.0.0/0"})
      expect(subject).to receive(:puts).with(" -> opened port ports TCP 22..22 from IP range 0.0.0.0/0")

      subject.create_security_group("foo", "foo", port: 22)
    end

    it "add new single port to existing SecurityGroup" do
      expect(fog_compute).to receive(:security_groups).and_return(security_groups)
      expect(security_groups).to receive(:find).and_return(security_group)
      expect(subject).to receive(:puts).with("Reusing security group foo")
      expect(security_group).to receive(:ip_permissions)
      expect(security_group).to receive(:authorize_port_range).with(22..22, {:ip_protocol=>"tcp", :cidr_ip=>"0.0.0.0/0"})
      expect(subject).to receive(:puts).with(" -> opened port ports TCP 22..22 from IP range 0.0.0.0/0")

      subject.create_security_group("foo", "foo", port: 22)
    end

    it "add skip existing single port on existing SecurityGroup" do
      expect(fog_compute).to receive(:security_groups).and_return(security_groups)
      expect(security_groups).to receive(:find).and_return(security_group)
      expect(subject).to receive(:puts).with("Reusing security group foo")
      expect(security_group).to receive(:ip_permissions).and_return([{"fromPort"=>22, "toPort"=>22, "ipRanges"=>[{"cidrIp" => "0.0.0.0/0"}], "ipProtocol"=>"tcp"}])
      expect(subject).to receive(:puts).with(" -> no additional ports opened")

      subject.create_security_group("foo", "foo", port: 22)
    end

    it "add new range of ports" do
      expect(fog_compute).to receive(:security_groups).and_return(security_groups)
      expect(security_groups).to receive(:find).and_return(security_group)
      expect(subject).to receive(:puts).with("Reusing security group foo")
      expect(security_group).to receive(:ip_permissions)
      expect(security_group).to receive(:authorize_port_range).with(60000..60050, {:ip_protocol=>"tcp", :cidr_ip=>"0.0.0.0/0"})
      expect(subject).to receive(:puts).with(" -> opened port ports TCP 60000..60050 from IP range 0.0.0.0/0")

      subject.create_security_group("foo", "foo", port: 60000..60050)
    end

  end
end