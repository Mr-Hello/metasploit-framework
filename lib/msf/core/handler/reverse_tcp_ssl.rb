# -*- coding: binary -*-
require 'rex/socket'
require 'thread'

require 'msf/core/handler/reverse_tcp'

module Msf
module Handler

###
#
# This module implements the reverse TCP handler.  This means
# that it listens on a port waiting for a connection until
# either one is established or it is told to abort.
#
# This handler depends on having a local host and port to
# listen on.
#
###
module ReverseTcpSsl

  include Msf::Handler::ReverseTcp

  #
  # Returns the string representation of the handler type, in this case
  # 'reverse_tcp_ssl'.
  #
  def self.handler_type
    return "reverse_tcp_ssl"
  end

  #
  # Returns the connection-described general handler type, in this case
  # 'reverse'.
  #
  def self.general_handler_type
    "reverse"
  end

  #
  # Initializes the reverse TCP SSL handler and adds the certificate option.
  #
  def initialize(info = {})
    super
    register_advanced_options(
      [
        OptPath.new('HandlerSSLCert', [false, "Path to a SSL certificate in unified PEM format"])
      ], Msf::Handler::ReverseTcpSsl)

  end

  #
  # Starts the listener but does not actually attempt
  # to accept a connection.  Throws socket exceptions
  # if it fails to start the listener.
  #
  def setup_handler
    if datastore['Proxies'] and not datastore['ReverseAllowProxy']
      raise RuntimeError, 'TCP connect-back payloads cannot be used with Proxies. Can be overriden by setting ReverseAllowProxy to true'
    end

    ex = false

    comm = select_comm
    local_port = bind_port
    addrs = bind_address

    addrs.each { |ip|
      begin

        self.listener_sock = Rex::Socket::SslTcpServer.create(
          'LocalHost' => ip,
          'LocalPort' => local_port,
          'Comm'      => comm,
          'SSLCert'   => datastore['HandlerSSLCert'],
          'Context'   =>
            {
              'Msf'        => framework,
              'MsfPayload' => self,
              'MsfExploit' => assoc_exploit
            })

        ex = false

        comm_used = comm || Rex::Socket::SwitchBoard.best_comm( ip )
        comm_used = Rex::Socket::Comm::Local if comm_used == nil

        if( comm_used.respond_to?( :type ) and comm_used.respond_to?( :sid ) )
          via = "via the #{comm_used.type} on session #{comm_used.sid}"
        else
          via = ""
        end

        print_status("Started reverse SSL handler on #{ip}:#{local_port} #{via}")
        break
      rescue
        ex = $!
        print_error("Handler failed to bind to #{ip}:#{local_port}")
      end
    }
    raise ex if (ex)
  end

end

end
end
