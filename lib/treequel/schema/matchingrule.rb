# -*- ruby -*-
#encoding: utf-8

require 'English'

require 'treequel'
require 'treequel/mixins'
require 'treequel/schema'
require 'treequel/exceptions'


# This is a class for representing matchingRule declarations in a Treequel::Schema.
class Treequel::Schema::MatchingRule
	include Treequel::Constants::Patterns
	extend Loggability,
	       Treequel::AttributeDeclarations


	# Loggability API -- Log to the Treequel module's logger
	log_to :treequel


	#############################################################
	###	C L A S S   M E T H O D S
	#############################################################

	### Parse an MatchingRule entry from a matchingRule description from a schema.
	def self::parse( schema, description )
		unless match = ( LDAP_MATCHING_RULE_DESCRIPTION.match(description) )
			raise Treequel::ParseError, "failed to parse matchingRule from %p" % [ description ]
		end

		oid, names, desc, obsolete, syntax_oid, extensions = match.captures
		# Treequel.logger.debug "  parsed matchingRule: %p" % [ match.captures ]

		# Normalize the attributes
		names = Treequel::Schema.parse_names( names )
		desc  = Treequel::Schema.unquote_desc( desc )

		return self.new( schema, oid, syntax_oid, names, desc, obsolete, extensions )
	end


	#############################################################
	###	I N S T A N C E   M E T H O D S
	#############################################################

	### Create a new MatchingRule
	def initialize( schema, oid, syntax_oid, names=nil, desc=nil, obsolete=false, extensions=nil )

		@schema     = schema

		@oid        = oid
		@syntax_oid = syntax_oid
		@names      = names
		@desc       = desc
		@obsolete   = obsolete ? true : false
		@extensions = extensions

		super()
	end


	######
	public
	######

	# The schema the matchingRule belongs to
	attr_reader :schema

	# The matchingRule's oid
	attr_reader :oid

	# The oid of the matchingRule's SYNTAX
	attr_accessor :syntax_oid

	# The Array of the matchingRule's names
	attr_reader :names

	# The matchingRule's description
	attr_accessor :desc

	# Is the matchingRule obsolete?
	predicate_attr :obsolete

	# The matchingRule's extensions (as a String)
	attr_accessor :extensions


	### Return the first of the matchingRule's names, if it has any, or +nil+.
	def name
		return self.names.first
	end


	# MatchingRuleDescription = LPAREN WSP
	#	numericoid                 ; object identifier
	#	[ SP "NAME" SP qdescrs ]   ; short names (descriptors)
	#	[ SP "DESC" SP qdstring ]  ; description
	#	[ SP "OBSOLETE" ]          ; not active
	#	SP "SYNTAX" SP numericoid  ; assertion syntax
	#	extensions WSP RPAREN      ; extensions

	### Returns the matchingRule as a String, which is the RFC4512-style schema
	### description.
	def to_s
		parts = [ self.oid ]

		parts << "NAME %s" % Treequel::Schema.qdescrs( self.names ) unless self.names.empty?

		parts << "DESC '%s'" % [ self.desc ]           if self.desc
		parts << "OBSOLETE"                            if self.obsolete?
		parts << "SYNTAX %s" % [ self.syntax_oid ]
		parts << self.extensions.strip             unless self.extensions.empty?

		return "( %s )" % [ parts.join(' ') ]
	end


	### Return a human-readable representation of the object suitable for debugging
	def inspect
		return "#<%s:0x%0x %s(%s) %s %sSYNTAX: %p>" % [
			self.class.name,
			self.object_id / 2,
			self.name,
			self.oid,
			self.desc,
			self.obsolete? ? "(OBSOLETE)" : '',
			self.syntax,
		]
	end


	### Return the Treequel::Schema::LDAPSyntax object that corresponds to the matchingRule's
	### SYNTAX attribute.
	def syntax
		return self.schema.ldap_syntaxes[ self.syntax_oid ]
	end

end # class Treequel::Schema::MatchingRule

