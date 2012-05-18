module CI::Repository

  # base repository for finding out about newly delivered releases
  class Batch < Base

    def model_class ; CI::Data::ReleaseBatch ; end

    def list
      @client.get(path_for())
    end

    def list_by_status(status)
      @client.get(path_for(), :query => {:status => status})
    end
  end

  # Methods for accessing import requests - this is content that is delivered
  # directly, without going through the usual CI channels
  class Batch::ImportRequest < Batch
    def path_components(instance=nil)
      instance ? ['import', 'by_id', instance.id] : ['import']
    end
  end

  # Methods for accessing deliveries - this is content that is delivered by
  # content providers using CI's services
  class Batch::Delivery < Batch
    def path_components(instance=nil)
      instance ? ['delivery', instance.id] : ['delivery', 'to_me']
    end
  end


end
