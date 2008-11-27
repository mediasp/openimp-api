require 'cgi'
require 'net/http'
require 'net/https'

module Net
  class HTTP
    class HTTPGenericRequest
      CHUNK_SIZE = 4096

      def send_request_with_body_stream(sock, ver, path, f)
        unless content_length() or chunked?
          raise ArgumentError, "Content-Length not given and Transfer-Encoding is not `chunked'"
        end
        supply_default_content_type
        write_header sock, ver, path
        if chunked? then
          while s = f.read(CHUNK_SIZE)
            sock.write(sprintf("%x\r\n", s.length) << s << "\r\n")
          end
          sock.write "0\r\n\r\n"
        else
          while s = f.read(CHUNK_SIZE)
            sock.write s
          end
        end
      end
    end

    class Post
      protected
      CRLF = "\r\n"
      ALLOWED_DELIMITER_TOKENS = ["0".."9", "A".."Z", "a".."z"].inject("") { |s, r| s + r.to_a.join } + "'()+_,-./:=?"
      RANDOM_RANGE = ALLOWED_DELIMITER_TOKENS.length

      def create_mime_delimiter length = 30
        srand
        (1..[length, 70].min).inject("") { |s, i| "#{s}#{ALLOWED_DELIMITER_TOKENS[rand(RANDOM_RANGE), 1]}" }
      end

      public
      def multipart sub_type, bodies = [], preamble = nil, epilogue = ""
        delimiter = create_mime_delimiter
        self['Content-Type'] = "multipart/#{sub_type}; boundary=\"#{delimiter}\""
        separator = "#{CRLF}--#{delimiter}#{CRLF}"
        self.body = "#{preamble || CRLF}#{separator}#{bodies.join(separator)}#{CRLF}--#{delimiter}--#{CRLF}#{epilogue}"
        self['Content-Length'] = self.body.length.to_s
      end
    end
  end
end


module Enumerable #:nodoc:
  def map_to_hash container = {}
    inject(container) { |hash, item| hash.merge!(yield(item) || {}) }
  end

  def cartesian other
    inject([]) { |array, x| array << other.collect { |y| [x, y] } }
  end

  def map_with_index
    result = []
    each_with_index {|x, i| result << yield(x, i)}
    result
  end
end

class String
  def to_method_name
    gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').gsub(/([a-z\d])([A-Z])/,'\1_\2').tr("-", "_").downcase
  end
end

class Symbol
  def to_method_name
    self.to_s.to_method_name
  end
end

module Kernel
  def with_aliased_namespace original, synonym, &block
    s = synonym.to_s.to_sym
    Object.send(:remove_const, s) if  old_binding = (Object.const_get(s) rescue nil)
    Object.const_set(s, original)
    result = yield
    Object.send(:remove_const, s)
    Object.const_set(s, old_binding) if old_binding
    result
  end
end