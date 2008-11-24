require File.dirname(__FILE__) + '/test_common.rb'
class TestMusic < Test::Unit::TestCase
  include TestCommon
=begin
  def test_list_encodings
    assert_nil CI::Encoding.encodings
    CI::Encoding.synchronize
    assert_not_nil CI::Encoding.encodings
    encoding = CI::Encoding.new(:name => 'wma_192')
    assert_instance_of CI::Encoding, encoding
    assert_equal encoding.name, 'wma_192'
  end

  def test_get_release
    release = CI::Release.new(:id => TEST_UPC)
    assert_instance_of CI::Release, release
    tracks = release.tracks
    assert_instance_of Array, tracks
  end

  def test_get_front_cover_for_release
    release = CI::Release.new(:id => TEST_UPC)
    assert_instance_of CI::Release, release
    front_cover = release.imagefrontcover
    assert_instance_of CI::File::Image, front_cover
  end
=end
end