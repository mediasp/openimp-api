require 'test/common'

class TestRelease < Test::Unit::TestCase
  def test_get_release
    release = CI::Metadata::Release.find(:upc => TEST_UPC)
    assert_instance_of CI::Metadata::Release, release
    tracks = release.tracks
    assert_instance_of Array, tracks
    assert_instance_of CI::Metadata::Track, tracks.first
  end

  def test_get_front_cover_for_release
    release = CI::Metadata::Release.find(:upc => TEST_UPC)
    assert_instance_of CI::Metadata::Release, release
    assert_instance_of String, release.main_artist
    front_cover = release.imagefrontcover
    assert_instance_of CI::File::Image, front_cover
  end

  def xtest_release_list
    list = CI::Metadata::Release.list
    assert_instance_of CI::Pager, list
    list.each do |page|
      assert_instance_of Array, page
      assert_instance_of CI::Metadata::Release, page.first
      break # we only bother to test the first
    end
  end
end
