class CI::File < CI
  ci_properties :Id, :MimeMajor, :MimeMinor, :SHA1DigestBase64, :FileSize, :__REPRESENTATION__
  
  self.allowed_requests = {
    :retrieve_by_id =>  [:get, '/?/retrieve', :id],
  }
  
  self.uri_path = '/filestore'
  
  alias_method :sha1_digest_base64, :s_h_a1_digest_base64 #ActiveSupport's String#underlinize gets confused.  We'll add  a convenience method for humans.
  alias_method :sha1_digest_base64=, :s_h_a1_digest_base64= 
  
  def mime_type
    "#{mime_major}/#{mime_minor}"
  end
  
  def mime_type=(mime)
    mime = mime.split('/')
    mime_major, mime_minor = *mime
  end
  
end