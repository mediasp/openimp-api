require File.dirname(__FILE__) + '/test_common.rb'

class TestFilestore < Test::Unit::TestCase
  include TestCommon

  def setup
    super
    if !@uploaded_id then
      file = CI::File.disk_file(TEST_ASSET_FILE, "text/plain")
      file.store!
      @uploaded_id = file.id
      @uploaded_data = file.content
    end
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
    file = CI::File.disk_file(TEST_ASSET_FILE, 'text/plain')
    assert_instance_of CI::File, file
    original_data = file.content
    file.store!
    assert_instance_of CI::File, file
    assert_match /^\/filestore\//, file.__representation__
    assert_not_nil file.sha1_digest_base64
    assert_not_nil file.mime_minor
    assert_not_nil file.mime_major
    assert_not_nil file.id
    file.content = nil
    file.retrieve_content
    assert_equal file.content, original_data
  end  

  def test_find_file
    file = CI::File.new(:id => @uploaded_id)
    assert_instance_of CI::File, file
    assert_not_nil file.sha1_digest_base64
    assert_not_nil file.mime_minor
    assert_not_nil file.mime_major
    assert_equal "/filestore/#{@uploaded_id}", file.__representation__
    assert_equal file.id, @uploaded_id
    assert_equal file.content, @uploaded_data
  end

  def test_get_token
    file = CI::File.new(:id => @uploaded_id)
    token = CI::FileToken.create(file)
    assert_instance_of CI::FileToken, token
    assert_not_nil token.url
    assert_equal file.__representation__, token.file.__representation__
    assert_equal file.content, token.file.content
    assert_equal file.content, open(token.url) {|r| r.read }
  end

  def test_file_deletion
    file = CI::File.new(:id => @uploaded_id)
    assert_instance_of CI::File, file
    placeholder = file.delete
    assert_instance_of CI::File, placeholder
    assert_equal "DELETED", placeholder.stored
  end
end