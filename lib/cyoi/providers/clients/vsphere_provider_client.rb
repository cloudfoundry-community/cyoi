module Cyoi; module Providers; module Clients; end; end; end

require "cyoi/providers/clients/fog_provider_client"

class Cyoi::Providers::Clients::VsphereProviderClient < Cyoi::Providers::Clients::FogProviderClient

  # Construct a Fog::Compute object
  # Uses +attributes+ which normally originates from +settings.provider+
  def setup_fog_connection
    configuration = Fog.symbolize_credentials(attributes.credentials)
    configuration[:provider] = "vSphere"
    @fog_compute = Fog::Compute.new(configuration)
  end
    
end
