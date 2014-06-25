require "cyoi/cli/provider_blobstore/blobstore_cli_base"
class Cyoi::Cli::Blobstore::BlobstoreCliAws < Cyoi::Cli::Blobstore::BlobstoreCliBase
end

Cyoi::Cli::Blobstore.register_cli("aws", Cyoi::Cli::Blobstore::BlobstoreCliAws)
