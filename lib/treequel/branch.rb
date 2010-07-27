#!/usr/bin/env ruby

require 'forwardable'
require 'ldap'
require 'ldap/ldif'

require 'treequel'
require 'treequel/mixins'
require 'treequel/constants'
require 'treequel/branchset'
require 'treequel/branchcollection'


# The object in Treequel that wraps an entry. It knows how to construct other branches
# for the entries below itself, and how to search for those entries.
class Treequel::Branch
	include Comparable,
	        Treequel::Loggable,
	        Treequel::Constants,
	        Treequel::Constants::Patterns

	extend Treequel::Delegation,
	       Treequel::AttributeDeclarations


	# The default width of LDIF output
	DEFAULT_LDIF_WIDTH = 70

	# The characters to use to fold an LDIF line (newline + a space)
	LDIF_FOLD_SEPARATOR = "\n "


	#################################################################
	###	C L A S S   M E T H O D S
	#################################################################

	# [Boolean] Whether or not to include operational attributes by default.
	@include_operational_attrs = false

	# Whether or not to include operational attributes when fetching the
	# entry for branches.
	class << self
		extend Treequel::AttributeDeclarations
		predicate_attr :include_operational_attrs
	end


	### Create a new Treequel::Branch from the given +entry+ hash from the specified +directory+.
	### 
	### @param [LDAP::Entry] entry  The raw entry object the Branch is wrapping.
	### @param [Treequel::Directory] directory  The directory object the Branch is from.
	### 
	### @return [Treequel::Branch]  The new branch object.
	def self::new_from_entry( entry, directory )
		return self.new( directory, entry['dn'].first, entry )
	end


	#################################################################
	###	I N S T A N C E   M E T H O D S
	#################################################################

	### Create a new Treequel::Branch with the given +directory+, +dn+, and an optional +entry+. 
	### If the optional +entry+ object is given, it will be used to fetch values from the 
	### directory; if it isn't provided, it will be fetched from the +directory+ the first
	### time it is needed.
	### 
	### @param [Treequel::Directory] directory  The directory the Branch belongs to.
	### @param [String] dn  The DN of the entry the Branch is wrapping.
	### @param [LDAP::Entry, Hash] entry  The entry object if it's already been fetched.
	def initialize( directory, dn, entry=nil )
		raise ArgumentError, "invalid DN" unless
			dn.match( Patterns::DISTINGUISHED_NAME ) || dn.empty?
		raise ArgumentError, "can't cast a %s to an LDAP::Entry" % [entry.class.name] unless
			entry.nil? || entry.is_a?( Hash )

		@directory = directory
		@dn        = dn
		@entry     = entry
		@values    = {}

		@include_operational_attrs = self.class.include_operational_attrs?
	end


	######
	public
	######

	# Delegate some other methods to a new Branchset via the #branchset method
	def_method_delegators :branchset, :filter, :scope, :select, :limit, :timeout, :order

	# Delegate some methods to the Branch's directory via its accessor
	def_method_delegators :directory, :controls, :referrals


	# The directory the branch's entry lives in
	# @return [Treequel::Directory]
	attr_reader :directory

	# The DN of the branch.
	# @return [String]
	attr_reader :dn
	alias_method :to_s, :dn

	# Whether or not to include operational attributes when fetching the Branch's entry
	predicate_attr :include_operational_attrs
	alias_method :include_operational_attributes?, :include_operational_attrs?

	### Change the DN the Branch uses to look up its entry.
	### 
	### @param [String] newdn  The new DN.
	### @return [void]
	def dn=( newdn )
		self.clear_caches
		@dn = newdn
	end


	### Enable or disable fetching of operational attributes (RC4512, section 3.4).
	### 
	### @param [Boolean] new_setting
	### @return [void]
	def include_operational_attrs=( new_setting )
		self.clear_caches
		@include_operational_attrs = new_setting ? true : false
	end
	alias_method :include_operational_attributes=, :include_operational_attrs=


	### Return the attribute/s which make up this Branch's RDN.
	### @return [Hash<Symbol => String>] The Branch's RDN attributes as a Hash.
	def rdn_attributes
		return make_rdn_hash( self.rdn )
	end


	### Return the LDAP::Entry associated with the receiver, fetching it from the
	### directory if necessary. Returns +nil+ if the entry doesn't exist in the
	### directory.
	### 
	### @return [LDAP::Entry]  The entry wrapped by the Branch.
	def entry
		@entry ||= self.lookup_entry
	end


	### Returns <tt>true</tt> if there is an entry currently in the directory with the
	### branch's DN.
	### @return [Boolean]
	def exists?
		return self.entry ? true : false
	end


	### Return the RDN of the branch.
	### @return [String]
	def rdn
		return self.split_dn( 2 ).first
	end


	### Return the receiver's DN as an Array of attribute=value pairs. 
	### 
	### @param [Fixnum] limit  If non-zero, only the <code>limit-1</code> first pairs 
	###     are split from the DN, and the remainder will be returned as the last 
	###     element.
	def split_dn( limit=0 )
		return self.dn.split( /\s*,\s*/, limit )
	end


	### Return the LDAP URI for this branch
	### @return [URI]
	def uri
		uri = self.directory.uri
		uri.dn = self.dn
		return uri
	end


	### Return the DN of this entry's parent, or nil if it doesn't have one.
	### @return [String]
	def parent_dn
		return nil if self.dn == self.directory.base_dn
		return self.split_dn( 2 ).last
	end


	### Return the Branch's immediate parent node.
	### @return [Treequel::Branch]
	def parent
		return self.class.new( self.directory, self.parent_dn )
	end


	### Perform a search with the specified +scope+, +filter+, and +parameters+ 
	### using the receiver as the base.
	### 
	### @param scope      (see Trequel::Directory#search)
	### @param filter     (see Trequel::Directory#search)
	### @param parameters (see Trequel::Directory#search)
	### @param block      (see Trequel::Directory#search)
	### 
	### @return [Array<Treequel::Branch>] the search results
	def search( scope=:subtree, filter='(objectClass=*)', parameters={}, &block )
		return self.directory.search( self, scope, filter, parameters, &block )
	end


	### Return the Branch's immediate children as Treeque::Branch objects.
	### @return [Array<Treequel::Branch>]
	def children
		return self.search( :one, '(objectClass=*)' )
	end


	### Return a Treequel::Branchset that will use the receiver as its base.
	### @return [Treequel::Branchset]
	def branchset
		return Treequel::Branchset.new( self )
	end


	### Returns a human-readable representation of the object suitable for
	### debugging.
	### 
	### @return [String]
	def inspect
		return "#<%s:0x%0x %s @ %s entry=%p>" % [
			self.class.name,
			self.object_id * 2,
			self.dn,
			self.directory,
			@entry,
		  ]
	end


	### Return the entry's DN as an RFC1781-style UFN (User-Friendly Name).
	### @return [String]
	def to_ufn
		return LDAP.dn2ufn( self.dn )
	end


	### Return the Branch as an LDAP::LDIF::Entry.
	### @return [String]
	def to_ldif( width=DEFAULT_LDIF_WIDTH )
		ldif = "dn: %s\n" % [ self.dn ]

		entry = self.entry || self.valid_attributes_hash
		self.log.debug "  making LDIF from an entry: %p" % [ entry ]

		entry.keys.reject {|k| k == 'dn' }.each do |attribute|
			entry[ attribute ].each do |val|
				ldif << ldif_for_attr( attribute, val, width )
			end
		end

		return LDAP::LDIF::Entry.new( ldif )
	end


	### Return the Branch as a Hash.
	### @see Treequel::Branch#[]
	### @return [Hash]  the entry as a Hash with converted values
	def to_hash
		entry = self.entry || self.valid_attributes_hash
		self.log.debug "  making a Hash from an entry: %p" % [ entry ]

		return entry.keys.inject({}) do |hash, attribute|
			if attribute == 'dn'
				hash[ attribute ] = self.dn
			else
				hash[ attribute ] = self[ attribute ]
			end
			hash
		end
	end


	### Fetch the value/s associated with the given +attrname+ from the underlying entry.
	### @return [Array, String]
	def []( attrname )
		attrsym = attrname.to_sym

		unless @values.key?( attrsym )
			value = self.get_converted_object( attrsym )
			value.freeze if value.respond_to?( :freeze )
			@values[ attrsym ] = value
		else
			self.log.debug "  value is cached."
		end

		return @values[ attrsym ]
	end


	### Fetch one or more values from the entry.
	### 
	### @param [Array<Symbol, String>] attributes  The attributes to fetch values for.
	### @return [Array<String>]  The values which correspond to +attributes+.
	def values_at( *attributes )
		return attributes.collect do |attribute|
			self[ attribute ]
		end
	end


	### Set attribute +attrname+ to a new +value+.
	### 
	### @param [Symbol, String] attrname  attribute name
	### @param [Object] value  the attribute value
	def []=( attrname, value )
		value = [ value ] unless value.is_a?( Array )
		value.collect! {|val| self.get_converted_attribute(attrname, val) }
		self.log.debug "Modifying %s to %p" % [ attrname, value ]
		self.directory.modify( self, attrname.to_s => value )
		@values.delete( attrname.to_sym )
		self.entry[ attrname.to_s ] = value
	end


	### Make the changes to the entry specified by the given +attributes+.
	### 
	### @param attributes (see Treequel::Directory#modify)
	### @return [TrueClass] if the merge succeeded
	def merge( attributes )
		self.directory.modify( self, attributes )
		self.clear_caches

		return true
	end
	alias_method :modify, :merge


	### Delete the specified attributes.
	### 
	### @param [Array<Hash, #to_s>] attributes  The attributes to delete, either as
	###     attribute names (in which case all values of the attribute are deleted) or
	###     Hashes of attributes and the Array of value/s which should be deleted.
	### 
	### @example Delete all 'description' attributes
	###     branch.delete( :description )
	### @example Delete the 'inetOrgPerson' and 'posixAccount' objectClasses from the entry
	###     branch.delete( :objectClass => [:inetOrgPerson, :posixAccount] )
	### @example Delete any blank 'description' or 'cn' attributes:
	###     branch.delete( :description => '', :cn => '' )
	### 
	### @return [TrueClass] if the delete succeeded
	def delete( *attributes )
		self.log.debug "Deleting attributes: %p" % [ attributes ]
		mods = attributes.flatten.collect do |attribute|
			if attribute.is_a?( Hash )
				attribute.collect do |key,vals|
					vals = Array( vals ).collect {|val| val.to_s }
					LDAP::Mod.new( LDAP::LDAP_MOD_DELETE, key.to_s, vals )
				end
			else
				LDAP::Mod.new( LDAP::LDAP_MOD_DELETE, attribute.to_s, [] )
			end
		end.flatten

		self.directory.modify( self, mods )
		self.clear_caches

		return true
	end


	### Create the entry for this Branch with the specified +attributes+. The +attributes+ should,
	### at a minimum, contain the pair `:objectClass => :someStructuralObjectClass`.
	### 
	### @param [Hash<Symbol,String => Object>] attributes
	def create( attributes={} )
		self.directory.create( self, attributes )
		return self
	end


	### Copy the entry for this Branch to a new entry with the given +newdn+ and merge in the
	### specified +attributes+.
	### 
	### @param [String] newdn  the dn of the new entry
	### @param [Hash<String, Symbol => Object>] attributes  merge attributes
	### @return [Treequel::Branch] a Branch for the new entry
	def copy( newdn, attributes={} )

		# Fully-qualify RDNs
		newdn = newdn + ',' + self.parent_dn unless newdn.index(',')

		self.log.debug "Creating a copy of %p at %p" % [ self.dn, newdn ]
		newbranch = self.class.new( self.directory, newdn )

		attributes = self.entry.merge( attributes )

		self.log.debug "  merged attributes: %p" % [ attributes ]
		self.directory.create( newbranch, attributes )

		return newbranch
	end


	### Move the entry associated with this branch to a new entry indicated by +rdn+. If 
	### any +attributes+ are given, also replace the corresponding attributes on the new
	### entry with them.
	### 
	### @param [String] rdn  
	### @param [Hash<String, Symbol => Object>] attributes 
	def move( rdn )
		self.log.debug "Asking the directory to move me to an entry called %p" % [ rdn ]
		return self.directory.move( self, rdn )
	end


	### Comparable interface: Returns -1 if other_branch is less than, 0 if other_branch is 
	### equal to, and +1 if other_branch is greater than the receiving Branch.
	### 
	### @param [Treequel::Branch] other_branch
	### @return [Fixnum]
	def <=>( other_branch )
		# Try the easy cases first
		return nil unless other_branch.respond_to?( :dn ) &&
			other_branch.respond_to?( :split_dn )
		return 0 if other_branch.dn == self.dn

		# Try comparing reversed attribute pairs
		rval = nil
		pairseq = self.split_dn.reverse.zip( other_branch.split_dn.reverse )
		pairseq.each do |a,b|
			comparison = (a <=> b)
			return comparison if !comparison.nil? && comparison.nonzero?
		end

		# The branches are related, so directly comparing DN strings will work
		return self.dn <=> other_branch.dn
	end


	### Fetch a new Treequel::Branch object for the child of the receiver with the specified
	### +rdn+.
	### 
	### @param [String] rdn  The RDN of the child to fetch.
	### @return [Treequel::Branch]
	def get_child( rdn )
		self.log.debug "Getting child %p from base = %p" % [ rdn, self.dn ]
		newdn = [ rdn, self.dn ].reject {|part| part.empty? }.join( ',' )
		return self.class.new( self.directory, newdn )
	end


	### Addition operator: return a Treequel::BranchCollection that contains both the receiver
	### and +other_branch+.
	### 
	### @param [Treequel::Branch] other_branch  
	### @return [Treequel::BranchCollection]
	def +( other_branch )
		return Treequel::BranchCollection.new( self.branchset, other_branch.branchset )
	end


	### Return Treequel::Schema::ObjectClass instances for each of the receiver's
	### objectClass attributes. If any +additional_classes+ are given, 
	### merge them with the current list of the current objectClasses for the lookup.
	### 
	### @param [Array<String, Symbol>] additional_classes 
	### @return [Array<Treequel::Schema::ObjectClass>]
	def object_classes( *additional_classes )
		schema = self.directory.schema

		oc_oids = self[:objectClass] || []
		oc_oids |= additional_classes.collect {|str| str.to_sym }
		oc_oids << :top if oc_oids.empty?

		oclasses = []
		oc_oids.each do |oid|
			oc = schema.object_classes[ oid.to_sym ] or
				raise Treequel::Error, "schema doesn't have a %p objectClass" % [ oid ]
			oclasses << oc
		end

		return oclasses.uniq
	end


	### Return the receiver's operational attributes as attributeType schema objects.
	###
	### @return [Array<Treequel::Schema::AttributeType>]  the operational attributes
	def operational_attribute_types
		return self.directory.schema.operational_attribute_types
	end


	### Return OIDs (numeric OIDs as Strings, named OIDs as Symbols) for each of the 
	### receiver's operational attributes.
	def operational_attribute_oids
		return self.operational_attribute_types.map( &:oid )
	end


	### Return Treequel::Schema::AttributeType instances for each of the receiver's
	### objectClass's MUST attributeTypes. If any +additional_object_classes+ are given, 
	### include the MUST attributeTypes for them as well. This can be used to predict what
	### attributes would need to be present for the entry to be saved if it added the
	### +additional_object_classes+ to its own.
	### 
	### @param [Array<String, Symbol>] additional_object_classes 
	### @return [Array<Treequel::Schema::AttributeType>]
	def must_attribute_types( *additional_object_classes )
		types = []
		oclasses = self.object_classes( *additional_object_classes )
		self.log.debug "Gathering MUST attribute types for objectClasses: %p" % [ oclasses ]

		oclasses.each do |oc|
			self.log.debug "  adding %p from %p" % [ oc.must, oc ]
			types |= oc.must
		end

		return types
	end


	### Return OIDs (numeric OIDs as Strings, named OIDs as Symbols) for each of the receiver's
	### objectClass's MUST attributeTypes. If any +additional_object_classes+ are given, 
	### include the OIDs of the MUST attributes for them as well. This can be used to predict 
	### what attributes would need to be present for the entry to be saved if it added the
	### +additional_object_classes+ to its own.
	### 
	### @param [Array<String, Symbol>] additional_object_classes 
	### @return [Array<String, Symbol>] oid strings and symbols
	def must_oids( *additional_object_classes )
		return self.object_classes( *additional_object_classes ).
			collect {|oc| oc.must_oids }.flatten.uniq.reject {|val| val == '' }
	end


	### Return a Hash of the attributes required by the Branch's objectClasses. If 
	### any +additional_object_classes+ are given, include the attributes that would be
	### necessary for the entry to be saved with them.
	### 
	### @param [Array<String, Symbol>] additional_object_classes 
	### @return [Hash<String => String>]
	def must_attributes_hash( *additional_object_classes )
		attrhash = {}

		self.must_attribute_types( *additional_object_classes ).each do |attrtype|
			self.log.debug "  adding attrtype %p to the MUST attributes hash" % [ attrtype ]

			if attrtype.name == :objectClass
				attrhash[ :objectClass ] = [:top] | additional_object_classes
			elsif attrtype.single?
				attrhash[ attrtype.name ] = ''
			else
				attrhash[ attrtype.name ] = ['']
			end
		end

		return attrhash
	end


	### Return Treequel::Schema::AttributeType instances for each of the receiver's
	### objectClass's MAY attributeTypes. If any +additional_object_classes+ are given, 
	### include the MAY attributeTypes for them as well. This can be used to predict what
	### optional attributes could be added to the entry if the +additional_object_classes+ 
	### were added to it.
	### 
	### @param [Array<String, Symbol>] additional_object_classes 
	### @return [Array<Treequel::Schema::AttributeType>]
	def may_attribute_types( *additional_object_classes )
		return self.object_classes( *additional_object_classes ).
			collect {|oc| oc.may }.flatten.uniq
	end


	### Return OIDs (numeric OIDs as Strings, named OIDs as Symbols) for each of the receiver's
	### objectClass's MAY attributeTypes. If any +additional_object_classes+ are given, 
	### include the OIDs of the MAY attributes for them as well. This can be used to predict 
	### what optional attributes could be added to the entry if the +additional_object_classes+ 
	### were added to it.
	### 
	### @param [Array<String, Symbol>] additional_object_classes 
	### @return [Array<String, Symbol>]  oid strings and symbols
	def may_oids( *additional_object_classes )
		return self.object_classes( *additional_object_classes ).
			collect {|oc| oc.may_oids }.flatten.uniq
	end


	### Return a Hash of the optional attributes allowed by the Branch's objectClasses. If 
	### any +additional_object_classes+ are given, include the attributes that would be
	### available for the entry if it had them.
	### 
	### @param [Array<String, Symbol>] additional_object_classes 
	### @return [Hash<String => String>]
	def may_attributes_hash( *additional_object_classes )
		entry = self.entry
		attrhash = {}

		self.may_attribute_types( *additional_object_classes ).each do |attrtype|
			self.log.debug "  adding attrtype %p to the MAY attributes hash" % [ attrtype ]

			if attrtype.single?
				attrhash[ attrtype.name ] = nil
			else
				attrhash[ attrtype.name ] = []
			end
		end

		attrhash[ :objectClass ] |= additional_object_classes
		return attrhash
	end


	### Return Treequel::Schema::AttributeType instances for the set of all of the receiver's
	### MUST and MAY attributeTypes plus the operational attributes.
	### 
	### @return [Array<Treequel::Schema::AttributeType>]
	def valid_attribute_types
		return self.must_attribute_types |
		       self.may_attribute_types  |
		       self.operational_attribute_types
	end


	### Return a uniqified Array of OIDs (numeric OIDs as Strings, named OIDs as Symbols) for
	### the set of all of the receiver's MUST and MAY attributeTypes plus the operational
	### attributes.
	### 
	### @return [Array<String, Symbol>]
	def valid_attribute_oids
		return self.must_oids | self.may_oids
	end


	### If the attribute associated with the given +attroid+ is in the list of valid 
	### attributeTypes for the receiver given its objectClasses, return the 
	### AttributeType object that corresponds with it. If it isn't valid, return nil.
	### Includes operational attributes.
	###
	### @param [String,Symbol] attroid  a numeric OID (as a String) or a named OID (as a Symbol)
	### @return [Treequel::Schema::AttributeType] the validated attributeType
	def valid_attribute_type( attroid )
		return self.valid_attribute_types.find {|attr_type| attr_type.valid_name?(attroid) }
	end


	### Return +true+ if the specified +attrname+ is a valid attributeType given the
	### receiver's current objectClasses. Does not include operational attributes.
	### 
	### @param [String, Symbol] the OID (numeric or name) of the attribute in question
	### @return [Boolean]
	def valid_attribute?( attroid )
		return !self.valid_attribute_type( attroid ).nil?
	end


	### Return a Hash of all the attributes allowed by the Branch's objectClasses. If
	### any +additional_object_classes+ are given, include the attributes that would be
	### available for the entry if it had them.
	### 
	### @param [Array<String, Symbol>] additional_object_classes 
	### @return [Hash<String => String>]
	def valid_attributes_hash( *additional_object_classes )
		self.log.debug "Gathering a hash of all valid attributes:"
		must = self.must_attributes_hash( *additional_object_classes )
		self.log.debug "  MUST attributes: %p" % [ must ]
		may  = self.may_attributes_hash( *additional_object_classes )
		self.log.debug "  MAY attributes: %p" % [ may ]

		return may.merge( must )
	end


	#########
	protected
	#########

	### Proxy method: call #traverse_branch if +attribute+ is a valid attribute
	### and +value+ isn't +nil+.
	### @see Treequel::Branch#traverse_branch
	def method_missing( attribute, value=nil, additional_attributes={} )
		return super( attribute ) if value.nil?
		return self.traverse_branch( attribute, value, additional_attributes )
	end


	### If +attribute+ matches a valid attribute type in the directory's
	### schema, return a new Branch for the RDN of +attribute+ and +value+, and 
	### +additional_attributes+ if it's a multi-value RDN.
	###
	### @param [Symbol] attribute            the RDN attribute of the child
	### @param [String] value                the RDN valye of the child
	### @param [Hash] additional_attributes  any additional RDN attributes
	### 
	### @example
	###   branch = Treequel::Branch.new( directory, 'ou=people,dc=acme,dc=com' )
	###   branch.uid( :chester ).dn
	###   # => 'uid=chester,ou=people,dc=acme,dc=com'
	###   branch.uid( :chester, :employeeType => 'admin' ).dn
	###   # => 'uid=chester+employeeType=admin,ou=people,dc=acme,dc=com'
	### 
	### @return [Treequel::Branch]  the Branch for the specified child
	### @raise [NoMethodError] if the +attribute+ or any +additional_attributes+ are
	###                        not valid attributeTypes.
	def traverse_branch( attribute, value, additional_attributes={} )
		valid_types = self.directory.schema.attribute_types

		# Raise if either the primary attribute or any secondary attributes are invalid
		if !valid_types.key?( attribute )
			raise NoMethodError, "undefined method `%s' for %p" % [ attribute, self ]
		elsif invalid = additional_attributes.keys.find {|ex_attr| !valid_types.key?(ex_attr) }
			raise NoMethodError, "invalid secondary attribute `%s' for %p" %
				[ invalid, self ]
		end

		# Make a normalized RDN from the arguments and return the Branch for it
		rdn = rdn_from_pair_and_hash( attribute, value, additional_attributes )
		return self.get_child( rdn )
	end


	### Fetch the entry from the Branch's directory.
	def lookup_entry
		self.log.debug "Looking up entry for %p" % [ self ]
		if self.include_operational_attrs?
			self.log.debug "  including operational attributes."
			return self.directory.get_extended_entry( self )
		else
			self.log.debug "  not including operational attributes."
			return self.directory.get_entry( self )
		end
	end


	### Get the value associated with +attrsym+, convert it to a Ruby object if the Branch's
	### directory has a conversion rule, and return it.
	def get_converted_object( attrsym )
		return nil unless self.entry
		value = self.entry[ attrsym.to_s ] or return nil

		if attribute = self.directory.schema.attribute_types[ attrsym ]
			self.log.debug "converting value for %p using the conversion for %p" %
				[ attrsym, attribute.syntax_oid ]
			if attribute.single?
				value = self.directory.convert_to_object( attribute.syntax_oid, value.first )
			else
				value = value.collect do |raw|
					self.directory.convert_to_object( attribute.syntax_oid, raw )
				end
			end
		else
			self.log.info "no attributeType for %p" % [ attrsym ]
		end

		return value
	end


	### Convert the specified +object+ according to the Branch's directory's conversion rules, 
	### and return it.
	def get_converted_attribute( attrsym, object )
		if attribute = self.directory.schema.attribute_types[ attrsym ]
			self.log.debug "converting %p object to a %p attribute" %
				[ attrsym, attribute.syntax_oid ]
			return self.directory.convert_to_attribute( attribute.syntax_oid, object )
		else
			self.log.info "no attributeType for %p" % [ attrsym ]
			return object.to_s
		end
	end


	### Clear any cached values when the structural state of the object changes.
	### @return [void]
	def clear_caches
		@entry = nil
		@values.clear
	end


	#######
	private
	#######

	### Make an RDN string (RFC 4514) from the primary +attribute+ and +value+ pair plus any 
	### +additional_attributes+ (for multivalue RDNs).
	def rdn_from_pair_and_hash( attribute, value, additional_attributes={} )
		additional_attributes.merge!( attribute => value )
		return additional_attributes.sort_by {|k,v| k.to_s }.
			collect {|pair| pair.join('=') }.
			join('+')
	end


	### Split the given +rdn+ into an Array of the iniital RDN attribute and value, and a
	### Hash containing any additional pairs.
	def pair_and_hash_from_rdn( rdn )
		initial, *trailing = rdn.split( '+' )
		initial_pair = initial.split( /\s*=\s*/ )
		trailing_pairs = trailing.inject({}) do |hash,pair|
			k,v = pair.split( /\s*=\s*/ )
			hash[ k ] = v
			hash
		end

		return initial_pair + [ trailing_pairs ]
	end


	### Given an +RDN+, return a Hash of the key/value pairs which make it up.
	def make_rdn_hash( rdn )
		return rdn.split( /\s*\+\s*/ ).inject({}) do |attributes, pair|
			attrname, value = pair.split(/\s*=\s*/)
			attributes[ attrname ] = [ value ]
			attributes
		end
	end


	### Make LDIF for the given +attribute+ and its +values+, wrapping at the given
	### +width+.
	### 
	### @param [String] attribute  the attribute
	### @param [Array<String>] values  the values for the given +attribute+
	### @param [Fixnum] width  the maximum width of the lines to return
	def ldif_for_attr( attribute, values, width )
		ldif = ''

		Array( values ).each do |val|
			line = "#{attribute}:"

			if val =~ /^#{LDIF_SAFE_STRING}$/
				line << ' ' << val.to_s
			else
				line << ': ' << [ val ].pack( 'm' ).chomp
			end

			# calculate how many times the line needs to be split, then add any 
			# additional splits that need to be added because of the additional
			# fold characters
			splits  = ( line.length / width )
			splits += ( splits * LDIF_FOLD_SEPARATOR.length ) / width
			splits.times {|i| line[ width * (i+1), 0 ] = LDIF_FOLD_SEPARATOR }

			ldif << line << "\n"
		end

		return ldif
	end


end # class Treequel::Branch


