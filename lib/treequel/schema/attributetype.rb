#!/usr/bin/env ruby

require 'English'

require 'treequel'
require 'treequel/mixins'
require 'treequel/schema'
require 'treequel/exceptions'


# This is a class for representing attributeType declarations in a Treequel::Schema.
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
class Treequel::Schema::AttributeType
	include Treequel::Loggable,
	        Treequel::Normalization,
	        Treequel::Constants::Patterns

	extend Treequel::AttributeDeclarations

	# Regex for splitting a syntax OID from its length specifier
	OID_SPLIT_PATTERN = /
		^
		#{SQUOTE}?
		(#{OID})					# OID = $1
		#{SQUOTE}?
		(?:
			#{LCURLY}
			(#{LEN})				# Length = $2
			#{RCURLY}
		)?$
	/x

	# The default USAGE type: "Usage of userApplications, the default,
	# indicates that attributes of this type represent user information.
	# That is, they are user attributes." (RFC4512)
	DEFAULT_USAGE_TYPE = 'userApplications'.freeze

	# A usage of directoryOperation, distributedOperation, or dSAOperation
	# indicates that attributes of this type represent operational and/or
	# administrative information.  That is, they are operational
	# attributes. (RFC4512)
	OPERATIONAL_ATTRIBUTE_USAGES = %w[directoryOperation distributedOperation dSAOperation].freeze


	#############################################################
	###	C L A S S   M E T H O D S
	#############################################################

	### Parse an AttributeType entry from a attributeType description from a schema.
	def self::parse( schema, description )
		unless match = ( LDAP_ATTRIBUTE_TYPE_DESCRIPTION.match(description) )
			raise Treequel::ParseError, "failed to parse attributeType from %p" % [ description ]
		end

		oid, names, desc, obsolete, sup_oid, eqmatch_oid, ordmatch_oid, submatch_oid, syntax_oid,
			single, collective, nousermod, usagetype, extensions = match.captures

		# Normalize the attributes
		names = Treequel::Schema.parse_names( names )
		desc  = Treequel::Schema.unquote_desc( desc )

		sup_oid = Treequel::Schema.parse_oid( sup_oid ) if sup_oid
		eqmatch_oid = Treequel::Schema.parse_oid( eqmatch_oid ) if eqmatch_oid
		ordmatch_oid = Treequel::Schema.parse_oid( ordmatch_oid ) if ordmatch_oid
		submatch_oid = Treequel::Schema.parse_oid( submatch_oid ) if submatch_oid

		return self.new( schema, oid,
			:names           => names,
			:desc            => desc,
			:obsolete        => obsolete,
			:sup_oid         => sup_oid,
			:eqmatch_oid     => eqmatch_oid,
			:ordmatch_oid    => ordmatch_oid,
			:submatch_oid    => submatch_oid,
			:syntax_oid      => syntax_oid,
			:single          => single,
			:collective      => collective,
			:user_modifiable => nousermod ? false : true,
			:usagetype       => usagetype || DEFAULT_USAGE_TYPE,
			:extensions      => extensions
		  )
	end


	#############################################################
	###	I N S T A N C E   M E T H O D S
	#############################################################

	### Create a new AttributeType
	def initialize( schema, oid, attributes )

		@schema          = schema

		@oid             = oid
		@names           = attributes[:names]
		@desc            = attributes[:desc]
		@obsolete        = attributes[:obsolete] ? true : false
		@sup_oid         = attributes[:sup_oid]
		@eqmatch_oid     = attributes[:eqmatch_oid]
		@ordmatch_oid    = attributes[:ordmatch_oid]
		@submatch_oid    = attributes[:submatch_oid]
		@single          = attributes[:single] ? true : false
		@collective      = attributes[:collective] ? true : false
		@user_modifiable = attributes[:user_modifiable] ? true : false
		@usagetype       = attributes[:usagetype]
		@extensions      = attributes[:extensions]

		@syntax_oid, @syntax_len = split_syntax_oid( attributes[:syntax_oid] ) if
			attributes[:syntax_oid]

		super()
	end


	######
	public
	######

	# The schema the attributeType belongs to
	attr_reader :schema

	# The attributeType's oid
	attr_reader :oid

	# The Array of the attributeType's names
	attr_reader :names

	# The attributeType's description
	attr_accessor :desc

	# Is the attributeType obsolete?
	predicate_attr :obsolete

	# The attributeType's superior class's OID
	attr_accessor :sup_oid

	# The oid of the attributeType's equality matching rule
	attr_accessor :eqmatch_oid

	# The oid of the attributeType's order matching rule
	attr_accessor :ordmatch_oid

	# The oid of the attributeType's substring matching rule
	attr_accessor :submatch_oid

	# The oid of the attributeType's value syntax
	attr_accessor :syntax_oid

	# The (optional) syntax length qualifier (nil if not present)
	attr_accessor :syntax_len

	# Are attributes of this type restricted to a single value?
	predicate_attr :single

	# Are attributes of this type collective?
	predicate_attr :collective

	# Are attributes of this type user-modifiable?
	predicate_attr :user_modifiable

	# The application of this attributeType
	attr_accessor :usagetype
	alias_method :usage, :usagetype
	alias_method :usage=, :usagetype=

	# The attributeType's extensions (as a String)
	attr_accessor :extensions


	### Return the first of the attributeType's names, if it has any, or +nil+.
	def name
		return self.names.first
	end


	### Return the attributeType's names after normalizing them.
	def normalized_names
		return self.names.collect {|name| normalize_key(name) }
	end


	### Returns +true+ if the specified +name+ is one of the attribute's names
	### after normalization of both.
	def valid_name?( name )
		normname = normalize_key( name )
		return self.normalized_names.include?( normname )
	end


	### Return the Treequel::Schema::AttributeType instance that corresponds to 
	### the receiver's superior type. If the attributeType doesn't have a SUP
	### attribute, this method returns +nil+.
	def sup
		return nil unless oid = self.sup_oid
		return self.schema.attribute_types[ oid ]
	end


	### Returns the attributeType as a String, which is the RFC4512-style schema
	### description.
	def to_s
		parts = [ self.oid ]

		parts << "NAME %s" % Treequel::Schema.qdescrs( self.names ) unless self.names.empty?

		parts << "DESC '%s'" % [ self.desc ]           if self.desc
		parts << "OBSOLETE"                            if self.obsolete?
		parts << "SUP %s" % [ self.sup_oid ]           if self.sup_oid
		parts << "EQUALITY %s" % [ self.eqmatch_oid ]  if self.eqmatch_oid
		parts << "ORDERING %s" % [ self.ordmatch_oid ] if self.ordmatch_oid
		parts << "SUBSTR %s" % [ self.submatch_oid ]   if self.submatch_oid
		if self.syntax_oid
			parts << "SYNTAX %s" % [ self.syntax_oid ]
			parts.last << "{%d}" % [ self.syntax_len ] if self.syntax_len
		end
		parts << "SINGLE-VALUE"                        if self.is_single?
		parts << "COLLECTIVE"                          if self.is_collective?
		parts << "NO-USER-MODIFICATION"            unless self.is_user_modifiable?
		parts << "USAGE %s" % [ self.usagetype ]       if self.usagetype
		parts << self.extensions.strip             unless self.extensions.empty?

		return "( %s )" % [ parts.join(' ') ]
	end


	### Return a human-readable representation of the object suitable for debugging
	def inspect
		return "#<%s:0x%0x %s(%s) %p %sSYNTAX: %p (length: %s)>" % [
			self.class.name,
			self.object_id / 2,
			self.name,
			self.oid,
			self.desc,
			self.is_single? ? '(SINGLE) ' : '',
			self.syntax_oid,
			self.syntax_len ? self.syntax_len : 'unlimited',
		]
	end


	### Return the Treequel::Schema::MatchingRule that corresponds to the EQUALITY 
	### matchingRule of the receiving attributeType.
	def equality_matching_rule
		if oid = self.eqmatch_oid
			return self.schema.matching_rules[ oid ]
		elsif self.sup
			return self.sup.equality_matching_rule
		else
			return nil
		end
	end


	### Return the Treequel::Schema::MatchingRule that corresponds to the ORDERING 
	### matchingRule of the receiving attributeType.
	def ordering_matching_rule
		if oid = self.ordmatch_oid
			return self.schema.matching_rules[ oid ]
		elsif self.sup
			return self.sup.ordering_matching_rule
		else
			return nil
		end
	end


	### Return the Treequel::Schema::MatchingRule that corresponds to the SUBSTR
	### matchingRule of the receiving attributeType.
	def substr_matching_rule
		if oid = self.submatch_oid
			return self.schema.matching_rules[ oid ]
		elsif self.sup
			return self.sup.substr_matching_rule
		else
			return nil
		end
	end


	### Return the Treequel::Schema::LDAPSyntax that corresponds to the receiver's SYNTAX attribute.
	def syntax
		if oid = self.syntax_oid
			return self.schema.ldap_syntaxes[ oid ]
		elsif self.sup
			return self.sup.syntax
		else
			return nil
		end
	end


	# Usage of userApplications, the default, indicates that attributes of
	# this type represent user information.  That is, they are user
	# attributes.

	### Test whether or not the attrinbute is a user applications attribute.
	### @return [Boolean]  true if the attribute's USAGE is 'userApplications' (or nil)
	def is_user?
		return !self.is_operational?
	end
	alias_method :user?, :is_user?


	### Test whether or not the attribute is an operational attribute.
	### @return [Boolean]  true if the attribute's usage is one of the OPERATIONAL_ATTRIBUTE_USAGES
	def is_operational?
		usage_type = self.usage || DEFAULT_USAGE_TYPE
		return OPERATIONAL_ATTRIBUTE_USAGES.map( &:downcase ).include?( usage_type.downcase )
	end
	alias_method :operational?, :is_operational?


	### Test whether or not the attribute is a directory operational attribute.
	### @return [Boolean]  true if the attribute's usage is 'directoryOperation'
	def is_directory_operational?
		usage_type = self.usage || DEFAULT_USAGE_TYPE
		return usage_type == 'directoryOperation'
	end
	alias_method :directory_operational?, :is_directory_operational?


	### Test whether or not the attribute is a distributed operational attribute.
	### @return [Boolean]  true if the attribute's usage is 'distributedOperation'
	def is_distributed_operational?
		usage_type = self.usage || DEFAULT_USAGE_TYPE
		return usage_type == 'distributedOperation'
	end
	alias_method :distributed_operational?, :is_distributed_operational?


	### Test whether or not the attribute is a DSA-specific operational attribute.
	### @return [Boolean]  true if the attribute's usage is 'dSAOperation'
	def is_dsa_operational?
		usage_type = self.usage || DEFAULT_USAGE_TYPE
		return usage_type == 'dSAOperation'
	end
	alias_method :dsa_operational?, :is_dsa_operational?
	alias_method :dsa_specific?, :is_dsa_operational?


	#######
	private
	#######

	### Split a numeric OID with an optional length qualifier into a numeric OID and length. If
	### no length qualifier is present, it will be nil.
	### NOTE: Modified to support ActiveDirectory schemas, which have both quoted numeric OIDs 
	### and descriptors as syntax OIDs.
	def split_syntax_oid( noidlen )
		unless noidlen =~ OID_SPLIT_PATTERN
			raise Treequel::ParseError, "invalid syntax OID: %p" % [ noidlen ]
		end

		oidstring, len = $1, $2
		oid = Treequel::Schema.parse_oid( oidstring )

		return oid, len ? Integer(len) : nil
	end

end # class Treequel::Schema::AttributeType

