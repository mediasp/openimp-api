require 'thread'

module CI::Repository

  # Repository for encodings
  class Encoding < Base

    def initialize(*args)
      super
      @cache_lock = Mutex.new
    end

    def model_class ; CI::Metadata::Encoding ; end

    def path_components(instance=nil)
      if instance
        ['encoding', instance.name] if instance.name
      else
        ['encoding']
      end
    end

    def list
      @client.get(path_for)
    end

    def cache_encodings!
      @cache_lock.synchronize do
        @encodings ||= begin
          encodings = {}
          list.each {|e| encodings['/'+e.path_components.join('/')] = e}
          encodings
        end
      end
    end

  end
end
