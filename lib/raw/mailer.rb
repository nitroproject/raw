require "socket"

require "facets/settings"

require "raw/mailer/mail"
require "raw/mailer/incoming"
require "raw/mailer/outgoing"

module Raw

# Handles incoming and outgoing emails. Can be called from
# a Controller or a standalone script (target of the MTA).

class Mailer < Mail
  is IncomingMailer
  is OutgoingMailer

  # The outgoing mail server configuration.

  setting :server, :default => {
    :address => "localhost",
    :port => 25,
    :domain => Socket.gethostname,
    :username => nil,
    :password => nil,
    :authentication => nil
  }, :doc => "The outgoing server configuration"

  # The delivery method. The following options are
  # supported:
  #
  # * :smtp
  # * :sendmail
  # * :test

  setting :delivery_method, :default => :smtp, :doc => "The delivery method"

  # Disable deliveries, useful for testing.

  setting :disable_deliveries, :default => false, :doc => "Dissable deliveries?"

  # The default template root.

  setting :template_dir, :default => "app/email", :doc => "The default template root"

  # The default from address

  setting :from, :default => "bot@nitroproject.org", :doc => "The default from address"

  # An array to store the delivered mails, useful
  # for testing.

  cattr_accessor :deliveries; @@deliveries = []
end

end
