#!/usr/bin/env ruby

require 'ldap'
require 'ldap/schema'

require 'treequel'
require 'treequel/schema'
require 'treequel/mixins'
require 'treequel/constants'


# The object in Treequel that represents a connection to a directory, the
# binding to that directory, and the base from which all DNs start.
# 
# == Subversion Id
#
#  $Id$
# 
# == Authors
# 
# * Michael Granger <ged@FaerieMUD.org>
# 
# :include: LICENSE
#
#---
#
# Please see the file LICENSE in the base directory for licensing details.
#
class Treequel::Directory
	include Treequel::Loggable,
	        Treequel::Constants


	# SVN Revision
	SVNRev = %q$Rev$

	# SVN Id
	SVNId = %q$Id$

	# The default directory options
	DEFAULT_OPTIONS = {
		:host          => 'localhost',
		:port          => LDAP::LDAP_PORT,
		:connect_type  => :tls,
		:base          => '',
	}


	### Create a new Treequel::Directory with the given +options+. Options is a hash with one 
	### or more of the following key-value pairs:
	### 
	### [host]::
	###   The LDAP host to connect to.
	### [port]::
	###   The port to connect to.
	### [connect_type]::
	###   The type of connection to establish. Must be one of +:plain+, +:tls+, or +:ssl+.
	### [base]::
	###   The base DN of the directory.
	def initialize( options={} )
		options = DEFAULT_OPTIONS.merge( options )

		@host         = options[:host]
		@port         = options[:port]
		@connect_type = options[:connect_type]
		@base         = options[:base]

		@conn     = nil
		@bound_as = nil
	end


	######
	public
	######

	# The host to connect to.
	attr_accessor :host

	# The port to connect to.
	attr_accessor :port

	# The type of connection to establish
	attr_accessor :connect_type

	# The base DN of the directory.
	attr_accessor :base


	### Returns a string that describes the directory
	def to_s
		# bindname = self.bound? ? self.bound_as : "unbound"
		bindname ||= 'anonymous'

		return "%s:%d (%s, %s, %s)" % [
			self.host,
			self.port,
			self.base,
			self.connect_type,
			bindname
		  ]
	end

	### Return the LDAP::Conn object associated with this directory, creating it with the
	### current options if necessary.
	def conn
		return @conn ||= self.connect
	end


	### Bind as the specified +user_dn+ and +password+. If the optional +block+ is given,
	### it will be executed with the receiver bound, then returned to its previous state when
	### the block exits.
	def bind( user_dn, password )
		self.log.debug "Binding with connection %p as: %s" % [ self.conn, user_dn ]
		self.conn.bind( user_dn.to_s, password )
		@bound_as = user_dn.to_s
	end


	### Execute the provided +block+ after binding as +user_dn+ with the given +password+. After
	### the block returns, the original binding (if any) will be restored.
	def bound_as( user_dn, password )
		raise LocalJumpError, "no block given" unless block_given?
		previous_bind_dn = @bound_as
		self.with_duplicate_conn do
			self.bind( user_dn.to_s, password )
			yield
		end
	ensure
		@bound_as = previous_bind_dn
	end


	### Returns +true+ if the directory's connection has already established a binding.
	def bound?
		return self.conn.bound?
	end
	alias_method :is_bound?, :bound?


	### Ensure that the the receiver's connection is unbound.
	def unbind
		if @conn.bound?
			old_conn = @conn
			@conn = old_conn.dup
			old_conn.unbind
		end
	end


	### Return the RDN string to the given +dn+ from the base of the directory.
	def rdn_to( dn )
		base_re = Regexp.new( ',' + Regexp.quote(self.base) + '$' )
		return dn.sub( base_re, '' )
	end


	### Given a Treequel::Branch object, find its corresponding LDAP::Entry and return
	### it.
	def get_entry( branch )
		base = branch.base
		filter = branch.attr_pair

		self.log.debug "Looking up entry for %p from %s" % [ filter, base ]
		return self.conn.search2( base.to_s, SCOPE[:onelevel], filter ).first
	end


	### Fetch the schema from the server.
	def schema
		schemahash = self.conn.schema
		return Treequel::Schema.new( schemahash )
	end


	### Perform a +scope+ search at +base+ using the specified +filter+. The +scope+ argument
	### can be one of +:onelevel+, +:base+, or +:subtree+.
	def search( base, scope, filter, selectattrs=[], timeout=0, sortby=nil )
		timeout_s = timeout_us = 0
		sortattr = sortfunc = nil

		# Normalize the arguments into what LDAP::Conn#search2 expects
		base_dn = base.respond_to?( :dn ) ? base.dn : base
		scope = SCOPE[scope] if scope.is_a?( Symbol )

		if !timeout.nil? && !timeout.zero?
			timeout_s = self.timeout.truncate
			timeout_us = Integer((self.timeout - timeout_s) * 1_000_000) # convert to µsec
		end

		if sortby.respond_to?( :call )
			sortfunc = sortby
		elsif !sortby.nil?
			sortattr = sortby.to_s
		end

		# conn.search2(base_dn, scope, filter, attrs=nil, attrsonly=false,
		# 	sec=0, usec=0, s_attr=nil, s_proc=nil)
		self.log.debug {
			fmt = "Searching with: base_dn=%p, scope=%p, filter=%p, attrs=%p, " +
			      "attrsonly=false, sec=%p, usec=%p, s_attr=%p, s_proc=%p"
			fmt % [
				base_dn,
				scope,
				filter.to_s,
				selectattrs,
				timeout_s,
				timeout_us,
				sortattr,
				sortfunc
			]
		}
		results = self.conn.search2( base_dn, scope, filter.to_s, 
			selectattrs, false, 
			timeout_s, timeout_us,
			sortattr, sortfunc )

		return results.collect do |entry|
			Treequel::Branch.new_from_entry( entry, self )
		end
	end



	#########
	protected
	#########

	### Proxy method: return a new Branch with the new +attribute+ and +value+ as
	### its base.
	def method_missing( attribute, value, *extra_args )
		raise ArgumentError,
			"wrong number of arguments (%d for 1)" % [ extra_args.length + 1 ] unless
			extra_args.empty?
		return Treequel::Branch.new( self, attribute, value, self.base )
	end


	### Create a new LDAP::Conn object with the current host, port, and connect_type
	### and return it.
	def connect
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


	### Execute a block with a copy of the current connection, restoring the original
	### after the block returns.
	def with_duplicate_conn
		original_conn = self.conn
		@conn = original_conn.dup
		self.log.debug "Executing with %p, a copy of connection %p" % [ @conn, original_conn ]
		yield
	ensure
		self.log.debug "  restoring original connection %p." % [ original_conn ]
		@conn = original_conn
	end

end # class Treequel::Directory


