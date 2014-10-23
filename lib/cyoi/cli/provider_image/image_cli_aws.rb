require "cyoi/cli/provider_image/image_cli_base"
class Cyoi::Cli::Image::ImageCliAws < Cyoi::Cli::Image::ImageCliBase

  def image_id
    trusty_image_id
  end

  # Ubuntu 14.04
  def trusty_image_id(region=nil)
    region = provider_client.attributes.region
    # http://cloud-images.ubuntu.com/locator/ec2/
    # version: 14.04 LTS
    # arch: amd64
    # instance type: ebs-ssd (not hvm)
    # Using release 20140927
    image_id = case region.to_s
    when "ap-northeast-1"
      "ami-df4b60de"
    when "ap-southeast-1"
      "ami-2ce7c07e"
    when "eu-west-1"
      "ami-f6b11181"
    when "sa-east-1"
      "ami-71d2676c"
    when "us-east-1"
      "ami-98aa1cf0"
    when "us-west-1"
      "ami-736e6536"
    when "eu-central-1"
      raise "Please let me know when http://cloud-images.ubuntu.com/locator/ec2/ releases a Trusty image for Frankfurt"
    when "cn-north-1"
      "ami-e642d0df"
    when "ap-southeast-2"
      "ami-1f117325"
    when "us-west-2"
      "ami-37501207"
    end
    image_id || raise("Please add Ubuntu 14.04 64bit (EBS SSD) AMI image id to aws.rb#trusty_image_id method for region '#{region}'")
  end

end

Cyoi::Cli::Image.register_image_cli("aws", Cyoi::Cli::Image::ImageCliAws)
