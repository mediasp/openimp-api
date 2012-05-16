require 'test/unit'
require 'yaml'

require 'ci'

begin
  TEST_CONFIG = YAML.load_file("#{File.dirname(__FILE__)}/config.yml")
rescue
  puts "Couldn't load test config in test/config.yml. Please make one from test/config.template.yml"
  exit 1
end

TEST_TEXT_FILE = "#{File.dirname(__FILE__)}/test_assets/test_file.txt"
TEST_IMAGE_FILE = "#{File.dirname(__FILE__)}/test_assets/test_image.jpg"
TEST_UPC = TEST_CONFIG[:test_upc]
TEST_AUDIO_FILE = TEST_CONFIG[:test_audio_file]
TEST_ORGANISATION_ID = TEST_CONFIG[:test_organisation_id]

if TEST_CONFIG[:log_stdout]
  require 'logger'
  logger = Logger.new(STDOUT)
  logger.level = Logger.const_get((TEST_CONFIG[:log_level] || 'INFO').upcase)
  TEST_CONFIG[:logger] = logger
end

CLIENT = CI::Client.new(TEST_CONFIG[:uri], TEST_CONFIG)