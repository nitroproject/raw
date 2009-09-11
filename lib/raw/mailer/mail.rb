require "net/smtp"

require "facets/settings"

module Raw

# Encapsulates an email message.
#--
# FIXME: Replace this with TMail::Mail for a much more robust
# solution. At the moment this is only used in the outgoing
# Mailer, the incoming Mailer uses TMail.
#++

class Mail

  # The default content type.

  setting :default_content_type, :default => 'text/plain', :doc => 'The default content type'

  # The default charset.

  setting :default_charset, :default => 'UTF-8', :doc => 'The default character set'

  # Encode the subject?

  setting :encode_subject, :default => false, :doc => 'Encode the subject?'

  # Sender, can be an array.

  attr_accessor :from

  # The list of the recipients, can be arrays.

  attr_accessor :to, :cc, :bcc

  # The subject

  attr_accessor :subject
  alias_method :title, :subject

  # The body of the message.

  attr_accessor :body

  # Reply to.

  attr_accessor :reply_to

  # Sent on

  attr_accessor :sent_on

  # Encode the subject?

  attr_accessor :encode_subject

  # The content type of the message.

  attr_accessor :content_type

  # The charset used to encode the message.

  attr_accessor :charset

  # Additional headers

  attr_accessor :headers

  def initialize(from = nil, to = nil, subject = nil, body = nil)
    @from, @to, @subject, @body = from, to, subject, body
    @headers = {}
    @content_type = self.class.default_content_type
    @charset = self.class.default_charset
  end

  def parse_headers
    @from = @headers["From"]
    @to = @headers["To"]
    @cc = @headers["Cc"]
    @bcc = @headers["Bcc"]
    @subject = @headers["Subject"]
  end

  # Accept string or IO.

  def self.new_from_encoded(encoded)
    if encoded.is_a? String
      require "stringio"
      encoded = StringIO.new(encoded)
    end

    f = encoded

    # the following code is copied from mailread.rb

    unless defined? f.gets
      f = open(f, "r")
      opened = true
    end

    _headers = {}
    _body = []
    begin
      while line = f.gets()
        line.chop!
        next if /^From /=~line  # skip From-line
        break if /^$/=~line     # end of header

        if /^(\S+?):\s*(.*)/=~line
          (attr = $1).capitalize!
          _headers[attr] = $2
        elsif attr
          line.sub!(/^\s*/, '')
          _headers[attr] += "\n" + line
        end
      end

      return unless line

      while line = f.gets()
        break if /^From /=~line
        _body.push(line)
      end
    ensure
      f.close if opened
    end

    mail = Mail.new
    mail.headers = _headers
    mail.body = _body.join("\n")
    mail.parse_headers

    return mail
  end

  def [](key)
    @headers[key]
  end

  def []=(key, value)
    @headers[key] = value
  end

  # Returns the Mail message in encoded format.

  def encoded
    raise "No body defined" unless @body
    raise "No sender defined" unless @from
    raise "No recipients defined" unless @to

    # gmosx: From is typically NOT an array.

    from = @from.is_a?(Array) ? @from.join(", ") : @from
    buf = "From: #{from}\n"

    to = @to.is_a?(Array) ? @to.join(", ") : @to
    buf << "To: #{to}\n"

    if @cc
      cc = @cc.is_a?(Array) ? @cc.join(", ") : @cc
      buf << "Cc: #{cc}\n"
    end

    if @bcc
      bcc = @bcc.is_a?(Array) ? @bcc.join(", ") : @bcc
      buf << "Bcc: #{bcc}\n"
    end

    buf << "Subject: #@subject\n" if @subject

    buf << "Content-Type: #@content_type; charset=#@charset\n"

    buf << "\n"
    buf << @body

    return buf
  end
end

end
