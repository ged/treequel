#!/usr/bin/env ruby

require 'time'

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

	extend Treequel::Delegation

	# SVN Revision
	SVNRev = %q$Rev$

	# SVN Id
	SVNId = %q$Id$

	# The default directory options
	DEFAULT_OPTIONS = {
		:host          => 'localhost',
		:port          => LDAP::LDAP_PORT,
		:connect_type  => :tls,
		:base_dn       => nil,
		:bind_dn       => nil,
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


	# :NOTE: the docs for #search_ext2 lie. The method signature is actually:
	# rb_scan_args (argc, argv, "39",
	#               &base, &scope, &filter, &attrs, &attrsonly,
	#               &serverctrls, &clientctrls, &sec, &usec, &limit,
	#               &s_attr, &s_proc)
	SEARCH_PARAMETER_ORDER = [
		:selectattrs,
		:attrsonly,
		:server_controls,
		:client_controls,
		:timeout_s,
		:timeout_us,
		:limit,
		:sort_attribute,
		:sort_func,
	].freeze

	# Default values to pass to LDAP::Conn#search_ext2; they'll be passed in the order 
	# specified by SEARCH_PARAMETER_ORDER.
	# :NOTE: the docs for #search_ext2 lie. The method signature is actually:
	# rb_scan_args (argc, argv, "39",
	#               &base, &scope, &filter, &attrs, &attrsonly,
	#               &serverctrls, &clientctrls, &sec, &usec, &limit,
	#               &s_attr, &s_proc)
	SEARCH_DEFAULTS = {
		:selectattrs     => ['*'],
		:attrsonly       => false,
		:server_controls => nil,
		:client_controls => nil,
		:timeout         => 0,
		:limit           => 0,
		:sortby          => nil,
	}.freeze


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
	### [base_dn]::
	###   The base DN of the directory.
	### [bind_dn]::
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

		@base_dn        = options[:base_dn] || self.get_default_base_dn
		@syntax_mapping = DEFAULT_SYNTAX_MAPPING.dup

		@base           = nil

		# Immediately bind if credentials are passed to the initializer.
		if ( options[:bind_dn] && options[:pass] )
			self.bind( options[:bind_dn], options[:pass] )
		end
	end


	######
	public
	######

	# Delegate some methods to the #base Branch.
	def_method_delegators :base, :children, :branchset, :filter, :scope, :select

	# The host to connect to.
	attr_accessor :host

	# The port to connect to.
	attr_accessor :port

	# The type of connection to establish
	attr_accessor :connect_type

	# The base DN of the directory
	attr_accessor :base_dn


	### Fetch the Branch for the base node of the directory.
	def base
		return @base ||= Treequel::Branch.new( self, self.base_dn )
	end


	### Returns a string that describes the directory
	def to_s
		return "%s:%d (%s, %s, %s)" % [
			self.host,
			self.port,
			self.base_dn,
			self.connect_type,
			self.bound? ? @bound_as : 'anonymous'
		  ]
	end


	### Return a human-readable representation of the object suitable for debugging
	def inspect
		return %{#<%s:0x%0x %s:%d (%s) base_dn=%p, bound as=%s, schema=%s>} % [
			self.class.name,
			self.object_id / 2,
			self.host,
			self.port,
			@conn ? "connected" : "not connected",
			self.base_dn,
			@bound_as ? @bound_as.dump : "anonymous",
			@schema ? @schema.inspect : "(schema not loaded)",
		]
	end


	### Return the LDAP::Conn object associated with this directory, creating it with the
	### current options if necessary.
	def conn
		return @conn ||= self.connect
	end


	### Return the URI object that corresponds to the directory.
	def uri
		uri_parts = {
			:scheme => self.connect_type == :ssl ? 'ldaps' : 'ldap',
			:host   => self.host,
			:port   => self.port,
			:dn     => '/' + self.base_dn
		}

		return URI::LDAP.build( uri_parts )
	end


	### Bind as the specified +user_dn+ and +password+. If the optional +block+ is given,
	### it will be executed with the receiver bound, then returned to its previous state when
	### the block exits.
	def bind( user_dn, password )
		user_dn = user_dn.dn if user_dn.respond_to?( :dn )

		self.log.info "Binding with connection %p as: %s" % [ self.conn, user_dn ]
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
		base_re = Regexp.new( ',' + Regexp.quote(self.base_dn) + '$' )
		return dn.to_s.sub( base_re, '' )
	end


	### Given a Treequel::Branch object, find its corresponding LDAP::Entry and return
	### it.
	def get_entry( branch )
		self.log.debug "Looking up entry for %p" % [ branch.dn ]
		return self.conn.search_ext2( branch.dn, SCOPE[:base], '(objectClass=*)' ).first
	rescue LDAP::ResultError => err
		self.log.info "  search for %p failed: %s" % [ branch.dn, err.message ]
		return nil
	end


	### Given a Treequel::Branch object, find its corresponding LDAP::Entry and return
	### it with its operational attributes (http://tools.ietf.org/html/rfc4512#section-3.4)
	### included.
	def get_extended_entry( branch )
		self.log.debug "Looking up entry (with operational attributes) for %p" % [ branch.dn ]
		return self.conn.search_ext2( branch.dn, SCOPE[:base], '(objectClass=*)', %w[* +] ).first
	rescue LDAP::ResultError => err
		self.log.info "  search for %p failed: %s" % [ branch.dn, err.message ]
		return nil
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
	def search( base, scope=:subtree, filter='(objectClass=*)', parameters={} )
		collectclass = nil

		# If the base argument is an object whose class knows how to create instances of itself
		# from an LDAP::Entry, use it instead of Treequel::Branch to wrap results
		if parameters.key?( :results_class )
			collectclass = parameters.delete( :results_class )
		else
			collectclass = base.class.respond_to?( :new_from_entry ) ? base.class : Treequel::Branch
		end

		# Format the arguments in the way #search_ext2 expects them
		base, scope, filter, searchparams =
			self.normalize_search_parameters( base, scope, filter, parameters )

		# Unwrap the search parameters from the hash in the correct order
		self.log.debug {
			attrlist = SEARCH_PARAMETER_ORDER.inject([]) do |list, param|
				list << "%s: %p" % [ param, searchparams[param] ]
			end
			"searching with base: %p, scope: %p, filter: %p, %s" %
				[ base, scope, filter, attrlist.join(', ') ]
		}
		parameters = searchparams.values_at( *SEARCH_PARAMETER_ORDER )

		# Wrap each result in the class derived from the 'base' argument
		if block_given?
			self.conn.search_ext2( base, scope, filter, *parameters ).each do |entry|
				yield collectclass.new_from_entry( entry, self )
			end
		else
			return self.conn.search_ext2( base, scope, filter, *parameters ).
				collect {|entry| collectclass.new_from_entry(entry, self) }
		end

	rescue RuntimeError => err
		conn = self.conn

		# The LDAP library raises a plain RuntimeError with an incorrect message if the 
		# connection goes away, so it's caught here to rewrap it
		case err.message
		when /no result returned by search/i
			raise LDAP::ResultError.new( LDAP.err2string(conn.err) )
		else
			raise
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
	def create( branch, newattrs={} )
		newdn = branch.dn
		schema = self.schema

		# Merge RDN attributes with existing ones, combining any that exist in both
		self.log.debug "Smushing rdn attributes %p into %p" % [ branch.rdn_attributes, newdn ]
		newattrs.merge!( branch.rdn_attributes ) do |key, *values|
			values.flatten
		end

		normattrs = self.normalize_attributes( newattrs )
		raise ArgumentError, "Can't create an entry with no objectClasses" unless
			normattrs.key?( 'objectClass' )
		raise ArgumentError, "Can't create an entry with no structural objectClass" unless
			normattrs['objectClass'].any? {|oc| schema.object_classes[oc.to_sym].structural? }

		self.log.debug "Creating an entry at %s with the attributes: %p" % [ newdn, normattrs ]
		self.conn.add( newdn, normattrs )

		return true
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
			newdn = [new_rdn, new_parent_dn].join(',')
		end

		if new_parent_dn != source_parent_dn
			raise Treequel::Error,
				"can't (yet) move an entry to a new parent"
		end

		self.log.debug "Modrdn (move): %p -> %p within %p" % [ source_rdn, new_rdn, source_parent_dn ]

		self.conn.modrdn( branch.dn, new_rdn, true )
		branch.dn = newdn
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



	#########
	protected
	#########

	### Delegate attribute/value calls on the directory itself to the directory's #base Branch.
	def method_missing( attribute, *args )
		return self.base.send( attribute, *args )
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
		conn.set_option( LDAP::LDAP_OPT_REFERRALS, LDAP::LDAP_OPT_OFF )

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
		self.log.info "Executing with %p, a copy of connection %p" % [ @conn, original_conn ]
		yield
	ensure
		self.log.info "  restoring original connection %p." % [ original_conn ]
		@conn = original_conn
	end


	### Normalize the attributes in +hash+ to be of the form expected by the
	### LDAP library (i.e., keys as Strings, values as Arrays of Strings)
	def normalize_attributes( hash )
		normhash = {}
		hash.each do |key,val|
			val = [ val ] unless val.is_a?( Array )
			val.collect! {|obj| obj.to_s }

			normhash[ key.to_s ] = val
		end

		return normhash
	end


	### Normalize the parameters to the #search method into the format expected by 
	### the LDAP::Conn#Search_ext2 method and return them as a Hash.
	def normalize_search_parameters( base, scope, filter, parameters )
		search_paramhash = SEARCH_DEFAULTS.merge( parameters )

		# Use the DN of the base object if it's an object that knows what a DN is
		base = base.dn if base.respond_to?( :dn )
		scope = SCOPE[scope.to_sym] if scope.respond_to?( :to_sym ) && SCOPE.key?( scope.to_sym )
		filter = filter.to_s

		# Split seconds and microseconds from the timeout value, convert the 
		# fractional part to µsec
		timeout = search_paramhash.delete( :timeout ) || 0
		search_paramhash[:timeout_s] = timeout.truncate
		search_paramhash[:timeout_us] = Integer((timeout - timeout.truncate) * 1_000_000)

		# Assign the 'sortby' parameter to either the sort proc or the sorting attribute, depending
		# on whether it's something that can be turned into a Proc or not.
		sortby = search_paramhash.delete( :sortby )
		search_paramhash[:sort_func] = nil
		search_paramhash[:sort_attribute] = ''
		if sortby.respond_to?( :to_proc )
			search_paramhash[:sort_func] = sortby.to_proc
		elsif !sortby.nil?
			search_paramhash[:sort_attribute] = sortby.to_s
		end

		return base, scope, filter, search_paramhash
	end

end # class Treequel::Directory


