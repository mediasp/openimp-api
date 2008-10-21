class CI::FileToken < CI
  ci_properties :Id, [:URL, :url], [:PlayURL, :play_url], :Unlimited, [:file, :file], :AttemptedDownloads, :SuccessfulDownloads, :MaxDownloadAttempts, :MaxDownloadSuccesses, :__REPRESENTATION__, :Valid, [:file, :file]
  
  def self.uri_path
    "/filestore"
  end
  
  def file=(file_hash)
    klass = file_hash['__class__'].sub('API', 'CI').constantize
    @params['file'] = klass.new(file_hash)
  end
  
end