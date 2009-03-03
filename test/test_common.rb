require 'test/unit'
require 'open-uri'
require File.dirname(__FILE__) + '/../lib/ci'

module TestCommon  
  TEST_TEXT_FILE = "#{File.dirname(__FILE__)}/test_assets/test_file.txt"
  TEST_IMAGE_FILE = "#{File.dirname(__FILE__)}/test_assets/test_image.jpg"
  TEST_UPC = 634904018320
  
  class << self
    attr_reader :host, :port, :protocol
    attr_accessor :username, :password
  end
  @username = 'playlouderapitest@ci-support.com'
  @password = nil
  @host = 'stage.api.cissme.com'
  @port = 80
  @protocol = :http
  
  def setup
    unless TestCommon.username
      print "\nUsername: "
      TestCommon.username = gets.chomp
    end
    unless TestCommon.password
      file = File.dirname(__FILE__)+'/.password'
      TestCommon.password = if File.exist?(file)
        File.read(file)
      else
        print "\nPassword: "
        gets
      end.chomp
    end
    CI::MediaFileServer.configure(TestCommon.username, TestCommon.password, {:host => TestCommon.host, :protocol => TestCommon.protocol, :port => TestCommon.port})
  end
  
  def test_truth
    assert true
  end
end