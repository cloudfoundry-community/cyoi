require "cyoi/cli/providers/provider_cli"
class Cyoi::Cli::Providers::ProviderCliAws < Cyoi::Cli::Providers::ProviderCli
  def choose_region_if_necessary
    attributes["region"] = "us-west-2"
  end

  def collect_credentials
    attributes["credentials"] = {}
  end
end

Cyoi::Cli::Provider.register_provider_cli("aws", Cyoi::Cli::Providers::ProviderCliAws)