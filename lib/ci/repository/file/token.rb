module CI::Repository

  # Repository for creating secure tokens for accessing content in CIs
  # filestory that can be handed out without needing authorization
  class File::Token < Base

    def initialize(client, file_repository)
      super(client)
      @file_repository = file_repository
    end

    def path_components(instance=nil)
      if instance
        ['filetoken', instance.id] if instance.id
      else
        ['filetoken']
      end
    end

    # The MFS API exposes a FileToken creation via several different URLs.
    # However we will never want to create a file token that we do not already
    # have a file to hand, and hence we only use the FileStore URL.
    def create(file, properties = {})
      path = @file_repository.path_for(file, 'createfiletoken')
      @client.post(path, properties).tap do |token|
        token.file = file
      end
    end

    # As an alternative a FileToken object can be created and the appropriate
    # values set, then the save method called which creates the token on the
    # server and its details loaded.
    def save(file_token, file)
      create(file, {
          :RedirectWhenExpiredUrl => file_token.redirect_when_expired_url,
          :Unlimited              => file.unlimited,
          :MaxDownloadAttempts    => file.max_download_attempts,
          :MaxDownloadSuccesses   => file.max_download_successes
      })
    end

  end
end
