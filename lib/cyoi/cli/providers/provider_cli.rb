module Cyoi; module Cli; module Providers; end; end; end

class Cyoi::Cli::Providers::ProviderCli
  attr_reader :attributes

  def initialize(attributes)
    @attributes = attributes.is_a?(Hash) ? Settingslogic.new(attributes) : attributes
    raise "@attributes must be Settingslogic (or Hash)" unless @attributes.is_a?(Settingslogic)
  end

  # helper to export the complete nested attributes.
  def export_attributes
    attributes.to_nested_hash
  end
end