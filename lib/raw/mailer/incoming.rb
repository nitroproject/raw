require "tmail"
require "facets/string/blank"

module Raw

# Add support for incoming mail handling.
#
# You need to setup your MTA to support incoming email
# handling. Here is an example for Postfix. Edit these files:
#
# /etc/postfix/master.cf:
# mailman  unix  -       n       n       -       -       pipe
#    flags= user=nobody argv=/path/to/ruby /path/to/app/script/runner.rb Mailer.receive(STDIN)
#
# /etc/postfix/main.cf:
# transport_maps = hash:/etc/postfix/transport
# virtual_mailbox_domains = lists.yourdomain.com
#
# /etc/postfix/transport:
# lists.yourdomain.com    mailman:
#
# Then run:
#
# sudo postmap transport
# sudo postfix stop
# sudo postfix start
#--
# IDEA: Creating a custom POP3 email fetcher is much better.
#++

module IncomingMailer

  # You can overide this class for specialized handling.

  def receive(mail)
  end

  module Self
    def receive(encoded)
#     mail = Raw::Mail.new_from_encoded(encoded)
      mail = TMail::Mail.parse(encoded)
      self.new.receive(mail)
    end
  end
end

end
