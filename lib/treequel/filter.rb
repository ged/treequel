#!/usr/bin/env ruby

require 'ldap'

require 'treequel'
require 'treequel/branchset'
require 'treequel/exceptions'
require 'treequel/sequel_integration'


# This is an object that is used to build an LDAP filter for Treequel::Branchsets.
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
class Treequel::Filter
	include Treequel::Loggable,
	        Treequel::Constants::Patterns

	### Filter list component of a Treequel::Filter.
	class FilterList
		include Treequel::Loggable

		### Create a new filter list with the given +filters+ in it.
		def initialize( *filters )
			@filters = filters.flatten
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


		### Append operator: add the +other+ filter to the list.
		def <<( other )
			@filters << other
			return self
		end

	end # class FilterList


	### An abstract class for filter components.
	### Subclass and override #to_s to implement a custom Component class.
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
			@filterlist = Treequel::Filter::FilterList.new( filterlist )
			super()
		end

		# The list of filters to AND together in the filter string
		attr_reader :filterlist

		### Stringify the item
		def to_s
			return '&' + @filterlist.to_s
		end

		### Add an additional filter to the list of requirements
		def add_requirement( filter )
			@filterlist << filter
		end

	end # AndComponent


	### An 'or' filter component
	class OrComponent < Treequel::Filter::Component

		### Create a new 'or' filter component with the given +filterlist+.
		def initialize( *filterlist )
			@filterlist = Treequel::Filter::FilterList.new( filterlist )
			super()
		end

		# The list of filters to OR together in the filter string
		attr_reader :filterlist

		### Stringify the item
		def to_s
			return '|' + @filterlist.to_s
		end

		### Add an additional filter to the list of alternatives
		def add_alternation( filter )
			@filterlist << filter
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
		include Treequel::Constants::Patterns

		# The valid values for +filtertype+ and the equivalent operator
		FILTERTYPE_OP = {
			:equal   => '=',
			:approx  => '~=',
			:greater => '>=',
			:less    => '<=',
		}
		FILTERTYPE_OP.freeze

		# Inverse of the FILTERTYPE_OP mapping (symbol -> name)
		FILTEROP_NAMES = FILTERTYPE_OP.invert.freeze

		# A regex that matches any of the 'simple' operators.
		FILTER_SPLIT_REGEXP = Regexp.new( '(' + FILTERTYPE_OP.values.join('|') + ')' )
		FILTER_SPLIT_REGEXP.freeze


		### Parse a new SimpleItemComponent from the specified +literal+.
		def self::parse_from_string( literal )
			parts = literal.split( FILTER_SPLIT_REGEXP, 3 )
			unless parts.length == 3
				raise Treequel::ExpressionError,
					"unable to parse %p as a string literal" % [ literal ]
			end

			attribute, operator, value = *parts
			filtertype = FILTEROP_NAMES[ operator ]

			return self.new( attribute, value, filtertype )
		end


		### Create a new 'simple' item filter component with the given
		### +attribute+, +filtertype+, and +value+. The +filtertype+ should
		### be one of: :equal, :approx, :greater, :less
		def initialize( attribute, value, filtertype=:equal )
			self.log.debug "creating a new %s %s for %p and %p" %
				[ filtertype, self.class.name, attribute, value ]

			# Handle Sequel :attribute.identifier
			attribute = attribute.value if attribute.respond_to?( :value )

			filtertype = filtertype.to_s.downcase.to_sym
			if FILTERTYPE_OP.key?( filtertype )
				# no-op
			elsif FILTEROP_NAMES.key?( filtertype.to_s )
				filtertype = FILTEROP_NAMES[ filtertype.to_s ]
			else
				raise Treequel::ExpressionError,
					"invalid simple item operator %p" % [ filtertype ]
			end

			@attribute  = attribute
			@value      = value
			@filtertype = filtertype
		end


		######
		public
		######

		# The name of the item's attribute
		attr_accessor :attribute

		# The item's value
		attr_accessor :value

		# The item's filter type (one of FILTERTYPE_OP.keys)
		attr_accessor :filtertype


		### The operator that is associated with the item's +filtertype+.
		def filtertype_op
			FILTERTYPE_OP[ self.filtertype.to_sym ]
		end


		### Stringify the component
		def to_s
			# Escape all the filter metacharacters
			escaped_val = self.value.to_s.gsub( UNESCAPED ) do |char|
				'\\' + char.unpack('C*').first.to_s(16)
			end

			return [ self.attribute, self.filtertype_op, escaped_val ].join
		end

	end # class SimpleItemComponent


	### A 'present' (attribute=*) component
	class PresentItemComponent < Treequel::Filter::ItemComponent

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

	end # class PresentItemComponent


	### A 'substring' (attribute=foo*) component
	class SubstringItemComponent < Treequel::Filter::ItemComponent
		include Treequel::Constants::Patterns


		### Parse the substring item from the given +literal+.
		def self::parse_from_string( literal )
			match = LDAP_SUBSTRING_FILTER.match( literal ) or
				raise Treequel::ExpressionError,
					"unable to parse %p as a substring literal" % [ literal ]

			Treequel.logger.debug "  parsed substring literal as: %p" % [ match.captures ]
			return self.new( *(match.captures.values_at(1,3,2)) )
		end


		#############################################################
		###	I N S T A N C E   M E T H O D S
		#############################################################

		### Create a new 'substring' item filter component that will match the specified +pattern+ 
		### against the given +attribute+.
		def initialize( attribute, pattern, options=nil )
			@attribute = attribute
			@pattern   = pattern
			@options   = options

			super()
		end


		######
		public
		######

		# The name of the attribute to match against
		attr_accessor :attribute

		# The pattern to match (if the index exists in the directory)
		attr_accessor :pattern

		# The attribute options
		attr_accessor :options


		### Stringify the component
		def to_s
			return self.attribute.to_s + self.options.to_s + '=' + self.pattern
		end

	end # class SubstringItemComponent



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

	# An equivalence mapping of operation names from Sequel expressions into
	# Treequel equivalents
	SEQUEL_FILTERTYPE_EQUIVALENTS = {
		:like => :equal,
		:>=   => :greater,
		:<=   => :less,
	}
	SEQUEL_FILTERTYPE_EQUIVALENTS.freeze

	# A list of filtertypes that come in as Sequel::Expressions; these generated nicer
	# exception messages that just 'unknown filtertype'
	UNSUPPORTED_SEQUEL_FILTERTYPES = {
		:'~*' => %{LDAP doesn't support Regex filters},
		:'~'  => %{LDAP doesn't support Regex filters},
		:>    => %{LDAP doesn't support "greater-than"; use "greater-than-or-equal-to" (>=) instead},
		:<    => %{LDAP doesn't support "less-than"; use "less-than-or-equal-to" (<=) instead},
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

		# Composite item components
		when Hash
			return self.parse_hash_expression( expression )

		# Unwrapped presence item filter
		when Symbol
			return Treequel::Filter::PresentItemComponent.new( expression )

		# Support Sequel expressions
		when Sequel::SQL::Expression
			return self.parse_sequel_expression( expression )

		# Filters and components can already act as components of other filters
		when Treequel::Filter, Treequel::Filter::Component
			return expression

		else
			raise Treequel::ExpressionError, 
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
			return Treequel::Filter::PresentItemComponent.new

		# Collection of subfilters
		# [ [:uid, 'mahlon'], [:employeeNumber, 20202] ]
		when expression.all? {|elem| elem.is_a?(Array) }
			Treequel.logger.debug "  parsing array of subfilters"
			filters = expression.collect {|exp| Treequel::Filter.new(exp) }
			if filters.length > 1
				return Treequel::Filter::AndComponent.new( filters )
			else
				return filters.first
			end

		# Literal filters [ 'uid~=gung', 'l=bangkok' ]  := '(uid~=gung)(l=bangkok)'
		when expression.all? {|item| item.is_a?(String) }
			filters = expression.collect {|item| Treequel::Filter.new(item) }
			return Treequel::Filter::FilterList.new( filters )

		# Collection of subfilter objects
		when expression.all? {|elem| elem.is_a?(Treequel::Filter) }
			return Treequel::Filter::FilterList.new( expression )

		# [ :attribute ] := '(attribute=*)'
		when expression.length == 1
			return self.parse_expression( expression[0] )

		when expression[0].is_a?( Symbol )
			return self.parse_tuple_array_expression( expression )

		else
			raise Treequel::ExpressionError,
				"don't know how to turn %p into a filter component" % [ expression ]
		end

	end


	### Parse one or more tuples contained in a Hash into an ANDed set of 
	### Treequel::Filter::Components and return it.
	def self::parse_hash_expression( expression )
		Treequel.logger.debug "Parsing Hash expression %p" % [ expression ]

		filterlist = expression.collect do |key, expr|
			Treequel.logger.debug "  adding %p => %p to the filter list" % [ key, expr ]
			if expr.respond_to?( :fetch )
				if expr.respond_to?( :length ) && expr.length > 1
					Treequel.logger.debug "    ORing together %d subfilters since %p has indices" %
						[ expr.length, expr ]
					subfilters = expr.collect {|val| Treequel::Filter.new(key, val) }
					Treequel::Filter.new( :or, subfilters )
				else
					Treequel.logger.debug "    unwrapping singular subfilter"
					Treequel::Filter.new([ key.to_sym, expr.first ])
				end
			else
				Treequel.logger.debug "    value is a scalar; creating a single filter"
				Treequel::Filter.new( key.to_sym, expr )
			end
		end

		if filterlist.length > 1
			return Treequel::Filter::AndComponent.new( *filterlist )
		else
			return filterlist.first
		end
	end


	### Parse a tuple of the form: [ Symbol, Object ] into a Treequel::Filter::Component
	### and return it.
	def self::parse_tuple_array_expression( expression )
		Treequel.logger.debug "Parsing tuple Array expression %p" % [ expression ]

		case expression[1]

		# [ :and/:or/:not, [:uid, 1] ]      := (&/|/!(uid=1))
		# [ :and/:or/:not, {:uid => 1} ]    := (&/|/!(uid=1))
		when Array, Hash
			return self.parse_logical_array_expression( *expression )

		when Range
			Treequel.logger.debug "  two ANDed item expressions from a Range"
			attribute = expression[0]
			range = expression[1]
			left = "#{attribute}>=#{range.begin}"
			right = "#{attribute}<=#{range.exclude_end? ? range.max : range.end}"
			return self.parse_logical_array_expression( :and, [left, right] )

		# [ :attribute, 'value' ]  := '(attribute=value)'
		# when String, Symbol, Numeric, Time
		else
			Treequel.logger.debug "  item expression from a %p" % [ expression[1].class ]
			return self.parse_item_component( *expression )
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

		filterlist = components.collect do |filterexp|
			Treequel.logger.debug "  making %p into a component" % [ filterexp ]
			Treequel::Filter.new( filterexp )
		end.flatten

		return compclass.new( *filterlist )
	end


	### Parse an item component from the specified +attribute+ and +value+
	def self::parse_item_component( attribute, value )
		Treequel.logger.debug "  tuple expression (%p=%p)-> item component" %
			[ attribute, value ]

		case
		when attribute.to_s.index( ':' )
			raise NotImplementedError, "extensible filters are not yet supported"
		when value == '*'
			return Treequel::Filter::PresentItemComponent.new( attribute )
		when value =~ LDAP_SUBSTRING_FILTER_VALUE
			return Treequel::Filter::SubstringItemComponent.new( attribute, value )
		else
			return Treequel::Filter::SimpleItemComponent.new( attribute, value )
		end
	end


	### Parse a Sequel::SQL::Expression as a Treequel::Filter::Component and return it.
	def self::parse_sequel_expression( expression )
		Treequel.logger.debug "  parsing Sequel expression: %p" % [ expression ]

		if expression.respond_to?( :op )
			op = expression.op.to_s.downcase.to_sym

			if equivalent = SEQUEL_FILTERTYPE_EQUIVALENTS[ op ]
				attribute, value = *expression.args

				# Turn :sn.like( 'bob' ) into (cn~=bob) 'cause it has no asterisks
				if op == :like 
					if value.index( '*' )
						Treequel.logger.debug \
							"    turning a LIKE expression with an asterisk into a substring filter"
						return Treequel::Filter::SubstringItemComponent.new( attribute, value )
					else
						Treequel.logger.debug \
							"    turning a LIKE expression with no wildcards into an 'approx' filter"
						equivalent = :approx
					end
				end

				return Treequel::Filter::SimpleItemComponent.new( attribute, value, equivalent )

			elsif op == :'!='
				contents = Treequel::Filter.new( expression.args )
				return Treequel::Filter::NotComponent.new( contents )

			elsif op == :'not like'
				Treequel.logger.debug "  making a NOT LIKE expression out of: %p" % [ expression ]
				attribute, value = *expression.args
				component = nil

				if value.index( '*' )
					component = Treequel::Filter::SubstringItemComponent.new( attribute, value )
				else
					component = Treequel::Filter::SimpleItemComponent.new( attribute, value, :approx )
				end

				filter = Treequel::Filter.new( component )
				return Treequel::Filter::NotComponent.new( filter )

			elsif LOGICAL_COMPONENTS.key?( op )
				components = expression.args.collect do |comp|
					Treequel::Filter.new( comp )
				end

				return self.parse_logical_array_expression( op, components )

			elsif msg = UNSUPPORTED_SEQUEL_FILTERTYPES[ op ]
				raise Treequel::ExpressionError,
					"unsupported Sequel filter syntax %p: %s" %
					[ expression, msg ]
			else
				raise ScriptError,
					"  unhandled Sequel BooleanExpression: add handling for %p: %p" % [ op, expression ]
			end

		else
			raise Treequel::ExpressionError,
				"don't know how to turn %p into a component" % [ expression ]
		end
	end


	#################################################################
	###	I N S T A N C E   M E T H O D S
	#################################################################

	### Create a new Treequel::Branchset::Filter with the specified +expression+.
	def initialize( *expression_parts )
		self.log.debug "New filter for expression: %p" % [ expression_parts ]
		@component = self.class.parse_expression( expression_parts )
		self.log.debug "  expression parsed into component: %p" % [ @component ]

		super()
	end


	######
	public
	######

	# The filtercomp part of the filter
	attr_accessor :component


	### Return the Treequel::Branchset::Filter as a String.
	def to_s
		# self.log.debug "stringifying filter %p" % [ self ]
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
		return %{#<%s:0x%0x (%s)>} % [
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


	### Return a new Filter that is the AND filter of the receiver with +other_filter+.
	def &( other_filter )
		return other_filter if self.promiscuous?
		return self.dup if other_filter.promiscuous?
		return self.class.new( :and, [self, other_filter] )
	end
	alias_method :+, :&


	### Return a new Filter that is the OR filter of the receiver with +other_filter+.
	def |( other_filter )
		return other_filter if self.promiscuous?
		return self.dup if other_filter.promiscuous?

		# Collapse nested ORs into a single one with an additional alternation
		# if possible.
		if self.component.respond_to?( :add_alternation )
			self.log.debug "collapsing nested ORs..."
			newcomp = self.component.dup
			newcomp.add_alternation( other_filter )
			return self.class.new( newcomp )
		else
			return self.class.new( :or, [self, other_filter] )
		end
	end


end # class Treequel::Filter

