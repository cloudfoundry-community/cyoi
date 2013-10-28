module Cyoi; module Cli; module AutoDetection; end; end; end

class Cyoi::Cli::AutoDetection::AutoDetectionFog
  # Displays a prompt for known IaaS that are configured
  # within .fog config file if found.
  #
  # If no ~/.fog file found or user chooses "Alternate credentials"
  # then no changes are made to settings.
  #
  # For example:
  #
  # 1. AWS (default)
  # 2. AWS (bosh)
  # 3. Alternate credentials
  # Choose infrastructure:  1
  #
  # If .fog config only contains one provider, do not prompt.
  #
  # fog config file looks like:
  # :default:
  #   :aws_access_key_id:     PERSONAL_ACCESS_KEY
  #   :aws_secret_access_key: PERSONAL_SECRET
  # :bosh:
  #   :aws_access_key_id:     SPECIAL_IAM_ACCESS_KEY
  #   :aws_secret_access_key: SPECIAL_IAM_SECRET_KEY
  #
  # Convert this into:
  # { "AWS (default)" => {:aws_access_key_id => ...}, "AWS (bosh)" => {...} }
  #
  # Then display options to user to choose.
  #
  # Currently detects following fog providers:
  # * AWS
  # * OpenStack
  #
  # If "Alternate credentials" is selected, then user is prompted for fog
  # credentials:
  # * provider?
  # * access keys?
  # * API URI or region?
  #
  # Sets (unless 'Alternate credentials' is chosen)
  # * settings.provider.name
  # * settings.provider.credentials
  #
  # For AWS, the latter has keys:
  #   {:aws_access_key_id, :aws_secret_access_key}
  #
  # For OpenStack, the latter has keys:
  #   {:openstack_username, :openstack_api_key, :openstack_tenant
  #      :openstack_auth_url, :openstack_region }
  def auto_detection_choices
    fog_choices = {}
    # Prepare menu options:
    # each provider/profile name gets a menu choice option
    fog_config.inject({}) do |iaas_options, fog_profile|
      profile_name, profile = fog_profile
      if profile[:aws_access_key_id]
        fog_choices["AWS (#{profile_name})"] = {
          "name" => "aws",
          "provider" => "AWS",
          "aws_access_key_id" => profile[:aws_access_key_id],
          "aws_secret_access_key" => profile[:aws_secret_access_key]
        }
      end
      if profile[:openstack_username]
        choice = {
          "name" => "openstack",
          "provider" => "OpenStack",
          "openstack_username" => profile[:openstack_username],
          "openstack_api_key" => profile[:openstack_api_key],
          "openstack_tenant" => profile[:openstack_tenant],
          "openstack_auth_url" => profile[:openstack_auth_url],
        }
        choice["openstack_region"] = profile[:openstack_region] if profile[:openstack_region]
        fog_choices["OpenStack (#{profile_name})"] = choice
      end
    end
    fog_choices
  end

  def fog_config
    @fog_config ||= begin
      if File.exists?(File.expand_path(fog_config_path))
        puts "Auto-detected infrastructure API credentials at #{fog_config_path} (override with $FOG)"
        YAML.load_file(File.expand_path(fog_config_path))
      else
        {}
      end
    end
  end

  def fog_config_path
    ENV['FOG'] || "~/.fog"
  end

end
