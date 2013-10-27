class Cyoi::Cli::Image; end
class Cyoi::Cli::Image::ImageCliBase
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
    unless valid?
      attributes["image_id"] = image_id
    end
    export_attributes
  end

  # helper to export the complete nested attributes.
  def export_attributes
    attributes.to_nested_hash
  end

  def valid?
    attributes["image_id"]
  end

  def display_confirmation
    puts "\n"
    puts "Confirming: Using image #{attributes["image_id"]}"
  end
end