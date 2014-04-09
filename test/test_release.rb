if RUBY_VERSION <= '1.8.7'
  require 'test/common'
else
  require_relative 'common'
end

class TestRelease < Test::Unit::TestCase

  def setup
    @release_repo = CI::Repository::Release.new(CLIENT)
  end

  def test_get_release
    release = @release_repo.find(:upc => TEST_UPC)
    assert_instance_of CI::Metadata::Release, release
    assert_instance_of Date, release.release_date

    tracks = release.tracks
    assert_instance_of Array, tracks
    assert_instance_of CI::Metadata::Track, tracks.first
    assert_instance_of CI::Metadata::Recording, tracks.first.recording
    assert_instance_of Fixnum, tracks.first.recording.duration

    assert_instance_of Hash, tracks.first.recording.external_identifiers
    assert_instance_of Hash, release.external_identifiers

    assert_instance_of Array, release.offers
    assert !release.offers.empty?
    assert !tracks.first.offers.empty?
    all_offers = [tracks.map {|t| t.offers}, release.offers].flatten
    all_offers.each do |offer|
      assert_instance_of CI::Data::Offer, offer
      offer.terms.each do |terms|
        assert_instance_of CI::Data::Offer::Terms, terms
        assert_instance_of Date, terms.began
        assert_instance_of Array, terms.countries
      end
    end
  end

  def test_lookup_by_organisation
    release = @release_repo.find(:upc => TEST_UPC,
      :organisation_id => TEST_ORGANISATION_ID)

    assert_instance_of CI::Metadata::Release, release
  end

  def test_get_front_cover_for_release
    release = @release_repo.find(:upc => TEST_UPC)
    assert_instance_of CI::Metadata::Release, release
    assert_instance_of String, release.main_artist
    front_cover = release.imagefrontcover
    assert_instance_of CI::File::Image, front_cover
  end

  def xtest_release_list
    list = @release_repo.list
    assert_instance_of CI::Pager, list
    list.each do |page|
      assert_instance_of Array, page
      assert_instance_of CI::Metadata::Release, page.first
      break # we only bother to test the first
    end
  end
end
