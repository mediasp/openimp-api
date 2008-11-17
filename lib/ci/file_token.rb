#Represents a File Token which can be given to an anonymous end user, allowing them to download a specific file.
#
#FileTokens have the following additional properties, as described in the CI API docs:
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
#
#You shouldn't really have any need to initialize this class directly or alter it, and changed cannot be persisted back to the CI backend as a result.
#It can be created by calling create_token or an associated method on an instance of CI::File or one of its subclasses.

module CI
  class FileToken < Asset
    api_attr_reader   :URL, :PlayURL, :Unlimited, :RedirectWhenExpiredUrl
    api_attr_reader   :SuccessfulDownloads, :AttemptedDownloads, :MaxDownloadAttempts, :MaxDownloadSuccesses
    api_attr_reader   :Valid
    api_attr_boolean  :Valid, :Unlimited
    has_one           :file
    self.base_url = "/filetoken"

    # The CI API exposes a FileToken creation via several different URLs. However we will never want to create
    # a file token that we do not already have a file to hand, and hence we only use the FileStore URL.
    def self.create file, properties = {}
      post File.url(file.id, 'createfiletoken'), properties
    end

    # As an alternative a FileToken object can be created and the appropriate values set, then the save method
    # called which creates the token on the server and its details loaded.
    def save!
      FileToken.create file, {  :RedirectWhenExpiredUrl => redirect_when_expired_url,
                                :Unlimited => unlimited,
                                :MaxDownloadAttempts => max_download_attempts,
                                :MaxDownloadSuccesses => max_download_successes   }
    end
  end
end