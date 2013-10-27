require "cyoi/cli/provider_image/image_cli_base"
class Cyoi::Cli::Image::ImageCliAws < Cyoi::Cli::Image::ImageCliBase

  def image_id
    ubuntu_1304_image_id
  end

  # Ubuntu 13.04
  def ubuntu_1304_image_id
    region = provider_client.attributes.region
    # http://cloud-images.ubuntu.com/locator/ec2/
    image_id = case region.to_s
    when "ap-northeast-1"
      "ami-6b26ab6a"
    when "ap-southeast-1"
      "ami-2b511e79"
    when "eu-west-1"
      "ami-3d160149"
    when "sa-east-1"
      "ami-28e43e35"
    when "us-east-1"
      "ami-c30360aa"
    when "us-west-1"
      "ami-d383af96"
    when "ap-southeast-2"
      "ami-84a333be"
    when "us-west-2"
      "ami-bf1d8a8f"
    end
    image_id || raise("Please add Ubuntu 13.04 64bit (EBS) AMI image id to aws.rb#raring_image_id method for region '#{region}'")
  end
end

Cyoi::Cli::Image.register_image_cli("aws", Cyoi::Cli::Image::ImageCliAws)
