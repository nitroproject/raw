require "facets/openobject"

require "raw/mailer/template"

module Raw

# Add support for outgoing mail handling.

module OutgoingMailer

  # The root directory where the templates reside.

  attr_accessor :template_dir

  def initialize(from = nil, to = nil, subject = nil, body = MailTemplate.new)
    super
    @charset = Mailer.default_charset.dup
    @encode_subject = Mailer.encode_subject
    @template_dir = Mailer.template_dir
  end

  # OutgoingMailer class-level extensions.

  module Self

    def method_missing(method_symbol, *params) #:nodoc:
      case method_symbol.id2name
        when /^create_([_a-z]*)/
          create_from_method($1, *params)
        when /^deliver_([_a-z]*)/
          begin
            deliver(send("create_" + $1, *params))
          rescue Object => ex
            error ex
            raise ex # FIXME
          end
      end
    end

    def mail(from, to, subject, body, timestamp = nil, headers = {}, encode = Mail.encode_subject, charset = Mail.default_charset) #:nodoc:
      deliver(create(from, to, subject, body, timestamp, headers, charset))
    end

    def create(from, to, subject, body, timestamp = nil, headers = {}, encode = Mail.encode_subject, content_type = Mail.default_content_type, charset = Mail.default_charset) #:nodoc:
      m = Mail.new
      m.to, m.subject, m.body, m.from = to, ( encode ? quoted_printable(subject, charset) : subject ), body, from
      m.sent_on = timestamp.respond_to?("to_time") ? timestamp.to_time : (timestamp || Time.now)
      m.content_type = content_type
      headers.each do |k, v|
        m[k] = v
      end
      return m
    end

    def deliver(mail) #:nodoc:
      # gmosx, FIXME: for some STUPID reason, delivery_method
      # returns nil, investigate.

      Mailer.delivery_method = :smtp unless Mailer.delivery_method

      unless Mailer.disable_deliveries
        send("perform_delivery_#{Mailer.delivery_method}", mail)
      end
    end

    def quoted_printable(text, charset) #:nodoc:
      text = text.gsub(/[^a-z ]/i) { "=%02x" % $&[0] }.gsub( / /, "_" )
      "=?#{charset}?Q?#{text}?="
    end

    private

    def create_from_method(method_name, *params)
      mailer = new

      mailer.send(method_name, *params)

      unless mailer.body.is_a? String
        mailer.body = render_body(method_name, mailer)
      end

      mail = create(
        mailer.from, mailer.to, mailer.subject,
        mailer.body, mailer.sent_on,
        mailer.headers, mailer.charset
      )

      mail.cc = mailer.cc if mailer.cc
      mail.bcc = mailer.bcc if mailer.bcc

      return mail
    end

    # Render the body by expanding the template

    def render_body(method_name, mailer)
      #--
      # FIXME: allow for multiple extensions (txt, html, etc)
      #++
      mailer.body.render("#{mailer.template_dir}/#{method_name.to_s}.html")
    end

    # Deliver emails using SMTP.

    def perform_delivery_smtp(mail) # :nodoc:
      c = Mailer.server
      Net::SMTP.start(c[:address], c[:port], c[:domain], c[:username], c[:password], c[:authentication]) do |smtp|
        smtp.send_message(mail.encoded, mail.from, *[mail.to, mail.cc, mail.bcc].compact)
      end
    end

    # Deliver emails using sendmail.

    def perform_delivery_sendmail(mail) # :nodoc:
      IO.popen("/usr/sbin/sendmail -i -t", "w+") do |sm|
        sm.print(mail.encoded)
        sm.flush
      end
    end

    # Used for testing, does not actually send the
    # mail.

    def perform_delivery_test(mail) # :nodoc:
      deliveries << mail
    end

    def perform_delivery_dump(mail)
      info "\n#{mail.body}"
    end

  end # Self

end

end
