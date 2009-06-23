#!/usr/bin/env ruby

require 'time'

require 'ldap'
require 'ldap/schema'

require 'treequel'
require 'treequel/mixins'
require 'treequel/constants'


# A wrapper around the connection to the LDAP server that handles
# reconnect attempts, normalizes exceptions, and referrals.
#
# == Subversion Id
#
#  $Id$
#
# == Authors
#
# * Michael Granger <ged@FaerieMUD.org>
# * Mahlon E. Smith <mahlon@martini.nu>
#
# :include: LICENSE
#
#--
#
# Please see the file LICENSE in the base directory for licensing details.
#
class Treequel::Connection
	include Treequel::Loggable,
	        Treequel::Constants

	extend Treequel::Delegation

	# SVN Revision
	SVNRev = %q$Rev$

	# SVN Id
	SVNId = %q$Id$

	# The default number of times to attempt to reconnect
	DEFAULT_RETRY_LIMIT = 5

	# The default number of seconds after which the connection retry counter resets.
	DEFAULT_RETRY_LIMIT_TIMEOUT = 5


	### Create a new Treequel::Connection object that will wrap an LDAP::Conn object
	### created with the given +host+, +port+, and +connect_type+.
	def initialize( host, port, connect_type=:tls )
		@host         = host
		@port         = port
		@connect_type = connect_type

		@ldapconn     = nil
	end


	######
	public
	######

	# Hook up LDAP::Conn's instance methods through the connection accessor.
	def_method_delegators :ldapconn, *LDAP::Conn.instance_methods( false )


	### Return the wrapped LDAP::Conn object this Connection wraps.
	def ldapconn
		@ldapconn ||= self.create_connection
	end


	#########
	protected
	#########

	### Create a new LDAP::Conn object with the current host, port, and connect_type
	### and return it.
	def create_connection
		conn = nil

		case @connect_type
		when :tls
			self.log.debug "Connecting using TLS to %s:%d" % [ @host, @port ]
			conn = LDAP::SSLConn.new( @host, @port, true )
		when :ssl
			self.log.debug "Connecting using SSL to %s:%d" % [ @host, @port ]
			conn = LDAP::SSLConn.new( host, port )
		else
			self.log.debug "Connecting using an unencrypted connection to %s:%d" % [ @host, @port ]
			conn = LDAP::Conn.new( host, port )
		end

		conn.set_option( LDAP::LDAP_OPT_PROTOCOL_VERSION, 3 )
		return conn
	end



end # class Treequel::Connection


