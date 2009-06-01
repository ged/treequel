#!/usr/bin/env ruby

require 'English'

require 'treequel'
require 'treequel/mixins'
require 'treequel/schema'
require 'treequel/exceptions'


# This is a class for representing matchingRuleUse declarations in a Treequel::Schema.
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
class Treequel::Schema::MatchingRuleUse
	include Treequel::Loggable,
	        Treequel::Constants::Patterns

	extend Treequel::AttributeDeclarations


	#############################################################
	###	C L A S S   M E T H O D S
	#############################################################

	### Parse an MatchingRuleUse entry from a matchingRuleUse description from a schema.
	def self::parse( schema, description )
		unless match = ( LDAP_MATCHING_RULE_USE_DESCRIPTION.match(description) )
			raise Treequel::ParseError, "failed to parse matchingRuleUse from %p" % [ description ]
		end

		oid, names, desc, obsolete, attr_oids, extensions = match.captures
		Treequel.logger.debug "  parsed matchingRuleUse: %p" % [ match.captures ]

		# Normalize the attributes
		names     = Treequel::Schema.parse_names( names )
		desc      = Treequel::Schema.unquote_desc( desc )
		attr_oids = Treequel::Schema.parse_oids( attr_oids )

		return self.new( schema, oid, attr_oids, names, desc, obsolete, extensions )
	end


	#############################################################
	###	I N S T A N C E   M E T H O D S
	#############################################################

	### Create a new MatchingRuleUse
	def initialize( schema, oid, attr_oids, names=nil, desc=nil, obsolete=false, extensions=nil )
		@schema     = schema

		@oid        = oid
		@names      = names
		@desc       = desc
		@obsolete   = obsolete ? true : false
		@attr_oids  = attr_oids

		@extensions = extensions

		super()
	end


	######
	public
	######

	# The schema the matchingRuleUse belongs to
	attr_reader :schema

	# The matchingRuleUse's oid
	attr_reader :oid

	# The Array of the matchingRuleUse's names
	attr_reader :names

	# The matchingRuleUse's description
	attr_accessor :desc

	# Is the matchingRuleUse obsolete?
	predicate_attr :obsolete

	# The OIDs of the attributes the matchingRuleUse applies to
	attr_reader :attr_oids

	# The matchingRuleUse's extensions (as a String)
	attr_accessor :extensions


	### Return the first of the matchingRuleUse's names, if it has any, or +nil+.
	def name
		return self.names.first
	end


	### Return a human-readable representation of the object suitable for debugging
	def inspect
		return "#<%s:0x%0x %s(%s) %p -> %p >" % [
			self.class.name,
			self.object_id / 2,
			self.name,
			self.oid,
			self.desc,
			self.attr_oids,
		]
	end


	### Return Treequel::Schema::AttributeType objects for each of the types this MatchingRuleUse
	### applies to.
	def attribute_types
		return self.attr_oids.collect {|oid| self.schema.attribute_types[oid] }
	end

end # class Treequel::Schema::MatchingRuleUse

