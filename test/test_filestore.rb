require 'test/common'
require 'open-uri'
require 'tempfile'

class TestFilestore < Test::Unit::TestCase
  def store_text_file
    if !@text_id then
      file = CI::File.disk_file(TEST_TEXT_FILE, "text/plain")
      file.store!
      @text_id = file.id
      @text_data = file.content
    end
    file
  end

  def store_image_file(as_class=CI::File::Image)
    if !@image_id then
      file = as_class.disk_file(TEST_IMAGE_FILE, "image/jpeg")
      file.store!
      @image_id = file.id
      @image_data = file.content
    end
    file
  end

  def test_mime_type_parsing
    mime_major = 'image'
    mime_minor = 'jpeg'
    file = CI::File.new
    file.mime_type = "#{mime_major}/#{mime_minor}"
    assert_equal mime_major, file.mime_major
    assert_equal mime_minor, file.mime_minor
  end

  def test_upload_file
    file = CI::File.disk_file(TEST_TEXT_FILE, 'text/plain')
    assert_instance_of CI::File, file
    original_data = file.content
    file.store!
    assert_instance_of CI::File, file
    assert_equal 'filestore', file.path_components.first
    assert_not_nil file.sha1_digest_base64
    assert_not_nil file.mime_minor
    assert_not_nil file.mime_major
    assert_not_nil file.id
    assert_equal "STORED", file.stored
    file.content = nil
    file.retrieve_content
    assert_equal file.content, original_data

    filename = Tempfile.new('ci-file-test').path
    file.download_to_file(filename)
    assert_equal File.read(filename), File.read(TEST_TEXT_FILE)
  end

  def test_find_file
    store_text_file
    file = CI::File.find(:id => @text_id)
    assert_instance_of CI::File, file
    assert_not_nil file.sha1_digest_base64
    assert_not_nil file.mime_minor
    assert_not_nil file.mime_major
    assert_equal ['filestore', @text_id.to_s], file.path_components
    assert_equal file.id, @text_id
    assert_equal file.content, @text_data
  end

  def test_find_audio_file
    file = CI::File.find(:id => TEST_AUDIO_FILE)
    assert_instance_of CI::File::Audio, file
    assert_not_nil file.sha1_digest_base64
    assert_not_nil file.mime_minor
    assert_not_nil file.mime_major
    assert_not_nil file.bit_rate
    assert_instance_of Fixnum, file.duration
    assert_instance_of Fixnum, file.crc32
    assert_equal ['filestore', TEST_AUDIO_FILE.to_s], file.path_components
    assert_equal file.id, TEST_AUDIO_FILE
  end

  def test_get_token
    store_text_file
    file = CI::File.find(:id => @text_id)
    token = CI::FileToken.create(file)
    assert_instance_of CI::FileToken, token
    assert_not_nil token.path_components
    assert_equal file.path_components, token.file.path_components
    assert_equal file.content, token.file.content
    assert_equal file.content, open(token.url) {|r| r.read}
  end

  def test_file_deletion
    store_text_file
    file = CI::File.find(:id => @text_id)
    assert_instance_of CI::File, file
    placeholder = file.delete
    assert_instance_of CI::File, placeholder
    assert_equal "DELETED", placeholder.stored
  end

  def test_image_file_handling
    store_image_file(CI::File::Image)
    file = CI::File.find(:id => @image_id)
    assert_instance_of CI::File::Image, file
    assert_instance_of Fixnum, file.width

    contextual_methods = file.contextual_methods
    assert_instance_of Array, contextual_methods
    contextual_methods.each do |method|
      assert_instance_of CI::ContextualMethod, method
    end
    digest = file.sha1_digest_base64
    height, width = file.height, file.width
    file.resize! 200, 300, :EXACT, { :targetType => 'jpg' }
    assert_equal 200, file.width.to_i
    assert_equal 300, file.height.to_i
    assert_not_equal digest, file.sha1_digest_base64
  end

  def test_direct_uploaded_image
    uploaded_as_image = store_image_file(CI::File::Image)
    assert_instance_of Fixnum, uploaded_as_image.width
  end

  def xtest_filestore_list
    list = CI::File.list
    assert_instance_of CI::Pager, list
    list.each do |page|
      assert_instance_of Array, page
      assert_instance_of CI::File, page.first
      break # we only bother to test the first
    end
  end
end

