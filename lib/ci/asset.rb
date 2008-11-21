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
    self.base_url = ""

    def self.url id, *actions
      MediaFileServer.resolve self.base_url, id, actions.join("/")
    end

    def self.with_api_attribute api_attribute
      ruby_method = api_attribute.to_method_name
      api_key = api_attribute.to_sym
      yield ruby_method, api_key
    end

    def self.api_attr_accessor *api_methods #:nodoc:
      Array.new(api_methods).each do |api_attribute|
        with_api_attribute(api_attribute) do |ruby_method, api_key|
          define_method(ruby_method) do
            @parameters[api_key]
          end
          define_method("#{ruby_method}=") do
            |v| @parameters[api_key] = v
          end
        end
      end
    end

    def self.has_many api_attribute
      with_api_attribute(api_attribute) do |ruby_method, api_key|
        define_method(ruby_method) do
          @parameters[api_attribute] || []
        end
        define_method("#{ruby_method}=") do |hashes|
          @parameters[api_key] = hashes.map { |hash| Asset.create hash[:__CLASS__] }
        end
      end
    end

    def self.references api_attribute
      with_api_attribute(api_attribute) do |ruby_method, api_key|
        define_method(ruby_method) do
           @parameters[api_key].respond_to?(:__representation__) ? @parameters[api_key] : (@parameters[api_key] = Asset.load(@parameters[api_key]["__REPRESENTATION__"], :representation => true))
        end
      end
    end

    # We use a custom constructor to automatically load the correct object from the
    # CI MFS system if the parameters to +new+ include an +id+.
    def self.new parameters={}, *args
      if api_id = (parameters[:Id] || parameters[:id]) then
        load api_id
      else
        asset = allocate
        asset.send :initialize, parameters, *args
        asset
      end
    end

    # Find a resource by its API id or representation url and instantiate an appropriate class.
    def self.load id, options = {}
      MediaFileServer.get(options[:representation] ? id : url(id))
    end

    # Create an instance of this class from a 
    def self.json_create properties
      asset = allocate
      asset.send :initialize, properties
      asset
    end

    api_attr_accessor :Id, :__REPRESENTATION__

    def initialize parameters = {}
      @parameters = {}
      parameters.delete_if { |k, v| k == '__CLASS__' }.each { |k, v| self.send("#{k.to_method_name}=", v) rescue nil }
    end

    def url action = nil
      self.class.url id, action
    end

    # Reload the current asset
    def refresh
      File.load id
    end

    def to_json *a
      self.parameters.inject({'__CLASS__' => self.class.name.sub(/CI::/i, 'API::')}) { |h, (k, v)|
        h[k] = case v
        when true then 1
        when false then 0
        else v.to_json(*a)
        end
      }.to_json(*a)
    end

    [:get, :get_octet_stream, :head, :delete].each do |m|
      class_eval <<-METHOD
        def #{m} action = nil
          MediaFileServer.#{m} url(action)
        end
      METHOD
    end

    def post properties, action = nil
      MediaFileServer.post url(action), properties
    end

    def put content_type, data
      MediaFileServer.put url(), content_type, data
    end

  protected
    def parameters
      @parameters.clone
    end
  end
end