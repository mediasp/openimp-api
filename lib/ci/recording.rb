module CI
  module Metadata
    class Recording < Asset
      attributes    :ISRC, :LabelName, :MainArtist, :external_identifiers
      collections   :Producers, :Mixers, :Composers, :Lyricists, :FeaturedArtists, :Artists
      collections   :Publishers, :tracks, :files
      attributes :Duration, :type => :duration

      def self.path_components(instance=nil)
        if instance
          ['recording', 'isrc', instance.isrc] if instance.isrc
        else
          ['recording']
        end
      end
    end

    #TODO add methods to get encodings etc.
  end
end
