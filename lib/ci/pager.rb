module CI
  # CI::Pager is a container object for paged result sets returned from certain CI API methods.
  # It contains an array of URIs for the pages of the result set; each of these URIs, when loaded,
  # should contain an array of result objects.
  # We wrap this behaviour here in a pretty simple fashion, exposing Enumerable and some Array methods.
  class Pager
    class << self
      alias :json_create :new
    end

    attr_reader :pages, :total_items

    def initialize(json_data)
      @pages = json_data['Pages']
      @total_items = json_data['NumberOfEntries']
    end

    include Enumerable

    def each
      @pages.length.times {|n| yield self[n]}
    end
    alias :each_page :each

    def reverse_each
      (@pages.length-1).downto(0) {|n| yield self[n]}
    end
    alias :reverse_each_page :reverse_each

    def [] n
      path = @pages[n]
      path_components = path.sub!(/^\//,'').split('/')
      @__deserializing_client.get(path_components)
    end
    alias :page :[]

    def length
      @pages.length
    end

    # An enumerable collection of all the items within the pages of the pager.
    # Allows you to forget that they're paginated altogether. Takes care of
    # reloading the items (which are typically have only a URL and class on them
    # in the pager page listing) before yielding them to you.
    # Has a length corresponding to the NumberOfEntries from the pager.
    def items
      # hmm, don't like this - need to formalize this __deserializing_client
      # hack
      Items.new(self, @__deserializing_client)
    end

    class Items
      def initialize(pager, client)
        @pager  = pager
        @client = client
      end

      include Enumerable

      def each
        @pager.each do |page|
          page.each do |item|
            # not sure where path_components comes from, but in the case of
            # paged stuff it seems to be there.
            yield @client.get(item.instance_variable_get("@path_components"))
          end
        end
      end

      def reverse_each
        @pager.reverse_each do |page|
          page.reverse_each do |item|
            # not sure where path_components comes from, but in the case of
            # paged stuff it seems to be there.
            yield @client.get(item.instance_variable_get("@path_components"))
          end
        end
      end

      def length
        @pager.total_items
      end
    end
  end
end
