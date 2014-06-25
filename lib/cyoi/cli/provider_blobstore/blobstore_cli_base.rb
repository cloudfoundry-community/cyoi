class Cyoi::Cli::Blobstore; end
class Cyoi::Cli::Blobstore::BlobstoreCliBase
  attr_reader :provider_client
  attr_reader :attributes
  attr_reader :hl

  def initialize(provider_client, attributes, highline)
    @provider_client = provider_client
    @hl = highline
    @attributes = attributes.is_a?(Hash) ? ReadWriteSettings.new(attributes) : attributes
    raise "@attributes must be ReadWriteSettings (or Hash); was #{@attributes.class}" unless @attributes.is_a?(ReadWriteSettings)
  end

  def perform_and_return_attributes
    # create blobstore OR show how many blobstore already exist in blobstore
    provider_client.create_blobstore(attributes["name"])
    export_attributes
  end

  # helper to export the complete nested attributes.
  def export_attributes
    attributes.to_nested_hash
  end

  def display_confirmation
    puts "\n"
    puts "Confirming: Using blobstore #{attributes["name"]}"
  end
end
