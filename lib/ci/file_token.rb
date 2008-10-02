class CI::FileToken < CI
  ci_properties :Id, [:URL, :url], [:PlayURL, :play_url], :Unlimited, [:file, :file], :AttemptedDownloads, :SuccessfulDownloads, :MaxDownloadAttempts, :MaxDownloadSuccesses, :__REPRESENTATION__, :Valid, [:file, :file]
  
  def self.uri_path
    "/filestore"
  end
  
  def file=(file_hash)
    @params[:file_id]= file_hash['Id'].to_i
  end
  
  def file
    @params[:file] ||= File.find(@params[:file_id])
  end
  
end