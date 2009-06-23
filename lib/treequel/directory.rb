#!/usr/bin/env ruby

require 'time'

require 'ldap'
require 'ldap/schema'

require 'treequel'
require 'treequel/connection'
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
# * Mahlon E. Smith <mahlon@martini.nu>
#
# :include: LICENSE
#
#--
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
		:base          => nil,
		:binddn        => nil,
		:pass          => nil
	}

	# Default mapping of SYNTAX OIDs to conversions. See #add_syntax_mapping for more
	# information on what a valid conversion is.
	DEFAULT_SYNTAX_MAPPING = {
		OIDS::BIT_STRING_SYNTAX       => lambda { |bs| bs[0..-1].to_i(2) },
		OIDS::BOOLEAN_SYNTAX          => { 'true' => true, 'false' => false },
		OIDS::GENERALIZED_TIME_SYNTAX => lambda {|string| Time.parse(string) },
		OIDS::UTC_TIME_SYNTAX         => lambda {|string| Time.parse(string) },
		OIDS::INTEGER_SYNTAX          => lambda {|string| Integer(string) },
	}


	#################################################################
	###	C L A S S   M E T H O D S
	#################################################################

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
	### [binddn]::
	###   The DN of the user to bind as.
	### [pass]::
	###   The password to use when binding.
	def initialize( options={} )
		options         = DEFAULT_OPTIONS.merge( options )

		@host           = options[:host]
		@port           = options[:port]
		@connect_type   = options[:connect_type]

		@conn           = nil
		@bound_as       = nil

		@base           = options[:base] || self.get_default_base_dn
		@syntax_mapping = DEFAULT_SYNTAX_MAPPING.dup

		# Immediately bind if credentials are passed to the initializer.
		if ( options[:binddn] && options[:pass] )
			self.bind( options[:binddn], options[:pass] )
		end
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
	alias_method :dn, :base


	### Returns a string that describes the directory
	def to_s
		return "%s:%d (%s, %s, %s)" % [
			self.host,
			self.port,
			self.base,
			self.connect_type,
			self.bound? ? @bound_as : 'anonymous'
		  ]
	end


	### Return a human-readable representation of the object suitable for debugging
	def inspect
		return %{#<%s:0x%0x %s:%d (%s) base=%p, bound as=%s, schema=%s>} % [
			self.class.name,
			self.object_id / 2,
			self.host,
			self.port,
			@conn ? "connected" : "not connected",
			self.base,
			@bound_as ? @bound_as.dump : "anonymous",
			@schema ? @schema.inspect : "(schema not loaded)",
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
		user_dn = user_dn.dn if user_dn.respond_to?( :dn )

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
			self.bind( user_dn, password )
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
		return dn.to_s.sub( base_re, '' )
	end


	### Given a Treequel::Branch object, find its corresponding LDAP::Entry and return
	### it.
	def get_entry( branch )
		base = branch.base
		filter = branch.rdn

		self.log.debug "Looking up entry for %p from %s" % [ filter, base ]
		return self.conn.search2( base.to_s, SCOPE[:onelevel], filter ).first
	end


	### Fetch the schema from the server.
	def schema
		unless @schema
			schemahash = self.conn.schema
			@schema = Treequel::Schema.new( schemahash )
		end

		return @schema
	end


	### Perform a +scope+ search at +base+ using the specified +filter+. The +scope+ argument
	### can be one of +:onelevel+, +:base+, or +:subtree+. Results will be returned as instances
	### of the given +collectclass+.
	def search( base, scope, filter, selectattrs=[], timeout=0, sortby=nil )
		timeout_s = timeout_us = 0
		sortattr = ''
		sortfunc = nil
		base_dn = nil
		collectclass = nil

		# Normalize the arguments into what LDAP::Conn#search2 expects
		if base.respond_to?( :dn )
			base_dn = base.dn
			collectclass = base.class
		else
			base_dn = base
			collectclass = Treequel::Branch
		end

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
		#	sec=0, usec=0, s_attr=nil, s_proc=nil)
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
			collectclass.new_from_entry( entry, self )
		end
	end


	### Modify the entry specified by the given +dn+ with the specified +mods+, which can be
	### either an Array of LDAP::Mod objects or a Hash of attribute/value pairs.
	def modify( branch, mods )
		normattrs = self.normalize_attributes( mods )
		self.log.debug "Modifying %s with attributes: %p" % [ branch.dn, normattrs ]
		self.conn.modify( branch.dn, normattrs )
	end


	### Delete the entry specified by the given +branch+.
	def delete( branch )
		self.log.info "Deleting %s from the directory." % [ branch ]
		self.conn.delete( branch.dn )
	end


	### Create a new Branch relative to the specified +branch+ with the given +rdn+ and 
	### +newattrs+ hash.
	def create( branch, rdn, newattrs={} )
		rdnattr, rdnval = rdn.split( /=/, 2 )
		newdn = rdn + ',' + branch.dn

		newattrs[rdnattr] ||= []
		newattrs[rdnattr] << rdnval
		normattrs = self.normalize_attributes( newattrs )

		self.log.debug "Creating an entry at %s with the attributes: %p" % [ newdn, normattrs ]
		self.conn.add( newdn, normattrs )

		return branch.class.new( self, rdnattr, rdnval, branch )
	end


	### Copy the entry from the specified +branch+ to a new entry specified by +newdn+ with the
	### given +attributes+. Returns a new branch object for the new entry.
	def copy( branch, newdn, attributes={} )
		source_rdn, source_parent_dn = branch.split_dn( 2 )
		new_rdn, new_parent_dn = newdn.split( /\s*,\s*/, 2 )

		if new_parent_dn.nil?
			new_parent_dn = source_parent_dn
		end

		if new_parent_dn != source_parent_dn
			raise Treequel::Error,
				"can't (yet) copy an entry to a new parent"
		end

		self.log.debug "Modrdn (copy): %p -> %p within %p" % [ source_rdn, new_rdn, source_parent_dn ]

		self.conn.modrdn( branch.dn, new_rdn, false )
		rdn_attr, rdn_val = new_rdn.split( /=/, 2 )
		newbranch = branch.class.new( self, rdn_attr, rdn_val, branch.parent )

		attributes = self.normalize_attributes( attributes )
		attributes[ rdn_attr ] ||= []
		attributes[ rdn_attr ] -= [ branch.rdn_value ]
		attributes[ rdn_attr ] |= [ rdn_val ]
		self.log.debug "  changing attributes of the new entry: %p" % [ attributes ]
		self.modify( newbranch, attributes )

		return newbranch
	end


	### Move the entry from the specified +branch+ to the new entry specified by 
	### +newdn+. Returns the (moved) branch object.
	def move( branch, newdn )
		source_rdn, source_parent_dn = branch.split_dn( 2 )
		new_rdn, new_parent_dn = newdn.split( /\s*,\s*/, 2 )

		if new_parent_dn.nil?
			new_parent_dn = source_parent_dn
		end

		if new_parent_dn != source_parent_dn
			raise Treequel::Error,
				"can't (yet) move an entry to a new parent"
		end

		self.log.debug "Modrdn (move): %p -> %p within %p" % [ source_rdn, new_rdn, source_parent_dn ]

		self.conn.modrdn( branch.dn, new_rdn, true )
		branch.rdn = new_rdn
	end


	### Add +conversion+ mapping for the specified +oid+. A conversion is any object that
	### responds to #[] (e.g., Proc, Method, Hash, Array); the argument is the raw
	### value String returned from the LDAP entry, and it should return the converted
	### value. Adding a mapping with a nil +conversion+ effectively clears it.
	def add_syntax_mapping( oid, conversion=nil )
		conversion = Proc.new if block_given?
		@syntax_mapping[ oid ] = conversion
	end


	### Map the specified +value+ to its Ruby datatype if one is registered for the given 
	### syntax +oid+. If there is no conversion registered, just return the +value+ as-is.
	def convert_syntax_value( oid, value )
		return value unless conversion = @syntax_mapping[ oid ]
		return conversion[ value ]
	end


	### Return all the top-level entries in the directory as Branches.
	def children
		return self.search( self.base, :one, '(objectClass=*)' )
	end


	#########
	protected
	#########

	### Proxy method: if the first argument matches a valid attribute in the directory's
	### schema, return a new Branch for the RDN made by using the first two arguments as
	### attribute and value.
	def method_missing( *args )
		attribute, value, *extra = *args
		return super unless attribute && self.schema.attribute_types.key?( attribute )
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


	### Fetch the default base dn for the server from the server's Root DSE.
	def get_default_base_dn
		dse = self.conn.root_dse
		return '' if dse.nil? || dse.empty?
		return dse.first['namingContexts'].first
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


	### Normalize the attributes in +hash+ to be of the form expected by the
	### LDAP library (i.e., keys as Strings, values as Arrays)
	def normalize_attributes( hash )
		normhash = {}
		hash.each do |key,val|
			val = [ val ] unless val.is_a?( Array )
			normhash[ key.to_s ] = val
		end

		return normhash
	end

end # class Treequel::Directory


