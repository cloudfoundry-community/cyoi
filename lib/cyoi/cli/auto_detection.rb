module Cyoi; module Cli; module AutoDetection; end; end; end

require "cyoi/cli/auto_detection/auto_detection_fog"

class Cyoi::Cli::AutoDetection::UI
  attr_reader :attributes
  attr_reader :hl

  def initialize(attributes, highline)
    @hl = highline
    @attributes = attributes.is_a?(Hash) ? ReadWriteSettings.new(attributes) : attributes
    raise "@attributes must be ReadWriteSettings (or Hash)" unless @attributes.is_a?(ReadWriteSettings)
  end

  def perform
    # Display menu of choices
    # Include "Alternate credentials" as the last option
    if aggregated_detector_choices.keys.size > 0
      hl.choose do |menu|
        menu.prompt = "Choose an auto-detected infrastructure:  "
        aggregated_detector_choices.each do |label, credentials|
          menu.choice(label) do
            attributes.set("name", credentials.delete("name"))
            attributes.set("credentials", credentials)
          end
        end
        menu.choice("Alternate credentials") { false }
      end
    end
  end

  # helper to export the complete nested attributes.
  def export_attributes
    attributes.to_nested_hash
  end

  def aggregated_detector_choices
    @aggregated_detector_choices ||= begin
      detectors.inject({}) do |choices, detector_class|
        detector = detector_class.new
        choices.merge!(detector.auto_detection_choices)
      end
    end
  end

  def detectors
    [
      Cyoi::Cli::AutoDetection::AutoDetectionFog
    ]
  end
end
