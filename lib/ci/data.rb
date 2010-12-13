module CI
  module Data

    class ReleaseBatch < Asset
      attributes :Id, :name, :OrganisationName, :OrganisationDPID, :OrganisationId
      attributes :releases_completed, :releases_incomplete, :type => :release_array
      attributes :Status

      def self.list
        MediaFileServer.get(path_components)
      end

      def self.list_by_status(status)
        MediaFileServer.get(path_components, :query => {:status => status})
      end
    end

    class ImportRequest < ReleaseBatch
      def self.path_components(instance=nil)
        instance ? ['import', 'by_id', instance.id] : ['import']
      end
    end

    class Delivery < ReleaseBatch
      def self.path_components(instance=nil)
        instance ? ['delivery', instance.id] : ['delivery', 'to_me']
      end
    end

    class Offer < Asset
      attributes :UseType
      collections :Terms

      class Terms < Asset
        attributes :Began, :Ended, :PreOrderReleaseDate, :type => :date
        attributes :Price
        collections :Countries
      end
    end

  end
end
