require File.dirname(__FILE__) + '/test_helper.rb'

TEST_ASSET_FILE = "#{File.dirname(__FILE__)}/test_assets/test_file.txt"
TEST_IMAGE_FILE = "#{File.dirname(__FILE__)}/test_assets/test_image.jpg"

class TestFilestore < Test::Unit::TestCase
  def setup
    unless CI.username
      print "\nUsername: "
      CI.username = gets.chomp
    end
    unless CI.password
      print "\nPassword: "
      CI.password = gets.chomp
      print "\n"
    end
    
    c = CI::File.new_from_file(TEST_ASSET_FILE, 'text/plain')
    c.store
    @uploaded_id = c.id
    @uploaded_data = c.data
  end
  
  def test_mime_type_parsing
    mime_major = 'image'
    mime_minor = 'jpeg'
    f = CI::File.new
    f.mime_type = "#{mime_major}/#{mime_minor}"
    assert_equal mime_major, f.mime_major
    assert_equal mime_minor, f.mime_minor
  end
  
  def test_upload_file
    c = CI::File.new_from_file(TEST_ASSET_FILE, 'text/plain')
    assert_instance_of CI::File, c
    c.store 
    assert_match /^\/filestore\//, c.__representation__
    assert_not_nil c.sha1_digest_base64
    assert_not_nil c.mime_minor
    assert_not_nil c.mime_major
    assert_not_nil c.id
    original_data = c.data
    c.data = nil
    c.retrieve
    assert_equal c.data, original_data
  end  

  def test_find_file
    c = CI::File.find(@uploaded_id)
    assert_instance_of CI::File, c
    assert_not_nil c.sha1_digest_base64
    assert_not_nil c.mime_minor
    assert_not_nil c.mime_major
    assert_equal "/filestore/#{@uploaded_id}", c.__representation__
    assert_equal c.id, @uploaded_id
    assert_equal c.data, @uploaded_data
  end
  
  def test_get_token
    file = CI::File.find(@uploaded_id)
    token = file.create_token
    assert_instance_of CI::FileToken, token
    assert_not_nil token.url
    assert_equal file.__representation__, token.file.__representation__
    assert_equal file.data, open(token.url) {|r| r.read}
  end
   
  def test_cast_to_image
    test_image = CI::File.new_from_file(TEST_IMAGE_FILE, 'image/jpeg')
    image = test_image.cast_as(CI::File::Image)
    assert_instance_of CI::File::Image, image
    assert_not_nil image.height
    assert_not_nil image.width
  end
  
  def test_image_resize
    test_image = CI::File::Image.new_from_file(TEST_IMAGE_FILE, 'image/jpeg')
    assert_instance_of CI::File::Image, test_image
    height = 600
    width = 800
    resized = test_image.resize(width, height)
    assert_instance_of CI::File::Image, resized
    assert_equal height, resized.height
    assert_equal width, resized.width
  end
  
  def test_image_resize_with_token
    test_image = CI::File::Image.new_from_file(TEST_IMAGE_FILE, 'image/jpeg')
    assert_instance_of CI::File::Image, test_image
    height = 600
    width = 800
    max_download_attempts = 5
    max_download_successes = 2
    token = test_image.resize(width, height, nil, nil, {:MaxDownloadAttempts => max_download_attempts, :MaxDownloadSuccesses => max_download_successes})
    assert_instance_of CI::FileToken, token
    assert_equal height, token.file.height
    assert_equal width, token.file.width
    assert_equal max_download_successes, token.max_download_successes
    assert_equal max_download_attempts, token.max_download_attempts
  end
end
