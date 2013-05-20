# Copyright (c) 2012-2013 Stark & Wayne, LLC

module Cyoi; end

module Cyoi::Providers
  extend self

  # returns a Infrastructure provider specific object
  # with helpers related to that provider
  # returns nil if +attributes.name+ is unknown
  def provider_client(attributes)
    attributes = attributes.is_a?(Hash) ? ReadWriteSettings.new(attributes) : attributes
    case attributes.name.to_sym
    when :aws
      @aws_provider_client ||= begin
        require "cyoi/providers/clients/aws_provider_client"
        Cyoi::Providers::Clients::AwsProviderClient.new(attributes)
      end
    when :openstack
      @openstack_provider_client ||= begin
        require "cyoi/providers/clients/openstack_provider_client"
        Cyoi::Providers::Clients::OpenStackProviderClient.new(attributes)
      end
    else
      nil
    end
  end
end
