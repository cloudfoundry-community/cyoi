class Cyoi::Cli::KeyPair; end
class Cyoi::Cli::KeyPair::KeyPairCliAws
  attr_reader :provider_client
  attr_reader :attributes
  attr_reader :hl

  def initialize(provider_client, attributes, highline)
    @provider_client = provider_client
    @hl = highline
    @attributes = attributes.is_a?(Hash) ? Settingslogic.new(attributes) : attributes
    raise "@attributes must be Settingslogic (or Hash)" unless @attributes.is_a?(Settingslogic)
    raise "@attributes.name must be set" unless @attributes["name"]
  end

  def perform_and_return_attributes
    provision_address unless valid?
    export_attributes
  end

  # helper to export the complete nested attributes.
  def export_attributes
    attributes.to_nested_hash
  end

  def valid?
    attributes["fingerprint"] && attributes["private_key"]
  end

  def display_confirmation
    puts "\n"
    puts "Confirming: Using key pair #{key_pair_name}"
  end

  def key_pair_name
    attributes.name
  end

  protected
  # provisions key pair from AWS and returns fog object KeyPair
  def provision_address
    print "Acquiring a key pair #{key_pair_name}... "
    if key_pair = provider_client.create_key_pair(key_pair_name)
      attributes["fingerprint"] = key_pair.fingerprint
      attributes["private_key"] = key_pair.private_key
      puts "done"
    end
  end
end

Cyoi::Cli::KeyPair.register_key_pair_cli("aws", Cyoi::Cli::KeyPair::KeyPairCliAws)
