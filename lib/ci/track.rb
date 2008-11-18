module CI
  class Track < Asset
    api_attr_reader   :ReferenceTitle, :SubTitle, :DisplayArtist, :ParentalWarningType
    api_attr_reader   :Genres, :SubGenres
    api_attr_reader   :PLineYear, :PLineText, :CLineYear, :CLineText
    api_attr_reader   :SequenceNumber, :VolumeNumber, :TrackNumber
    api_attr_reader   :files, :recording, :release
    has_one           :recording
    has_one           :release
    has_many          :files
    #TODO getter and setter for files array, recording, release
    #TODO better way of doing inter-class associations.


    def self.find_track_by_upc_and_sequence_number upc, sequence_number
    end
  end
end