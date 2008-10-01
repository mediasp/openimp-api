class CI::FileToken < CI
  ci_properties :Id, [:URL, :url], [:PlayURL, :play_url], :Unlimited, [:file, :file], :AttemptedDownloads, :SuccesfulDownloads, :MaxDownloadAttempts, :MaxDownloadSuccesses, :__REPRESENTATION__, :Valid, [:file, :file]
  
  def file=(file_hash)
    File.find(hash)
  end
  
  
end