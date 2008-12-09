module CI
  module Metadata
    class Recording < Asset
      attributes    :ISRC, :LabelName, :MainArtist
      collections   :Producers, :Mixers, :Composers, :Lyricists, :FeaturedArtists, :Artists, :Publishers, :tracks, :files

      def self.path_components(instance=nil)
        if instance
          ['recording', 'isrc', instance.isrc] if instance.isrc
        else
          ['recording']
        end
      end
      
      # http://en.wikipedia.org/wiki/ISO_8601#Durations although we only handle the PT00H00M00S format of this for now
      # we expose this as an integer number of seconds
      def duration
        case @parameters['Duration']
        when /^PT(\d\d)H(\d\d)M(\d\d)S$/i
          $1.to_i*3600 + $2.to_i*60 + $3.to_i
        end
      end
      
      def duration=(value)
        @parameters['Duration'] = case value
        when String then value
        when Integer then
          mins, secs = value.divmod(60)
          hours, mins = mins.divmod(60)
          sprintf("PT%02dH%02dM%02dS", hours, mins, secs)
        end
      end
    end

    #TODO add methods to get encodings etc.
  end
end