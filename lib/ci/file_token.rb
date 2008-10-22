#Represents a File Token which can be given to an anonymous end user, allowing them to download a specific file
#FileTokens have the following additional properties, as described in the CI API docs.
#* id
#* url
#* play_url
#* unlimited
#* file (this is loaded eagerly - will not perform another request for the association.)
#* attemted_downloads
#* successful_downloads
#* max_download_attepts
#* max_download_successes
#* valid
#* You shouldn't really have any need to initialize this class directly or alter it, and changed cannot be persisted back to the CI backend as a result.
#* It can be created by calling create_token or an associated method on an instance of CI::File or one of its subclasses.

class CI::FileToken < CI
  ci_properties :Id, [:URL, :url], [:PlayURL, :play_url], :Unlimited, [:file, :file], :AttemptedDownloads, :SuccessfulDownloads, :MaxDownloadAttempts, :MaxDownloadSuccesses, :Valid
  self.uri_path = "/filestore"
  
  #:nodoc:
  def file=(file_hash)
    klass = file_hash['__class__'].sub('API', 'CI').constantize
    @params['file'] = klass.new(file_hash)
  end
  
end