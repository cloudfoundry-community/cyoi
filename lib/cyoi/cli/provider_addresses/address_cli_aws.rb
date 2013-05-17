module Cyoi::Cli::Addresses; end
class Cyoi::Cli::Addresses::AddressCliAws
  attr_reader :attributes
  attr_reader :hl

  def initialize(attributes, highline)
    @hl = highline
    @attributes = attributes.is_a?(Hash) ? Settingslogic.new(attributes) : attributes
    raise "@attributes must be Settingslogic (or Hash)" unless @attributes.is_a?(Settingslogic)
  end

  def perform_and_return_attributes
    unless valid_address?
      attributes["ip"] = "1.2.3.4"
    end
    export_attributes
  end

  # helper to export the complete nested attributes.
  def export_attributes
    attributes.to_nested_hash
  end


  def valid_address?
    attributes["ip"]
  end

  def display_confirmation
    puts "\n"
    puts "Confirming: Using address #{attributes.ip}"
  end
end

Cyoi::Cli::Address.register_address_cli("aws", Cyoi::Cli::Addresses::AddressCliAws)