module CI
  class Track < Asset
    api_attr_accessor :ReferenceTitle, :SubTitle, :DisplayArtist, :ParentalWarningType
    api_attr_accessor :Genres, :SubGenres
    api_attr_accessor :PLineYear, :PLineText, :CLineYear, :CLineText
    api_attr_accessor :SequenceNumber, :VolumeNumber, :TrackNumber
    api_attr_accessor :files, :recording, :release
    has_many          :files
    #TODO getter and setter for files array, recording, release
    #TODO better way of doing inter-class associations.


    def self.find_track_by_upc_and_sequence_number upc, sequence_number
    end
  end
end