require "cyoi/cli/provider_image/image_cli_base"
class Cyoi::Cli::Image::ImageCliOpenStack < Cyoi::Cli::Image::ImageCliBase

  def image_id
    "not implemented"
  end
end

Cyoi::Cli::Image.register_image_cli("openstack", Cyoi::Cli::Image::ImageCliOpenStack)
