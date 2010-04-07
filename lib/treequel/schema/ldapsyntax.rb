#!/usr/bin/env ruby

require 'English'

require 'treequel'
require 'treequel/mixins'
require 'treequel/schema'
require 'treequel/exceptions'


# This is a class for representing ldapSyntax declarations in a Treequel::Schema.
class Treequel::Schema::LDAPSyntax
	include Treequel::Loggable,
	        Treequel::Constants::Patterns

	extend Treequel::AttributeDeclarations


	#############################################################
	###	C L A S S   M E T H O D S
	#############################################################

	### Parse an LDAPSyntax entry from an ldapSyntax description from a schema.
	def self::parse( schema, description )
		unless match = ( LDAP_SYNTAX_DESCRIPTION.match(description) )
			raise Treequel::ParseError, "failed to parse syntax from %p" % [ description ]
		end

		oid, desc, extensions = match.captures
		# Treequel.logger.debug "  parsed syntax: %p" % [ match.captures ]

		# Normalize the attributes
		desc  = Treequel::Schema.unquote_desc( desc )

		return self.new( schema, oid, desc, extensions )
	end


	#############################################################
	###	I N S T A N C E   M E T H O D S
	#############################################################

	### Create a new LDAPSyntax
	def initialize( schema, oid, desc=nil, extensions=nil )

		@schema     = schema

		@oid        = oid
		@desc       = desc
		@extensions = extensions

		super()
	end


	######
	public
	######

	# The schema the syntax belongs to
	attr_reader :schema

	# The syntax's oid
	attr_reader :oid

	# The syntax's description
	attr_accessor :desc

	# The syntax's extensions (as a String)
	attr_accessor :extensions


	### Return a human-readable representation of the object suitable for debugging
	def inspect
		return "#<%s:0x%0x %s(%s)>" % [
			self.class.name,
			self.object_id / 2,
			self.oid,
			self.desc,
		]
	end


end # class Treequel::Schema::LDAPSyntax

