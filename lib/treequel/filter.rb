#!/usr/bin/env ruby

require 'ldap'

require 'treequel' 
require 'treequel/branchset'


# This is an object that is used to build an LDAP filter for Treequel::BranchSets.
#
# == Grammar (from RFC 2254) ==
#
#   filter     = "(" filtercomp ")"
#   filtercomp = and / or / not / item
#   and        = "&" filterlist
#   or         = "|" filterlist
#   not        = "!" filter
#   filterlist = 1*filter
#   item       = simple / present / substring / extensible
#   simple     = attr filtertype value
#   filtertype = equal / approx / greater / less
#   equal      = "="
#   approx     = "~="
#   greater    = ">="
#   less       = "<="
#   extensible = attr [":dn"] [":" matchingrule] ":=" value
#                / [":dn"] ":" matchingrule ":=" value
#   present    = attr "=*"
#   substring  = attr "=" [initial] any [final]
#   initial    = value
#   any        = "*" *(value "*")
#   final      = value
#   attr       = AttributeDescription from Section 4.1.5 of [1]
#   matchingrule = MatchingRuleId from Section 4.1.9 of [1]
#   value      = AttributeValue from Section 4.1.6 of [1]
# 
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
class Treequel::Filter

	### Exception type raised when an expression cannot be parsed from the
	### arguments given to Treequel::Filter.new
	class ExpressionError < RuntimeError; end


	### Filter list component of a Treequel::Filter.
	class FilterList

		### Create a new filter list with the given +filter+ in it.
		def initialize( *filters )
			@filters = filters
		end

		######
		public
		######

		# The filters in the FilterList
		attr_reader :filters


		### Return the FilterList as a string.
		def to_s
			return self.filters.collect {|f| f.to_s }.join
		end

	end # class FilterList


	### An abstract class for filter components.
	class Component

		### Stringify the component.
		### :TODO: If this doesn't end up being a refactored version of all of its 
		### subclasses's #to_s methods, test that it needs overriding.
		def to_s
			raise NotImplementedError, "%s does not provide an implementation of #to_s" %
				[ self.class.name ]
		end
	end


	### A filtercomp that negates the filter it contains.
	class NotComponent < Treequel::Filter::Component

		### Create an negation component of the specified +filter+.
		def initialize( filter )
			@filter = filter
		end

		### Return the stringified filter form of the receiver.
		def to_s
			return '!' + @filter.to_s
		end

	end


	### An 'and' filter component
	class AndComponent < Treequel::Filter::Component
		include Treequel::Loggable
		
		### Create a new 'and' filter component with the given +filterlist+.
		def initialize( *filterlist )
			@filterlist = filterlist
			super()
		end
		
		# The list of filters to AND together in the filter string
		attr_reader :filterlist
		
		### Stringify the item
		def to_s
			return '&' + @filterlist.collect {|c| c.to_s }.join
		end
		
	end # AndComponent


	### An 'or' filter component
	class OrComponent < Treequel::Filter::Component
		
		### Create a new 'or' filter component with the given +filterlist+.
		def initialize( *filterlist )
			@filterlist = filterlist
			super()
		end

		# The list of filters to OR together in the filter string
		attr_reader :filterlist
		
		### Stringify the item
		def to_s
			return '|' + @filterlist.collect {|c| c.to_s }.join
		end
		
	end # class OrComponent


	### An 'item' filter component
	class ItemComponent < Treequel::Filter::Component; end


	### A simple (attribute=value) component
	class SimpleItemComponent < Treequel::Filter::ItemComponent
		
		# simple     = attr filtertype value
		# filtertype = equal / approx / greater / less
		# equal      = "="
		# approx     = "~="
		# greater    = ">="
		# less       = "<="
		FILTERTYPE_OP = {
			:equal   => '=',
			:approx  => '~=',
			:greater => '>=',
			:less    => '<=',
		}
		FILTERTYPE_OP.freeze

		
		### Create a new 'simple' item filter component with the given
		### +attribute+, +filtertype+, and +value+. The +filtertype+ should
		### be one of: :equal, :approx, :greater, :less
		def initialize( attribute, value, filtertype=:equal )
			@attribute = attribute
			@value = value
			@filtertype = filtertype
		end
		
		
		### Stringify the component
		def to_s
			return [ @attribute, FILTERTYPE_OP[@filtertype], @value ].join
		end
		
	end # class SimpleItemComponent
	
	
	### A presence (attribute=*) component
	class PresenceItemComponent < Treequel::Filter::ItemComponent
		
		# The default attribute to test for presence if none is specified
		DEFAULT_ATTRIBUTE = 'objectClass'
		
		### Create a new 'presence' item filter component for the given +attribute+.
		def initialize( attribute=DEFAULT_ATTRIBUTE )
			@attribute = attribute
		end
		
		
		### Stringify the component
		def to_s
			return @attribute.to_s + '=*'
		end
		
	end # class PresenceItemComponent
	
	

	#################################################################
	###	F I L T E R   C O N S T A N T S
	#################################################################

	# The default filter expression to use when searching if none is specified
	DEFAULT_EXPRESSION = [ :objectClass ]
	DEFAULT_EXPRESSION.freeze


	### Turn the specified filter +expression+ into a Treequel::Filter::Component
	### object and return it.
	def self::parse_expression( expression )
		expression = expression[0] if expression.is_a?( Array ) && expression.length == 1

		case expression
			
		# String-literal filters
		when String
			return expression

		# 'Item' components
		when Array
			return self.parse_array_expression( expression )

		# Unwrapped presence item filter
		when Symbol
			return PresenceItemComponent.new( expression )
			
		else
			raise Treequel::Filter::ExpressionError, 
				"don't know how to turn %p into an filter component" % [ expression ]
		end
	end


	LOGICAL_COMPONENTS = {
		:or  => OrComponent,
		:|   => OrComponent,
		:and => AndComponent,
		:&   => AndComponent,
		:not => NotComponent,
		:"!" => NotComponent,
	}
	

	### Turn the specified expression Array into a Treequel::Filter::Component object
	### and return it.
	def self::parse_array_expression( expression )
		Treequel.logger.debug "Parsing Array expression %p" % [ expression ]
		
		case
		# [ ] := '(objectClass=*)'
		when expression.empty?
			return PresenceItemComponent.new
			
		# [ :attribute ] := '(attribute=*)'
		when expression.length == 1
			return PresenceItemComponent.new( *expression )

		# [ :and/:or/:not, [] ]    := (&/|/!())
		when expression[1].is_a?( Array )
			compclass = LOGICAL_COMPONENTS[ expression[0] ] or
				raise "don't know how to parse the tuple expression %p" % [ expression ]
			filterlist = expression[1..-1].collect {|exp| Treequel::Filter.new(exp) }
			return compclass.new( *filterlist )
			
		# [ :attribute, 'value' ]  := '(attribute=value)'
		when expression.length == 2
			return SimpleItemComponent.new( *expression )

		else
			raise Treequel::Filter::ExpressionError, 
				"don't know how to turn %p into a filter component" % [ expression ]
		end
		
	end
	

	#################################################################
	###	I N S T A N C E   M E T H O D S
	#################################################################

	### Create a new Treequel::BranchSet::Filter with the specified +expression+.
	def initialize( *expression_parts )
		@component = self.class.parse_expression( expression_parts )

		super()
	end


	######
	public
	######

	# The filtercomp part of the filter
	attr_reader :component

	### Return the Treequel::BranchSet::Filter as a String.
	def to_s
		filtercomp = self.component.to_s
		if filtercomp[0] == ?(
			return filtercomp
		else
			return '(' + filtercomp + ')'
		end
	end


end # class Treequel::Filter

