module CI
  class Track < Asset
    api_attr_reader :PLineYear, :SubGenres, :files, :recording, :CLineText, :ReferenceTitle, :Genres, :SequenceNumber, :SubTitle, :ParentalWarningType, :TrackNumber, :CLineYear, :release, :PLineText, :DisplayArtist, :VolumeNumber
    #TODO This isn't gettable or puttable on it's own, it only exists as a property of a Recording and / or Release. This should be enforced somehow.
    #ci_has_one :recording
    #ci_has_one :release
    #ci_has_many :files
    #TODO getter and setter for files array, recording, release
    #TODO better way of doing inter-class associations.
  end
end