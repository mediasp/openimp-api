class CI::Track < CI
  ci_properties :PLineYear, :SubGenres, :files, :recording, :CLineText, :ReferenceTitle, :Genres, :SequenceNumber, :SubTitle, :ParentalWarningType, :TrackNumber, :CLineYear, :release, :PLineText, :DisplayArtist, :VolumeNumber
  #TODO This isn't gettable or puttable on it's own, it only exists as a property of a Recording and / or Release. This should be enforced somehow.
  #TODO getter and setter for files array, recording, release
  #TODO better way of doing inter-class associations.
end