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
	include Treequel::Loggable

	### Exception type raised when an expression cannot be parsed from the
	### arguments given to Treequel::Filter.new
	class ExpressionError < RuntimeError; end


	### Filter list component of a Treequel::Filter.
	class FilterList
		include Treequel::Loggable

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
		include Treequel::Loggable

		# Hide this class's new method
		private_class_method :new

		### Inherited hook: re-expose inheriting class's .new method
		def self::inherited( klass )
			klass.module_eval( 'public_class_method :new' )
			super
		end


		### Stringify the component.
		### :TODO: If this doesn't end up being a refactored version of all of its 
		### subclasses's #to_s methods, test that it needs overriding.
		def to_s
			raise NotImplementedError, "%s does not provide an implementation of #to_s" %
				[ self.class.name ]
		end
		

		### Return a human-readable string representation of the component suitable 
		### for debugging.
		def inspect
			return %Q{#<%s:0x%0x "%s">} % [
				self.class.name,
				self.object_id * 2,
				self.to_s,
			]
		end
		
		### Components are non-promiscuous (don't match everything) by default.
		def promiscuous?
			return false
		end
		
	end # class Component


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
	###   simple     = attr filtertype value
	###   filtertype = equal / approx / greater / less
	###   equal      = "="
	###   approx     = "~="
	###   greater    = ">="
	###   less       = "<="
	class SimpleItemComponent < Treequel::Filter::ItemComponent
		
		# The valid values for +filtertype+ and the equivalent operator
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
			self.log.debug "creating a new %s %s for %p and %p" %
				[ filtertype, self.class.name, attribute, value ]

			@attribute  = attribute
			@value      = value
			@filtertype = filtertype
		end
		
		
		######
		public
		######

		# The name of the item's attribute
		attr_reader :attribute
		
		# The item's value
		attr_reader :value
		
		# The item's filter type (one of FILTERTYPE_OP.keys)
		attr_reader :filtertype


		### The operator that is associated with the item's +filtertype+.
		def filtertype_op
			FILTERTYPE_OP[ self.filtertype ]
		end
		
		
		### Stringify the component
		def to_s
			return [ self.attribute, self.filtertype_op, self.value ].join
		end
		
	end # class SimpleItemComponent
	
	
	### A presence (attribute=*) component
	class PresenceItemComponent < Treequel::Filter::ItemComponent
		
		# The default attribute to test for presence if none is specified
		DEFAULT_ATTRIBUTE = :objectClass
		
		### Create a new 'presence' item filter component for the given +attribute+.
		def initialize( attribute=DEFAULT_ATTRIBUTE )
			@attribute = attribute
		end
		
		
		### Stringify the component
		def to_s
			return @attribute.to_s + '=*'
		end
		
		
		### Returns true, indicating that this component in a filter will match every
		### entry if its attribute is 'objectClass'.
		def promiscuous?
			return @attribute.to_sym == DEFAULT_ATTRIBUTE
		end
		
	end # class PresenceItemComponent
	
	

	#################################################################
	###	F I L T E R   C O N S T A N T S
	#################################################################

	# The default filter expression to use when searching if none is specified
	DEFAULT_EXPRESSION = [ :objectClass ]
	DEFAULT_EXPRESSION.freeze

	# The mapping of leftmost symbols in a boolean expression and the
	# corresponding FilterComponent class.
	LOGICAL_COMPONENTS = {
		:or  => OrComponent,
		:|   => OrComponent,
		:and => AndComponent,
		:&   => AndComponent,
		:not => NotComponent,
		:"!" => NotComponent,
	}
	

	### Turn the specified filter +expression+ into a Treequel::Filter::Component
	### object and return it.
	def self::parse_expression( expression )
		Treequel.logger.debug "Parsing expression %p" % [ expression ]
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


	### Turn the specified expression Array into a Treequel::Filter::Component object
	### and return it.
	def self::parse_array_expression( expression )
		Treequel.logger.debug "Parsing Array expression %p" % [ expression ]
		
		case
		# [ ] := '(objectClass=*)'
		when expression.empty?
			Treequel.logger.debug "  empty expression -> objectClass presence item component"
			return PresenceItemComponent.new
			
		# [ :attribute ] := '(attribute=*)'
		when expression.length == 1
			Treequel.logger.debug "  unary expression -> presence item component"
			return PresenceItemComponent.new( *expression )

		# [ :and/:or/:not, [:uid, 1] ]    := (&/|/!(uid=1))
		when expression[1].is_a?( Array )
			return self.parse_logical_array_expression( *expression )
		
		# [ :or, {:uid => [1, 2]} ]    := (|(uid=1)(uid=2))
		when expression[1].is_a?( Hash )
			Treequel.logger.debug "  logical expression from a Hash"
			compclass = LOGICAL_COMPONENTS[ expression[0] ] or
				raise "don't know how to parse the tuple expression %p" % [ expression ]
			filterlist = expression[1].collect do |attribute, vals|
				vals.collect {|exp| Treequel::Filter.new(attribute, exp) }
			end.flatten
			return compclass.new( *filterlist )
			
		# [ :attribute, 'value' ]  := '(attribute=value)'
		when expression.length == 2
			Treequel.logger.debug "  tuple expression -> simple item component"
			return SimpleItemComponent.new( *expression )

		else
			raise Treequel::Filter::ExpressionError, 
				"don't know how to turn %p into a filter component" % [ expression ]
		end
		
	end
	
	
	### Break down the given +expression+ as a logical (AND, OR, or NOT)
	### filter component and return it.
	def self::parse_logical_array_expression( op, *components )
		Treequel.logger.debug "Parsing logical %p expression with components: %p" %
			[ op, components ]

		compclass = LOGICAL_COMPONENTS[ op ] or
			raise "don't know what a %p condition is. I only know about: %p" %
			 	[ op, LOGICAL_COMPONENTS.keys ]

		filterlist = components.collect do |comp|
			case comp.first
			when String, Symbol
				Treequel::Filter.new( comp )
			when Treequel::Filter
				comp
			else
				raise Treequel::Filter::ExpressionError,
					"don't know how to turn %p into a %p component" % [ comp, op ]
			end
		end.flatten

		return compclass.new( *filterlist )
	end
	

	#################################################################
	###	I N S T A N C E   M E T H O D S
	#################################################################

	### Create a new Treequel::BranchSet::Filter with the specified +expression+.
	def initialize( *expression_parts )
		@component = self.class.parse_expression( expression_parts )
		self.log.debug "created a filter with component: %p" % [ @component ]

		super()
	end


	######
	public
	######

	# The filtercomp part of the filter
	attr_accessor :component


	### Return the Treequel::BranchSet::Filter as a String.
	def to_s
		self.log.debug "stringifying filter %p" % [ self ]
		filtercomp = self.component.to_s
		if filtercomp[0] == ?(
			return filtercomp
		else
			return '(' + filtercomp + ')'
		end
	end


	### Return a human-readable string representation of the filter suitable 
	### for debugging.
	def inspect
		return %{#<%s:0x%0x (%s)} % [
			self.class.name,
			self.object_id * 2,
			self.component,
		]
	end
	
	
	### Returns +true+ if the filter contains a single 'present' component for
	### the objectClass attribute (which will match every entry)
	def promiscuous?
		return self.component.promiscuous?
	end
	alias_method :is_promiscuous?, :promiscuous?
	
	
	### Equality operator -- returns +true+ if +other_filter+ is equivalent
	### to the receiver.
	def ==( other_filter )
		return ( self.component == other_filter.component )
	end
	

	### AND two filters together
	def &( other_filter )
		return other_filter if self.promiscuous?
		return self.dup if other_filter.promiscuous?
		return self.class.new( :and, [self, other_filter] )
	end
	alias_method :+, :&



end # class Treequel::Filter

