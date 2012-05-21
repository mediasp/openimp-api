module CI::Repository

  # Extends the File repository to add resizing methods
  class File::Image < File

    RESIZE_METHODS = [ 'NOMODIFIER', 'EXACT', 'SQUARE', 'SMALLER', 'LARGER' ]
    RESIZE_TYPES = { 'jpeg' => 'jpg', 'png' => 'png', 'tiff' => 'tiff', 'gif' => 'gif', 'bmp' => 'bmp' }

    def model_class ; CI::File::Image ; end

    def mfs_class_name
      "MFS::File::Image"
    end

    def resize(file, width, height, mode = :NOMODIFIER, properties = {})
      @client.post(path_for(file, 'contextualmethod', 'Resize'),
        properties.merge(:targetX => width, :targetY => height, :resizeType => "IMAGE_RESIZE_#{mode}", :Synchronous => 1))
    end

    def resize!(file, *args)
      result_file = resize(file, *args)
      file.send(:replace_with!, result_file)
      file
    end

  end
end
