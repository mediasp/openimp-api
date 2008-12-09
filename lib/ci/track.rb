module CI
  module Metadata
    class Track < Asset
      attributes    :ReferenceTitle, :SubTitle, :DisplayArtist, :ParentalWarningType
      attributes    :PLineYear, :PLineText, :CLineYear, :CLineText
      attributes    :SequenceNumber, :VolumeNumber, :TrackNumber
      attributes    :recording, :release
      collections   :files, :Genres, :SubGenres
      #TODO getter and setter for files array, recording, release
      #TODO better way of doing inter-class associations.

      def self.path_components(instance=nil)
        if instance && instance.release && instance.sequence_number
          instance.release.path_components + ['track', instance.sequence_number]
        end
      end
    end
  end
end