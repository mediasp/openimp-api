require File.dirname(__FILE__) + '/test_common.rb'

class TestFilestore < Test::Unit::TestCase
  include TestCommon

  def setup
    super
    if !@uploaded_id then
      c = CI::File.disk_file(TEST_ASSET_FILE, "text/plain")
      c = c.store
      @uploaded_id = c.id
      @uploaded_data = c.content
    end
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
    c = CI::File.disk_file(TEST_ASSET_FILE, 'text/plain')
    assert_instance_of CI::File, c
    original_data = c.content
    c = c.store
    assert_instance_of CI::File, c
    assert_match /^\/filestore\//, c.__representation__
    assert_not_nil c.sha1_digest_base64
    assert_not_nil c.mime_minor
    assert_not_nil c.mime_major
    assert_not_nil c.id
    c.content = nil
    c.retrieve_content
    assert_equal c.content, original_data
  end  

  def test_find_file
    c = CI::File.new(:id => @uploaded_id)
    assert_instance_of CI::File, c
    assert_not_nil c.sha1_digest_base64
    assert_not_nil c.mime_minor
    assert_not_nil c.mime_major
    assert_equal "/filestore/#{@uploaded_id}", c.__representation__
    assert_equal c.id, @uploaded_id
    assert_equal c.content, @uploaded_data
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
end