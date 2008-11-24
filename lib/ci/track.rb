module CI
  class Track < Asset
    attributes    :ReferenceTitle, :SubTitle, :DisplayArtist, :ParentalWarningType
    attributes    :PLineYear, :PLineText, :CLineYear, :CLineText
    attributes    :SequenceNumber, :VolumeNumber, :TrackNumber
    attributes    :recording
    collections   :files, :Genres, :SubGenres
    references    :release
    #TODO getter and setter for files array, recording, release
    #TODO better way of doing inter-class associations.


    def self.find_track_by_upc_and_sequence_number upc, sequence_number
    end
  end
end