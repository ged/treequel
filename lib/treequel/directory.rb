#!/usr/bin/env ruby

require 'time'

require 'ldap'
require 'ldap/schema'

require 'treequel'
require 'treequel/schema'
require 'treequel/mixins'
require 'treequel/constants'
require 'treequel/branch'


# The object in Treequel that represents a connection to a directory, the
# binding to that directory, and the base from which all DNs start.
class Treequel::Directory
	include Treequel::Loggable,
	        Treequel::Constants,
	        Treequel::HashUtilities

	extend Treequel::Delegation

	# The default directory options
	DEFAULT_OPTIONS = {
		:host          => 'localhost',
		:port          => LDAP::LDAP_PORT,
		:connect_type  => :tls,
		:base_dn       => nil,
		:bind_dn       => nil,
		:pass          => nil,
		:results_class => Treequel::Branch,
	}

	# Default mapping of SYNTAX OIDs to conversions from an LDAP string. 
	# See #add_attribute_conversions for more information on what a valid conversion is.
	DEFAULT_ATTRIBUTE_CONVERSIONS = {
		OIDS::BIT_STRING_SYNTAX         => lambda {|bs, _| bs[0..-1].to_i(2) },
		OIDS::BOOLEAN_SYNTAX            => { 'TRUE' => true, 'FALSE' => false },
		OIDS::GENERALIZED_TIME_SYNTAX   => lambda {|string, _| Time.parse(string) },
		OIDS::UTC_TIME_SYNTAX           => lambda {|string, _| Time.parse(string) },
		OIDS::INTEGER_SYNTAX            => lambda {|string, _| Integer(string) },
		OIDS::DISTINGUISHED_NAME_SYNTAX => lambda {|dn, directory|
			resclass = directory.results_class
			resclass.new( directory, dn )
		},
	}

	# Default mapping of SYNTAX OIDs to conversions to an LDAP string from a Ruby object. 
	# See #add_object_conversion for more information on what a valid conversion is.
	DEFAULT_OBJECT_CONVERSIONS = {
		OIDS::BIT_STRING_SYNTAX         => lambda {|bs, _| bs.to_i.to_s(2) },
		OIDS::BOOLEAN_SYNTAX            => lambda {|obj, _| obj ? 'TRUE' : 'FALSE' },
		OIDS::GENERALIZED_TIME_SYNTAX   => lambda {|time, _| time.ldap_generalized },
		OIDS::UTC_TIME_SYNTAX           => lambda {|time, _| time.ldap_utc },
		OIDS::INTEGER_SYNTAX            => lambda {|obj, _| Integer(obj).to_s },
		OIDS::DISTINGUISHED_NAME_SYNTAX => lambda {|obj, _| obj.dn },
	}

	# :NOTE: the docs for #search_ext2 lie. The method signature is actually:
	# rb_scan_args (argc, argv, "39",
	#               &base, &scope, &filter, &attrs, &attrsonly,
	#               &serverctrls, &clientctrls, &sec, &usec, &limit,
	#               &s_attr, &s_proc)

	# The order in which hash arguments should be extracted from Hash parameters to 
	# #search
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
	SEARCH_DEFAULTS = {
		:selectattrs     => ['*'],
		:attrsonly       => false,
		:server_controls => nil,
		:client_controls => nil,
		:timeout         => 0,
		:limit           => 0,
		:sortby          => nil,
	}.freeze


	require 'treequel/branch'

	# The methods that get delegated to the directory's #base branch.
	DELEGATED_BRANCH_METHODS =
		Treequel::Branch.instance_methods(false).collect {|m| m.to_sym }



	#################################################################
	###	I N S T A N C E   M E T H O D S
	#################################################################

	### Create a new Treequel::Directory with the given +options+. Options is a hash with one
	### or more of the following key-value pairs:
	### 
	### @param [Hash] options the connection options
	### @option options [String] :host ('localhost')
	###    The LDAP host to connect to
	### @option options [Fixnum] :port (LDAP::LDAP_PORT)
	###    The port number to connect to
	### @option options [Symbol] :connect_type (:tls)
	###    The type of connection to establish; :tls, :ssl, or :plain.
	### @option options [String] :base_dn (nil)
	###    The base DN of the directory; defaults to the first naming context of
	###    the directory's root DSE.
	### @option options [String] :bind_dn (nil)
	###    The DN of the user to bind as; if unset, binds anonymously.
	### @option options [String] :pass (nil)
	###    The password to use when binding.
	### @option options [CLass] :results_class (Treequel::Branch)
	###    The class to instantiate by default for entries fetched from the Directory.
	def initialize( options={} )
		options                = DEFAULT_OPTIONS.merge( options )

		@host                  = options[:host]
		@port                  = options[:port]
		@connect_type          = options[:connect_type]
		@results_class         = options[:results_class]

		@conn                  = nil
		@bound_user            = nil


		@object_conversions    = DEFAULT_OBJECT_CONVERSIONS.dup
		@attribute_conversions = DEFAULT_ATTRIBUTE_CONVERSIONS.dup
		@registered_controls   = []

		@base_dn               = options[:base_dn] || self.get_default_base_dn
		@base                  = nil

		# Immediately bind if credentials are passed to the initializer.
		if ( options[:bind_dn] && options[:pass] )
			self.bind( options[:bind_dn], options[:pass] )
		end
	end


	######
	public
	######

	# Delegate some methods to the #base Branch.
	def_method_delegators :base, *DELEGATED_BRANCH_METHODS

	# Delegate some methods to the connection via the #conn method
	def_method_delegators :conn, :controls, :referrals


	# The host to connect to.
	# @return [String]
	attr_accessor :host

	# The port to connect to.
	# @return [Fixnum]
	attr_accessor :port

	# The type of connection to establish
	# @return [Symbol]
	attr_accessor :connect_type

	# The Class to instantiate when wrapping results fetched from the Directory.
	# @return [Class]
	attr_accessor :results_class

	# The base DN of the directory
	# @return [String]
	attr_accessor :base_dn

	# The control modules that are registered with the directory
	# @return [Array<Module>]
	attr_reader :registered_controls

	# The DN of the user the directory is bound as
	# @return [String]
	attr_reader :bound_user


	### Fetch the root DSE as a Treequel::Branch.
	def root_dse
		return self.search( '', :base, '(objectClass=*)', :selectattrs => ['+'] ).first
	end


	### Fetch the Branch for the base node of the directory.
	### @return [Treequel::Branch]
	def base
		return @base ||= self.results_class.new( self, self.base_dn )
	end


	### Returns a string that describes the directory
	### @return [String]
	def to_s
		return "%s:%d (%s, %s, %s)" % [
			self.host,
			self.port,
			self.base_dn,
			self.connect_type,
			self.bound? ? @bound_user : 'anonymous'
		  ]
	end


	### Return a human-readable representation of the object suitable for debugging
	### @return [String]
	def inspect
		return %{#<%s:0x%0x %s:%d (%s) base_dn=%p, bound as=%s, schema=%s>} % [
			self.class.name,
			self.object_id / 2,
			self.host,
			self.port,
			@conn ? "connected" : "not connected",
			self.base_dn,
			@bound_user ? @bound_user.dump : "anonymous",
			@schema ? @schema.inspect : "(schema not loaded)",
		]
	end


	### Return the LDAP::Conn object associated with this directory, creating it with the
	### current options if necessary.
	### @return [LDAP::Conn, LDAP::SSLConn]
	def conn
		return @conn ||= self.connect
	end


	### Return the URI object that corresponds to the directory.
	### @return [URI::LDAP]
	def uri
		uri_parts = {
			:scheme => self.connect_type == :ssl ? 'ldaps' : 'ldap',
			:host   => self.host,
			:port   => self.port,
			:dn     => '/' + self.base_dn
		}

		return URI::LDAP.build( uri_parts )
	end


	### Bind as the specified +user_dn+ and +password+.
	### 
	### @param [String, #dn] user_dn  the DN of the user to bind as
	### @param [String] password      the password to bind with
	### 
	### @return [void]
	def bind( user_dn, password )
		user_dn = user_dn.dn if user_dn.respond_to?( :dn )

		self.log.info "Binding with connection %p as: %s" % [ self.conn, user_dn ]
		self.conn.bind( user_dn.to_s, password )
		@bound_user = user_dn.to_s
	end
	alias_method :bind_as, :bind


	### Execute the provided +block+ after binding as +user_dn+ with the given +password+. After
	### the block returns, the original binding (if any) will be restored.
	### 
	### @param (see #bind)
	### 
	### @return [void]
	def bound_as( user_dn, password )
		raise LocalJumpError, "no block given" unless block_given?
		previous_bind_dn = @bound_user
		self.with_duplicate_conn do
			self.bind( user_dn, password )
			yield
		end
	ensure
		@bound_user = previous_bind_dn
	end


	### Returns +true+ if the directory's connection is already bound to the directory.
	### @return [Boolean]
	def bound?
		return self.conn.bound?
	end
	alias_method :is_bound?, :bound?


	### Ensure that the the receiver's connection is unbound.
	### @return [void]
	def unbind
		if @conn.bound?
			old_conn = @conn
			@conn = old_conn.dup
			old_conn.unbind
		end
	end


	### Return the RDN string to the given +dn+ from the base of the directory.
	### @param [#to_s] dn  the DN of the entry
	def rdn_to( dn )
		base_re = Regexp.new( ',' + Regexp.quote(self.base_dn) + '$' )
		return dn.to_s.sub( base_re, '' )
	end


	### Given a Treequel::Branch object, find its corresponding LDAP::Entry and return
	### it.
	### 
	### @param [Treequel::Branch] branch  the branch to look up
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
	### 
	### @param [Treequel::Branch] branch  the branch to look up
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


	### Perform a +scope+ search at +base+ using the specified +filter+.
	### 
	### @param [String, #dn] base  The base DN of the search.
	### @param [Symbol] scope      The scope to use in the search; can be one of 
	###                            +:onelevel+, +:base+, or +:subtree+. 
	### @param [#to_s] filter      The search filter (RFC4515), either as a String 
	###                            or something that stringifies to an filter string.
	### @param [Hash] options      Search options.
	### 
	### @option options [Class] :results_class (Treequel::Branch)
	###    The Class to use when wrapping results; if not specified, defaults to the class 
	###    of +base+ if it responds to #new_from_entry, or the directory object's 
	###    #results_class if it does not.
	### @option options [Array<String, Symbol>] :selectattrs (['*'])
	###    The attributes to return from the search; defaults to '*', which means to
	###    return all non-operational attributes. Specifying '+' will cause the search
	###    to include operational parameters as well.
	### @option options [Boolean] :attrsonly (false)
	###    If +true, the LDAP::Entry objects returned from the search won't have attribute values.
	###    This has no real effect on Treequel::Branches, but is provided in case other 
	###    +results_class+ classes need it.
	### @option options [Array<LDAP::Control>] :server_controls (nil)
	###    Any server controls that should be sent with the search.
	### @option options [Array<LDAP::Control>] :client_controls (nil)
	###    Any client controls that should be applied to the search.
	### @option options [Fixnum] :timeout_s (0)
	###    The number of seconds (in addition to :timeout_us) after which the search request should 
	###    be aborted.
	### @option options [Fixnum] :timeout_us (0)
	###    The number of microseconds (in addition to :timeout_s) after which the search request 
	###    should be aborted.
	### @option options [Fixnum] :limit
	###    The maximum number of results to return from the server.
	### @option options [Array<String>] :sort_attribute
	###    An Array of String attribute names to sort by. 
	### @option options [Proc] :sort_func
	###    A function that will provide sorting.
	### 
	### @return [Array] the array of results, each of which is wrapped in the
	###    options[:results_class]. If a block is given, it acts like a filter:
	###    the return vaule from the block is returned instead.
	### 
	### @yield [branch]  an optional block, which will receive the results one at a time
	### @yieldparam [Treequel::Branch] branch  the resulting entry, wrapped in 
	###    the options[:results_class].
	def search( base, scope=:subtree, filter='(objectClass=*)', options={} )
		collectclass = nil

		# If the base argument is an object whose class knows how to create instances of itself
		# from an LDAP::Entry, use it instead of Treequel::Branch to wrap results
		if options.key?( :results_class )
			collectclass = options.delete( :results_class )
		else
			collectclass = base.class.respond_to?( :new_from_entry ) ?
				base.class :
				self.results_class
		end

		# Format the arguments in the way #search_ext2 expects them
		base_dn, scope, filter, searchopts =
			self.normalize_search_parameters( base, scope, filter, options )

		# Unwrap the search options from the hash in the correct order
		self.log.debug {
			attrlist = SEARCH_PARAMETER_ORDER.inject([]) do |list, param|
				list << "%s: %p" % [ param, searchopts[param] ]
			end
			"searching with base: %p, scope: %p, filter: %p, %s" %
				[ base_dn, scope, filter, attrlist.join(', ') ]
		}
		parameters = searchopts.values_at( *SEARCH_PARAMETER_ORDER )

		# Wrap each result in the class derived from the 'base' argument
		self.log.debug "Searching via search_ext2 with arguments: %p" % [[
			base_dn, scope, filter, *parameters
		]]

		results = []
		self.conn.search_ext2( base_dn, scope, filter, *parameters ).each do |entry|
			branch = collectclass.new_from_entry( entry, self )
			branch.include_operational_attrs = true if
				base.respond_to?( :include_operational_attrs? ) &&
				base.include_operational_attrs?

			if block_given?
				results << yield( branch )
			else
				results << branch
			end
		end

		return results
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
		if mods.first.respond_to?( :mod_op )
			self.log.debug "Modifying %s with LDAP mod objects: %p" % [ branch.dn, mods ]
			self.conn.modify( branch.dn, mods )
		else
			normattrs = normalize_attributes( mods )
			self.log.debug "Modifying %s with: %p" % [ branch.dn, normattrs ]
			self.conn.modify( branch.dn, normattrs )
		end
	end


	### Delete the entry specified by the given +branch+.
	def delete( branch )
		self.log.info "Deleting %s from the directory." % [ branch ]
		self.conn.delete( branch.dn )
	end


	### Create the entry for the given +branch+, setting its attributes to +newattrs+.
	### @param [Treequel::Branch, #to_s] branch   the branch to create (or a DN string)
	### @param [Hash, Array<LDAP::Mod>] newattrs  the attributes to create the entry with. This
	###                                   can be either a Hash of attributes, or an Array of
	###                                   LDAP::Mod objects.
	def create( branch, newattrs={} )
		newattrs = normalize_attributes( newattrs ) if newattrs.is_a?( Hash )
		self.conn.add( branch.to_s, newattrs )

		return true
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


	### Add +conversion+ mapping for attributes of specified +oid+ to a Ruby object. A 
	### conversion is any object that responds to #[] with a String 
	### argument(e.g., Proc, Method, Hash); the argument is the raw value String returned 
	### from the LDAP entry, and it should return the converted value. Adding a mapping 
	### with a nil +conversion+ effectively clears it.
	### @see #convert_to_object
	def add_attribute_conversion( oid, conversion=nil )
		conversion = Proc.new if block_given?
		@attribute_conversions[ oid ] = conversion
	end


	### Add +conversion+ mapping for the specified +oid+. A conversion is any object that
	### responds to #[] with an object argument(e.g., Proc, Method, Hash); the argument is 
	### the Ruby object that's being set as a value in an LDAP entry, and it should return the 
	### raw LDAP string. Adding a mapping with a nil +conversion+ effectively clears it.
	### @see #convert_to_attribute
	def add_object_conversion( oid, conversion=nil )
		conversion = Proc.new if block_given?
		@object_conversions[ oid ] = conversion
	end


	### Register the specified +modules+
	def register_controls( *modules )
		supported_controls = self.supported_control_oids
		self.log.debug "Got %d supported controls: %p" %
			[ supported_controls.length, supported_controls ]

		modules.each do |mod|
			oid = mod.const_get( :OID ) if mod.const_defined?( :OID )
			raise NotImplementedError, "%s doesn't define an OID" % [ mod.name ] if oid.nil?

			self.log.debug "Checking for directory support for %p (%s)" % [ mod, oid ]

			if supported_controls.include?( oid )
				@registered_controls << mod
			else
				raise Treequel::UnsupportedControl,
					"%s is not supported by %s" % [ mod.name, self.uri ]
			end
		end
	end
	alias_method :register_control, :register_controls


	### Map the specified LDAP +attribute+ to its Ruby datatype if one is registered for the given 
	### syntax +oid+. If there is no conversion registered, just return the +value+ as-is.
	def convert_to_object( oid, attribute )
		return attribute unless conversion = @attribute_conversions[ oid ]

		if conversion.respond_to?( :call )
			return conversion.call( attribute, self )
		else
			return conversion[ attribute ]
		end
	end


	### Map the specified Ruby +object+ to its LDAP string equivalent if a conversion is 
	### registered for the given syntax +oid+. If there is no conversion registered, just 
	### returns the +value+ as a String (via #to_s).
	def convert_to_attribute( oid, object )
		return object.to_s unless conversion = @object_conversions[ oid ]

		if conversion.respond_to?( :call )
			return conversion.call( object, self )
		else
			return conversion[ object ]
		end
	end


	### Return an Array of Symbols for the controls supported by the Directory, as listed
	### in the directory's root DSE. Any controls which aren't known (i.e., don't have an
	### entry in Treequel::Constants::CONTROL_NAMES), the numeric OID will be returned as-is.
	def supported_controls
		return self.supported_control_oids.collect {|oid| CONTROL_NAMES[oid] || oid }
	end


	### Return an Array of OID strings representing the controls supported by the Directory, 
	### as listed in the directory's root DSE.
	def supported_control_oids
		return self.root_dse[:supportedControl]
	end


	### Return an Array of Symbols for the extensions supported by the Directory, as listed
	### in the directory's root DSE. Any extensions which aren't known (i.e., don't have an
	### entry in Treequel::Constants::EXTENSION_NAMES), the numeric OID will be returned as-is.
	def supported_extensions
		return self.supported_extension_oids.collect {|oid| EXTENSION_NAMES[oid] || oid }
	end


	### Return an Array of OID strings representing the extensions supported by the Directory, 
	### as listed in the directory's root DSE.
	def supported_extension_oids
		return self.root_dse[:supportedExtension]
	end


	### Return an Array of Symbols for the features supported by the Directory, as listed
	### in the directory's root DSE. Any features which aren't known (i.e., don't have an
	### entry in Treequel::Constants::FEATURE_NAMES), the numeric OID will be returned as-is.
	def supported_features
		return self.supported_feature_oids.collect {|oid| FEATURE_NAMES[oid] || oid }
	end


	### Return an Array of OID strings representing the features supported by the Directory, 
	### as listed in the directory's root DSE.
	def supported_feature_oids
		return self.root_dse[:supportedFeatures]
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
			conn = LDAP::SSLConn.new( @host, @port )
		else
			self.log.debug "Connecting using an unencrypted connection to %s:%d" % [ @host, @port ]
			conn = LDAP::Conn.new( @host, @port )
		end

		conn.set_option( LDAP::LDAP_OPT_PROTOCOL_VERSION, 3 )
		conn.set_option( LDAP::LDAP_OPT_REFERRALS, LDAP::LDAP_OPT_OFF )

		return conn
	end


	### Fetch the default base dn for the server from the server's Root DSE.
	def get_default_base_dn
		return self.root_dse[:namingContexts].first.dn
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

		### Sorting in Ruby-LDAP is not significantly more useful than just sorting
		### the returned entries from Ruby, as it happens client-side anyway (i.e., entries
		### are still returned from the server in arbitrary/insertion order, and then the client
		### sorts those 
		search_paramhash[:sort_func] = nil
		search_paramhash[:sort_attribute] = ''

		return base, scope, filter, search_paramhash
	end

end # class Treequel::Directory


