#!/usr/bin/env ruby

require 'English'

require 'treequel'
require 'treequel/mixins'
require 'treequel/schema'
require 'treequel/exceptions'


# This is a class for representing attributeType declarations in a Treequel::Schema.
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
#---
#
# Please see the file LICENSE in the base directory for licensing details.
#
class Treequel::Schema::AttributeType
	include Treequel::Loggable,
	        Treequel::Constants::Patterns

	extend Treequel::AttributeDeclarations


	#############################################################
	###	C L A S S   M E T H O D S
	#############################################################

	### Parse an AttributeType entry from a attributeType description from a schema.
	def self::parse( description )
		unless match = ( LDAP_ATTRIBUTE_TYPE_DESCRIPTION.match(description) )
			raise Treequel::ParseError, "failed to parse attributeType from %p" % [ description ]
		end

		oid, names, desc, obsolete, sup, eqmatch_oid, ordmatch_oid, submatch_oid, valsynoid,
			single, collective, nousermod, usagetype, extensions = match.captures

		# Normalize the attributes
		names = Treequel::Schema.parse_names( names )
		desc  = Treequel::Schema.unquote_desc( desc )

		eqmatch_oid = Treequel::Schema.parse_oid( eqmatch_oid ) if eqmatch_oid
		ordmatch_oid = Treequel::Schema.parse_oid( ordmatch_oid ) if ordmatch_oid
		submatch_oid = Treequel::Schema.parse_oid( submatch_oid ) if submatch_oid

		# Invert the 'no-user-modification' attribute
		usermodifiable = nousermod ? false : true

		return self.new( oid, names, desc, obsolete, sup, eqmatch_oid, ordmatch_oid, submatch_oid,
			valsynoid, single, collective, usermodifiable, usagetype, extensions )
	end


	#############################################################
	###	I N S T A N C E   M E T H O D S
	#############################################################

	### Create a new AttributeType
	def initialize( oid, names=nil, desc=nil, obsolete=false, sup=nil, eqmatch_oid=nil,
	                ordmatch_oid=nil, submatch_oid=nil, valsynoid=nil, single=false,
	                collective=false, user_modifiable=true, usagetype=nil, extensions=nil )

		@oid             = oid
		@names           = names
		@desc            = desc
		@obsolete        = obsolete ? true : false
		@sup             = sup
		@eqmatch_oid     = eqmatch_oid
		@ordmatch_oid    = ordmatch_oid
		@submatch_oid    = submatch_oid
		@valsynoid       = valsynoid
		@single          = single ? true : false
		@collective      = collective ? true : false
		@user_modifiable = user_modifiable ? true : false
		@usagetype       = usagetype
		@extensions      = extensions

		super()
	end


	######
	public
	######

	# The attributeType's oid
	attr_reader :oid

	# The Array of the attributeType's names
	attr_reader :names

	# The attributeType's description
	attr_accessor :desc

	# Is the attributeType obsolete?
	predicate_attr :obsolete

	# The attributeType's superior class
	attr_accessor :sup

	# The oid of the attributeType's equality matching rule
	attr_accessor :eqmatch_oid

	# The oid of the attributeType's order matching rule
	attr_accessor :ordmatch_oid

	# The oid of the attributeType's substring matching rule
	attr_accessor :submatch_oid

	# The oid of the attributeType's value syntax
	attr_accessor :valsynoid

	# Are attributes of this type restricted to a single value?
	predicate_attr :single

	# Are attributes of this type collective?
	predicate_attr :collective

	# Are attributes of this type user-modifiable?
	predicate_attr :user_modifiable

	# The application of this attributeType
	attr_accessor :usagetype

	# The attributeType's extensions (as a String)
	attr_accessor :extensions


	### Return the first of the attributeType's names, if it has any, or +nil+.
	def name
		return self.names.first
	end


end # class ObjectClass

