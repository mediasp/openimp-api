require File.dirname(__FILE__) + '/test_common.rb'

class TestFilestore < Test::Unit::TestCase
  include TestCommon

  def setup
    super
    store_text_file
    store_image_file
  end

  def store_text_file
    if !@text_id then
      file = CI::File.disk_file(TEST_TEXT_FILE, "text/plain")
      file.store!
      @text_id = file.id
      @text_data = file.content
    end
    file
  end

  def store_image_file
    if !@image_id then
      file = CI::File.disk_file(TEST_IMAGE_FILE, "image/jpeg")
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
    assert_match /^\/filestore\//, file.__representation__
    assert_not_nil file.sha1_digest_base64
    assert_not_nil file.mime_minor
    assert_not_nil file.mime_major
    assert_not_nil file.id
    assert_equal "STORED", file.stored
    file.content = nil
    file.retrieve_content
    assert_equal file.content, original_data
  end  

  def test_find_file
    file = CI::File.new(:id => @text_id)
    assert_instance_of CI::File, file
    assert_not_nil file.sha1_digest_base64
    assert_not_nil file.mime_minor
    assert_not_nil file.mime_major
    assert_equal "/filestore/#{@text_id}", file.__representation__
    assert_equal file.id, @text_id
    assert_equal file.content, @text_data
  end

  def test_get_token
    file = CI::File.new(:id => @text_id)
    token = CI::FileToken.create(file)
    assert_instance_of CI::FileToken, token
    assert_not_nil token.url
    assert_equal file.__representation__, token.file.__representation__
    assert_equal file.content, token.file.content
    assert_equal file.content, open(token.url) {|r| r.read }
  end

  def test_file_deletion
    file = CI::File.new(:id => @text_id)
    assert_instance_of CI::File, file
    placeholder = file.delete
    assert_instance_of CI::File, placeholder
    assert_equal "DELETED", placeholder.stored
  end

  def test_enumerate_contextual_methods
    file = CI::File.new(:id => @image_id)
    assert_instance_of CI::File, file
    file = file.sub_type("image/jpeg")
    assert_instance_of CI::File::Image, file
    contextual_methods = file.contextual_methods
    assert_instance_of Array, contextual_methods
    contextual_methods.each do |method|
      assert_instance_of CI::ContextualMethod, method
    end
  end
end