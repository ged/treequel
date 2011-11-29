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
	        Treequel::Constants::Patterns,
	        Treequel::HashUtilities

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

	# [Boolean] Whether or not to freeze values cached in @values. This helps
	#   prevent you from accidentally doing branch[:attr] << 'value', which
	#   modifies the cached values, but not the entry.
	@freeze_converted_values = true

	# Whether or not to include operational attributes when fetching the
	# entry for branches.
	class << self
		extend Treequel::AttributeDeclarations
		predicate_attr :include_operational_attrs
		predicate_attr :freeze_converted_values
	end


	### Create a new Treequel::Branch from the given +entry+ hash from the specified +directory+.
	def self::new_from_entry( entry, directory )
		entry = Treequel::HashUtilities.stringify_keys( entry )
		dnvals = entry.delete( 'dn' ) or
			raise ArgumentError, "no 'dn' attribute for entry"

		Treequel.logger.debug "Creating Branch from entry: %p in directory: %s" %
			[ dnvals.first, directory ]
		return self.new( directory, dnvals.first, entry )
	end


	#################################################################
	###	I N S T A N C E   M E T H O D S
	#################################################################

	### Create a new Treequel::Branch with the given +directory+, +dn+, and an optional +entry+. 
	### If the optional +entry+ object is given, it will be used to fetch values from the 
	### directory; if it isn't provided, it will be fetched from the +directory+ the first
	### time it is needed.
	def initialize( directory, dn, entry=nil )
		raise ArgumentError, "nil DN" unless dn
		raise ArgumentError, "invalid DN" unless
			dn.match( Patterns::DISTINGUISHED_NAME ) || dn.empty?
		raise ArgumentError, "can't cast a %s to an LDAP::Entry" % [entry.class.name] unless
			entry.nil? || entry.is_a?( Hash )

		@directory = directory
		@dn        = dn
		@entry     = entry ? stringify_keys( entry ) : nil
		@values    = {}

		@include_operational_attrs = self.class.include_operational_attrs?

		self.log.debug "New branch (%s): entry = %p, directory = %p" % [ @dn, @entry, @directory ]
	end


	######
	public
	######

	# Delegate some other methods to a new Branchset via the #branchset method
	def_method_delegators :branchset, :filter, :scope, :select, :limit, :timeout, :as, :from

	# Delegate some methods to the Branch's directory via its accessor
	def_method_delegators :directory, :controls, :referrals


	# The directory the branch's entry lives in
	attr_reader :directory

	# The DN of the branch.
	attr_reader :dn
	alias_method :to_s, :dn

	# Whether or not to include operational attributes when fetching the Branch's entry
	predicate_attr :include_operational_attrs
	alias_method :include_operational_attributes?, :include_operational_attrs?


	### Change the DN the Branch uses to look up its entry to +newdn+.
	def dn=( newdn )
		self.clear_caches
		@dn = newdn
	end


	### Enable (if +new_setting+ is true) or disable fetching of operational attributes (RC4512, 
	### section 3.4).
	def include_operational_attrs=( new_setting )
		self.clear_caches
		@include_operational_attrs = new_setting ? true : false
	end
	alias_method :include_operational_attributes=, :include_operational_attrs=


	### Return the attribute/s which make up this Branch's RDN as a Hash.
	def rdn_attributes
		return make_rdn_hash( self.rdn )
	end


	### Return the LDAP::Entry associated with the receiver, fetching it from the
	### directory if necessary. Returns +nil+ if the entry doesn't exist in the
	### directory.
	def entry
		@entry ||= self.lookup_entry
	end


	### Returns <tt>true</tt> if there is an entry currently in the directory with the
	### branch's DN.
	def exists?
		return self.entry ? true : false
	end


	### Returns +true+ if the Branch's entry has been fetched from the directory.
	def loaded?
		return @entry ? true : false
	end


	### Return the RDN of the branch.
	def rdn
		return self.split_dn( 2 ).first
	end


	### Return the receiver's DN as an Array of attribute=value pairs. If the optional +limit+ is
	### non-zero, only the <code>limit-1</code> first pairs are split from the DN, and the 
	### remainder will be returned as the last element.
	def split_dn( limit=0 )
		return self.dn.split( /\s*,\s*/, limit )
	end


	### Return the LDAP URI for this branch
	def uri
		uri = self.directory.uri
		uri.dn = self.dn
		return uri
	end


	### Return the DN of this entry's parent, or nil if it doesn't have one.
	def parent_dn
		return nil if self.dn == self.directory.base_dn
		return '' if self.dn.index( ',' ).nil?
		return self.split_dn( 2 ).last
	end


	### Return the Branch's immediate parent node.
	def parent
		pardn = self.parent_dn or return nil
		return self.class.new( self.directory, pardn )
	end


	### Perform a search with the specified +scope+, +filter+, and +parameters+ using the 
	### receiver as the base. See Trequel::Directory#search for details. Returns an Array of
	### Treequel::Branch objects.
	def search( scope=:subtree, filter='(objectClass=*)', parameters={}, &block )
		return self.directory.search( self, scope, filter, parameters, &block )
	end


	### Return the Branch's immediate children as Treeque::Branch objects.
	def children
		return self.search( :one, '(objectClass=*)' )
	end


	### Return a Treequel::Branchset that will use the receiver as its base.
	def branchset
		return Treequel::Branchset.new( self )
	end


	### Returns a human-readable representation of the object suitable for
	### debugging.
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
	def to_ufn
		if LDAP.respond_to?( :dn2ufn )
			return LDAP.dn2ufn( self.dn )

		# An implementation for LDAP libraries with no
		# dn2ufn
		else
			ufn = ''
			tuples = self.split_dn

			# Separate the trailing domainComponents
			dcs = []
			dcs << tuples.pop while tuples.last =~ /^dc\s*=/i

			# Append the non-dc tuples with their attributes stripped first
			ufn << tuples.collect do |rdn|
				rdn.
					gsub(/\b#{ATTRIBUTE_TYPE}\s*=/, '').
					gsub(/\s*\+\s*/, ' + ')
			end.join( ', ' )

			# Now append the DCs joined with dots
			unless dcs.empty?
				ufn << ', '
				ufn << dcs.reverse.map {|rdn| rdn.sub(/dc\s*=\s*/i, '') }.join( '.' )
			end

			return ufn
		end
	end


	### Return the Branch as an LDAP::LDIF::Entry.
	def to_ldif( width=DEFAULT_LDIF_WIDTH )
		ldif = "dn: %s\n" % [ self.dn ]

		entry = self.entry || self.valid_attributes_hash
		self.log.debug "  making LDIF from an entry: %p" % [ entry ]

		entry.keys.reject {|k| k == 'dn' }.each do |attribute|
			Array( entry[attribute] ).each do |val|
				ldif << ldif_for_attr( attribute, val, width )
			end
		end

		return LDAP::LDIF::Entry.new( ldif )
	end


	### Return the Branch as a Hash.
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
	def []( attrname )
		attrsym = attrname.to_sym

		if @values.key?( attrsym )
			# self.log.debug "  value for %p is cached (%p)." % [ attrname, @values[attrsym] ]
		else
			self.log.debug "  value for %p is NOT cached." % [ attrsym ]
			value = self.get_converted_object( attrsym )
			self.log.debug "  converted value is: %p" % [ value ]
			value.freeze if
				self.class.freeze_converted_values? &&
				value.respond_to?( :freeze )
			@values[ attrsym ] = value if value
		end

		return @values[ attrsym ]
	end


	### Fetch one or more values for the specified +attributes+ from the entry.
	###
	###    branch.values_at( :cn, :objectClass )
	###    => [["sysadmin"], ["top", "posixGroup", "apple-group"]]
	def values_at( *attributes )
		return attributes.collect do |attribute|
			self[ attribute ]
		end
	end


	### Set attribute +attrname+ to a new +value+.
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
	###   branch.merge( :description => ['The syadmin group'], :cn => ['sysadmin'] )
	def merge( attributes )
		self.directory.modify( self, attributes )
		self.clear_caches

		return true
	end
	alias_method :modify, :merge


	### Delete the specified +attributes+, which are the attributes to delete either as
	### attribute names (in which case all values of the attribute are deleted), or
	### Hashes of attributes and the Array of value/s which should be deleted.
	### 
	###     # Delete all 'description' attributes
	###     branch.delete( :description )
	###
	###     # Delete the 'inetOrgPerson' and 'posixAccount' objectClasses from the entry
	###     branch.delete( :objectClass => [:inetOrgPerson, :posixAccount] )
	###
	###     # Delete any blank 'description' or 'cn' attributes:
	###     branch.delete( :description => '', :cn => '' )
	### 
	def delete( *attributes )

		# If no attributes are given, delete the whole entry
		if attributes.empty?
			self.log.info "No attributes specified; deleting entire entry for %s" % [ self.dn ]
			self.directory.delete( self )

		# Otherwise, gather up the LDAP::Mod objects that will delete the given attributes
		else
			self.log.debug "Deleting attributes: %p" % [ attributes ]
			mods = attributes.flatten.collect do |attribute|

				# Delete particular values of the attribute
				if attribute.is_a?( Hash )
					attribute.collect do |key,vals|
						vals = [ vals ] unless vals.is_a?( Array )
						vals.collect! {|val| self.get_converted_attribute(key, val) }
						LDAP::Mod.new( LDAP::LDAP_MOD_DELETE, key.to_s, vals )
					end

				# Delete all values of the attribute
				else
					LDAP::Mod.new( LDAP::LDAP_MOD_DELETE, attribute.to_s, [] )
				end

			end

			self.directory.modify( self, mods.flatten )
		end

		self.clear_caches

		return true
	end


	### Create the entry for this Branch with the specified +attributes+. The +attributes+ should,
	### at a minimum, contain the pair `:objectClass => [:someStructuralObjectClass]`.
	###
	###     groups = dir.ou( :groups )
	###     newgroup = groups.cn( :staff )
	###     newgroup.create( :objectClass => ['posixGroup'], :gidNumber => 2100 )
	###     # => #<Treequel::Branch:0x1086a0ac8 cn=staff,ou=groups,dc=example,dc=com>
	def create( attributes={} )
		self.directory.create( self, attributes )
		self.clear_caches
		return self
	end


	### Copy the entry for this Branch to a new entry with the given +newdn+ and merge in the
	### specified +attributes+.
	def copy( newdn, attributes={} )

		# Fully-qualify RDNs
		newdn = newdn + ',' + self.parent_dn unless newdn.index(',')

		self.log.debug "Creating a copy of %p at %p" % [ self.dn, newdn ]
		newbranch = self.class.new( self.directory, newdn )

		attributes = self.entry.merge( stringify_keys(attributes) )

		self.log.debug "  merged attributes: %p" % [ attributes ]
		self.directory.create( newbranch, attributes )

		return newbranch
	end


	### Move the entry associated with this branch to a new entry indicated by +rdn+. If 
	### any +attributes+ are given, also replace the corresponding attributes on the new
	### entry with them.
	def move( rdn )
		self.log.debug "Asking the directory to move me to an entry called %p" % [ rdn ]
		self.directory.move( self, rdn )
		self.clear_caches

		return self
	end


	### Comparable interface: Returns -1 if other_branch is less than, 0 if +other_branch+ is 
	### equal to, and +1 if +other_branch+ is greater than the receiving Branch.
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
	def get_child( rdn )
		self.log.debug "Getting child %p from base = %p" % [ rdn, self.dn ]
		newdn = [ rdn, self.dn ].reject {|part| part.empty? }.join( ',' )
		return self.class.new( self.directory, newdn )
	end


	### Addition operator: return a Treequel::BranchCollection that contains both the receiver
	### and +other_branch+.
	def +( other_branch )
		return Treequel::BranchCollection.new( self.branchset, other_branch.branchset )
	end


	### Return Treequel::Schema::ObjectClass instances for each of the receiver's
	### objectClass attributes. If any +additional_classes+ are given, 
	### merge them with the current list of the current objectClasses for the lookup.
	def object_classes( *additional_classes )
		# self.log.debug "Fetching object classes for %s" % [ self.dn ]
		schema = self.directory.schema

		oc_oids = self[:objectClass] || []
		oc_oids |= additional_classes.collect {|str| str.to_sym }
		oc_oids << 'top' if oc_oids.empty?

		oclasses = []
		oc_oids.each do |oid|
			oc = schema.object_classes[ oid.to_sym ] or
				raise Treequel::Error, "schema doesn't have a %p objectClass" % [ oid ]
			oclasses << oc
		end

		# self.log.debug "  found %d objectClasses: %p" % [  oclasses.length, oclasses.map(&:name) ]
		return oclasses.uniq
	end


	### Return the receiver's operational attributes as attributeType schema objects.
	def operational_attribute_types
		return self.directory.schema.operational_attribute_types
	end


	### Return OIDs (numeric OIDs as Strings, named OIDs as Symbols) for each of the 
	### receiver's operational attributes.
	def operational_attribute_oids
		return self.operational_attribute_types.inject([]) do |oids, attrtype|
			oids.push( *attrtype.names )
			oids << attrtype.oid
		end
	end


	### Return Treequel::Schema::AttributeType instances for each of the receiver's
	### objectClass's MUST attributeTypes. If any +additional_object_classes+ are given, 
	### include the MUST attributeTypes for them as well. This can be used to predict what
	### attributes would need to be present for the entry to be saved if it added the
	### +additional_object_classes+ to its own.
	def must_attribute_types( *additional_object_classes )
		oclasses = self.object_classes( *additional_object_classes )
		types = oclasses.map( &:must ).flatten.uniq

		return types
	end


	### Return OIDs (numeric OIDs as Strings, named OIDs as Symbols) for each of the receiver's
	### objectClass's MUST attributeTypes. If any +additional_object_classes+ are given, 
	### include the OIDs of the MUST attributes for them as well. This can be used to predict 
	### what attributes would need to be present for the entry to be saved if it added the
	### +additional_object_classes+ to its own.
	def must_oids( *additional_object_classes )
		return self.object_classes( *additional_object_classes ).
			collect {|oc| oc.must_oids }.flatten.uniq.reject {|val| val == '' }
	end


	### Return a Hash of the attributes required by the Branch's objectClasses. If 
	### any +additional_object_classes+ are given, include the attributes that would be
	### necessary for the entry to be saved with them.
	def must_attributes_hash( *additional_object_classes )
		attrhash = {}

		self.must_attribute_types( *additional_object_classes ).each do |attrtype|
			# self.log.debug "  adding attrtype %p to the MUST attributes hash" % [ attrtype.name ]

			if attrtype.name == :objectClass
				attrhash[ :objectClass ] = ['top'] | additional_object_classes
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
	def may_attribute_types( *additional_object_classes )
		return self.object_classes( *additional_object_classes ).
			collect {|oc| oc.may }.flatten.uniq
	end


	### Return OIDs (numeric OIDs as Strings, named OIDs as Symbols) for each of the receiver's
	### objectClass's MAY attributeTypes. If any +additional_object_classes+ are given, 
	### include the OIDs of the MAY attributes for them as well. This can be used to predict 
	### what optional attributes could be added to the entry if the +additional_object_classes+ 
	### were added to it.
	def may_oids( *additional_object_classes )
		return self.object_classes( *additional_object_classes ).
			collect {|oc| oc.may_oids }.flatten.uniq
	end


	### Return a Hash of the optional attributes allowed by the Branch's objectClasses. If 
	### any +additional_object_classes+ are given, include the attributes that would be
	### available for the entry if it had them.
	def may_attributes_hash( *additional_object_classes )
		entry = self.entry
		attrhash = {}

		self.may_attribute_types( *additional_object_classes ).each do |attrtype|
			# self.log.debug "  adding attrtype %p to the MAY attributes hash" % [ attrtype.named ]

			if attrtype.single?
				attrhash[ attrtype.name ] = nil
			else
				attrhash[ attrtype.name ] = []
			end
		end

		# :FIXME: Does the resulting hash need the additional objectClasses? objectClass is
		#         MUST via 'top', so it should already exist in that hash when merged with
		#         this one...
		# attrhash[ :objectClass ] |= additional_object_classes

		return attrhash
	end


	### Return Treequel::Schema::AttributeType instances for the set of all of the receiver's
	### MUST and MAY attributeTypes plus the operational attributes.
	def valid_attribute_types
		return self.must_attribute_types |
		       self.may_attribute_types  |
		       self.operational_attribute_types
	end


	### Return a uniqified Array of OIDs (numeric OIDs as Strings, named OIDs as Symbols) for
	### the set of all of the receiver's MUST and MAY attributeTypes plus the operational
	### attributes.
	def valid_attribute_oids
		return self.must_oids | self.may_oids
	end


	### If the attribute associated with the given +attroid+ is in the list of valid 
	### attributeTypes for the receiver given its objectClasses, return the 
	### AttributeType object that corresponds with it. If it isn't valid, return nil.
	### Includes operational attributes.
	def valid_attribute_type( attroid )
		return self.valid_attribute_types.find {|attr_type| attr_type.valid_name?(attroid) }
	end


	### Return +true+ if the specified +attrname+ is a valid attributeType given the
	### receiver's current objectClasses. Does not include operational attributes.
	def valid_attribute?( attroid )
		return !self.valid_attribute_type( attroid ).nil?
	end


	### Return a Hash of all the attributes allowed by the Branch's objectClasses. If
	### any +additional_object_classes+ are given, include the attributes that would be
	### available for the entry if it had them.
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
	def method_missing( attribute, value=nil, additional_attributes={} )
		return super( attribute ) if value.nil?
		return self.traverse_branch( attribute, value, additional_attributes )
	end


	### If +attribute+ matches a valid attribute type in the directory's
	### schema, return a new Branch for the RDN of +attribute+ and +value+ and 
	### +additional_attributes+ (if it's a multi-value RDN).
	###
	###     # (Called via #method_missing)
	###     branch = Treequel::Branch.new( directory, 'ou=people,dc=acme,dc=com' )
	###     branch.uid( :chester ).dn
	###     # => 'uid=chester,ou=people,dc=acme,dc=com'
	###     branch.uid( :chester, :employeeType => 'admin' ).dn
	###     # => 'uid=chester+employeeType=admin,ou=people,dc=acme,dc=com'
	### 
	### Raises a NoMethodError if the +attribute+ or any +additional_attributes+ are
	### not valid attributeTypes.
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
		self.log.debug "Looking up entry for %s" % [ self.dn ]
		entry = nil

		if self.include_operational_attrs?
			self.log.debug "  including operational attributes."
			entry = self.directory.get_extended_entry( self )
		else
			self.log.debug "  not including operational attributes."
			entry = self.directory.get_entry( self )
		end

		entry.delete( 'dn' ) if entry
		self.log.debug "  entry is: %p" % [ entry ]
		return entry
	end


	### Get the value associated with +attrsym+, convert it to a Ruby object if the Branch's
	### directory has a conversion rule, and return it.
	def get_converted_object( attrsym )
		value = self.entry ? self.entry[ attrsym.to_s ] : nil

		if attribute = self.directory.schema.attribute_types[ attrsym ]
			syntax = attribute.syntax
			syntax_oid = syntax.oid if syntax

			if attribute.single?
				value = self.directory.convert_to_object( syntax_oid, value.first ) if value
			else
				value = Array( value ).collect do |raw|
					self.directory.convert_to_object( syntax_oid, raw )
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
			self.log.debug "converting %p object (a %p) to a %s attribute" %
				[ attrsym, object.class, attribute.syntax.desc ]
			return self.directory.convert_to_attribute( attribute.syntax_oid, object )
		else
			self.log.info "no attributeType for %p" % [ attrsym ]
			return object.to_s
		end
	end


	### Clear any cached values when the structural state of the object changes.
	def clear_caches
        self.log.debug "Clearing entry and values caches."
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
	def ldif_for_attr( attribute, value, width )
		unsplit_line = "#{attribute}:"

		if value.empty? || value =~ /\A#{LDIF_SAFE_STRING}\Z/
			unsplit_line << ' ' << value.to_s
		else
			unsplit_line << ': ' << [ value ].pack( 'm' ).chomp
		end
		unsplit_line.gsub!( /\n/, '' )

		ldif = ''
		ldif << unsplit_line.slice!( 0, width ) << LDIF_FOLD_SEPARATOR until
		 	unsplit_line.empty?

		ldif.rstrip!
		ldif << "\n"

		return ldif
	end


end # class Treequel::Branch


