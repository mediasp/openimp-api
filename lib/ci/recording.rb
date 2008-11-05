class CI::Recording < CI
  ci_properties :tracks, :LabelName, :files, :Composers, :Lyricists, :Producers, :MainArtist, :Artists, :Mixers, :Publishers, :ISRC, :FeaturedArtists, :Duration
  self.uri_path = "/recording/isrc"
  
  alias_method :id, :isrc
  
  def tracks
    @params['tracks'] || []
  end
  
  def tracks=(tracks)
    @params['tracks'] = tracks.map do |track|
      klass = track['__class__'].sub('API', 'CI').constantize
      klass.new(track)
    end
  end
  
  def files
    @params['files'] || []
  end
  
  def files=(files)
    @params['files'] = files.map do |file|
      klass = file['__class__'].sub('API', 'CI').constantize
      klass.new(file)
    end
  end
  
  def newest_track
    CI::Track.do_request(:get, "#{id}/newest")
  end
  
  #TODO add methods to get encodings etc.
  
end