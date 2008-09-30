class CI::File::Image < CI::File
  ci_properties :Width, :Height
  
  RESIZE_METHODS = [
    'NOMODIFIER',
    'EXACT',
    'SQUARE',
    'SMALLER',
    'LARGER'
  ]
  
  def resize(target_width, target_height, method='NOMODIFIER')
    raise  "resize method not recognised" unless RESIZE_METHODS.include?(method)
  end
end