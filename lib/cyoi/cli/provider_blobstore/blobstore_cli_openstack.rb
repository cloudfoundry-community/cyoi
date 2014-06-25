require "cyoi/cli/provider_blobstore/blobstore_cli_base"
class Cyoi::Cli::Blobstore::BlobstoreCliOpenStack < Cyoi::Cli::Blobstore::BlobstoreCliBase
end

Cyoi::Cli::Blobstore.register_cli("openstack", Cyoi::Cli::Blobstore::BlobstoreCliOpenStack)
