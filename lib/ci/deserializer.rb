# Extracted in to a module so code can use json fixtures for tests
module CI::Deserializer

  # Classes must respond to .json_create(properties, client)
  # They will be passed a hash of json properties; any class instances within
  # this property hash will already have been recursively instantiated.
  #
  # Note we don't use the JSON library's inbuilt instantiation feature, as we
  # want to use this restricted custom class mapping:
  CLASS_MAPPING = {
    'MFS::Metadata::ArtistAppearance' => CI::Metadata::ArtistAppearance,
    'MFS::Metadata::Encoding'         => CI::Metadata::Encoding,
    'MFS::Metadata::Recording'        => CI::Metadata::Recording,
    'MFS::Metadata::Release'          => CI::Metadata::Release,
    'MFS::Metadata::Track'            => CI::Metadata::Track,
    'MFS::Pager'                      => CI::Pager,
    'MFS::FileToken'                  => CI::FileToken,
    'MFS::File'                       => CI::File,
    'MFS::File::Image'                => CI::File::Image,
    'MFS::File::Audio'                => CI::File::Audio,
    'MFS::ContextualMethod'           => CI::ContextualMethod,
    'MediaAPI::Data::ReleaseBatch'    => CI::Data::ReleaseBatch,
    'MediaAPI::Data::ImportRequest'   => CI::Data::ImportRequest,
    'MediaAPI::Data::Delivery'        => CI::Data::Delivery,
    'MediaAPI::Data::Offer'           => CI::Data::Offer,
    'MediaAPI::Data::Offer::Terms'    => CI::Data::Offer::Terms
  }


  # block - visitor to each mapped class that is instantiated
  def parse_json(json, &block)
    instantiate_classes_in_parsed_json(JSON.parse(json), &block)
  end

  def instantiate_classes_in_parsed_json(data, &block)
    case data
    when Hash
      ci_class = data.delete('__CLASS__')
      mapped_data = {}
      data.each {|key,value| mapped_data[key] = instantiate_classes_in_parsed_json(value, &block)}

      if ci_class
          klass = CLASS_MAPPING[ci_class]
        if klass
          klass.json_create(mapped_data).tap do |instance|
            yield instance if block_given?
          end
        else
          warn("Unknown class in CI json: #{ci_class}")
          mapped_data
        end
      else
        mapped_data
      end

    when Array
      data.map {|item| instantiate_classes_in_parsed_json(item, &block)}

    else
      data
    end
  end

end
