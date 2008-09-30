require File.dirname(__FILE__) + '/test_helper.rb'

TEST_ASSET_FILE = "#{File.dirname(__FILE__)}/test_assets/test_file.txt"

class TestCI < Test::Unit::TestCase
  def setup
    CI.username = 'playlouderapitest@ci-support.com'
    CI.password = 'foo52bim'
  end
  
  def test_truth
    assert true
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
    @uploaded_id = c.id
    @uploaded_data = c.data
  end  

  def test_find_file
    c = CI::File.find(@uploaded_id)
    assert_instance_of CI::File, c
    assert_equal c.id, @uploaded_id
    assert_equal c.data, @uploaded_data
  end
   
end
