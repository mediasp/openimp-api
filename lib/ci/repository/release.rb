module CI::Repository
  class Release < Base

    def initialize(client)

    def model_class ; CI::Metadata::Release ; end

    def path_components(instance=nil)
      if instance
        if instance.upc
          cmps = ['release', 'upc', instance.upc]

          # If supplied, we can narrow the search by organisation to
          # avoid UPC clashes - API behaviour for clashes is as yet
          # undefined, and we can expect other changes
          if instance.organisation_id
            ['licensor', instance.organisation_id] + cmps
          else
            cmps
          end
        end
      else
        ['release']
      end
    end
  end
end
