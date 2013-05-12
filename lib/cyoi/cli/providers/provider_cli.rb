module Cyoi; module Cli; module Providers; end; end; end

class Cyoi::Cli::Providers::ProviderCli
  attr_reader :attributes
  attr_reader :hl

  def initialize(attributes, highline)
    @hl = highline
    @attributes = attributes.is_a?(Hash) ? Settingslogic.new(attributes) : attributes
    raise "@attributes must be Settingslogic (or Hash)" unless @attributes.is_a?(Settingslogic)
  end

  # helper to export the complete nested attributes.
  def export_attributes
    attributes.to_nested_hash
  end

  # Only a subclass can represent valid infrastruct
  # If using this class directly, then it has not yet decided
  # which provider/infrastructure to use
  def valid_infrastructure?
    false
  end

  def display_confirmation
    raise "please implement in subclass"
  end

  def say(message, *args)
    puts(message)
  end
end