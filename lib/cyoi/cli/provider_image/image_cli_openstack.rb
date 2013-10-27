require "cyoi/cli/provider_image/image_cli_base"
class Cyoi::Cli::Image::ImageCliOpenStack < Cyoi::Cli::Image::ImageCliBase

  def image_id
    choose_image_id
  end

  def choose_image_id
    hl.choose do |menu|
      menu.prompt = "Choose image: "
      images.each do |image|
        label, code = image[:label], image[:code]
        menu.choice(label) { return code }
      end
    end
  end

  def images
    provider_client.fog_compute.images.map { |image| { label: image.name, code: image.id }}
  end
end

Cyoi::Cli::Image.register_image_cli("openstack", Cyoi::Cli::Image::ImageCliOpenStack)
