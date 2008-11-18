module CI
  class Asset
    
    def self.class_inheritable_accessor(*args)
      args.each do |arg|
        class_eval "
          def self.#{arg}
            @#{arg} ||= superclass.#{arg} unless self == CI::Asset
          end 
          def self.#{arg}=(val)
            @#{arg}=val
          end
        "
      end
    end
    class_inheritable_accessor  :base_url, :api_class_name
    class_inheritable_accessor  :attributes, :boolean_attributes
    self.base_url = ""
    self.attributes = SymmetricTranslationTable.new(:api, :ruby)
    self.boolean_attributes = []

  private
    def self.url id, action = nil
      MediaFileServer.resolve self.base_url, id, action
    end

    def url action = nil
      Asset.url id, action
    end

  public
    def self.api_attr api_method, writeable = false #:nodoc:
      ruby_method = api_method.to_method_name
      MediaFileServer::API_ATTRIBUTES.define_api_term api_method, ruby_method
      define_method ruby_method, lambda { @parameters[api_method] }
      define_method "#{ruby_method}=", lambda { |v|
        @parameters[api_method] = (MediaFileServer::BOOLEAN_ATTRIBUTES.include?(api_method) ? (v == 1) : v)
      } if writeable
    end

    def self.api_attr_reader *api_methods #:nodoc:
      Array.new(api_methods).each { |attribute| api_attr attribute, false }
    end

    def self.api_attr_accessor *api_methods #:nodoc:
      Array.new(api_methods).each { |attribute| api_attr attribute, true }
    end

    def self.api_attr_boolean *api_methods
      Array.new(api_methods).each { |attribute| MediaFileServer::BOOLEAN_ATTRIBUTES << attribute }
    end

    def self.has_many api_attribute
      ruby_method = api_attribute.to_method_name
      define_method ruby_method, lambda { @parameters[api_attribute] || [] }
      define_method "#{ruby_method}=", lambda { |hashes|
        @parameters[api_attribute] = hashes.map { |hash| Asset.create hash[:__CLASS__] }
        }
    end

    def self.has_one api_attribute, options = {}
      ruby_method = api_attribute.to_method_name
      define_method "#{ruby_method}=", lambda { |hash| @parameters[api_attribute] = Asset.create(hash[:__CLASS__]) }
    end

    # Create an instance of this class from a 
    def self.json_create o
      asset = allocate
      o.each { |k, v| asset.instance_variable_set "@#{k}", v unless k == '__CLASS__' }
      asset
    end

    # Find a resource by its API id and instantiate an appropriate class.
    def self.load id
      MediaFileServer.get(url(id))
    end

    # We use a custom constructor to automatically load the correct object from the
    # CI MFS system if the parameters to +new+ include an +id+.
    def self.new parameters={}, *args
      unless parameters.has_key?('id') then
        asset = allocate
        asset.send :initialize, *([parameters] + args)
        asset
      else
        load id
      end
    end

    api_attr_reader :Id, :__CLASS__, :__REPRESENTATION
    
    def initialize parameters = {}
      @parameters = {}
      parameters.each { |k, v| self.send("#{k}=", v) rescue nil }
    end

    # Reload the current asset
    def refresh
      File.load id
    end

    def to_json *a
      self.parameters.inject({'__CLASS__' => self.class.name.sub(/CI/i, 'API')}) { |h, (k, v)|
        h[k] = case v
        when true then 1
        when false then 0
        else v.to_json(*a)
        end
      }.to_json(*a)
    end

    [:get, :get_octet_stream, :head, :delete].each do |m|
      class_eval <<-METHOD
        def #{m}
          MediaFileServer.#{m} url()
        end
      METHOD
    end

    def post properties
      MediaFileServer.post url(), properties
    end

    def put content_type, data
      MediaFileServer.put url(), content_type, data
    end
  end
end