#!/usr/bin/env ruby
# coding: utf-8

require 'forwardable'
require 'ldap'

require 'treequel'
require 'treequel/mixins'
require 'treequel/constants'
require 'treequel/branch'
require 'treequel/filter'
require 'treequel/sequel_integration'
require 'treequel/control'


# A branchset represents an abstract set of LDAP records returned by
# a search in a directory. It can be used to create, retrieve, update,
# and delete records.
# 
# Search results are fetched on demand, so a branchset can be kept
# around and reused indefinitely (branchsets never cache results):
# 
#   people = directory.ou( :people )
#   davids = people.filter(:firstName => 'david') # no records are retrieved
#   davids.all # records are retrieved
#   davids.all # records are retrieved again
# 
# Most branchset methods return modified copies of the branchset
# (functional style), so you can reuse different branchsets to access
# data:
# 
#   # (employeeId < 2000)
#   veteran_davids = davids.filter( :employeeId < 2000 )
#   
#   # (&(employeeId < 2000)(|(deactivated >= '2008-12-22')(!(deactivated=*))))
#   active_veteran_davids = 
#       veteran_davids.filter([:or, ['deactivated >= ?', Date.today], [:not, [:deactivated]] ])
#   
#   # (&(employeeId < 2000)(|(deactivated >= '2008-12-22')(!(deactivated=*)))(mobileNumber=*))
#   active_veteran_davids_with_cellphones = 
#       active_veteran_davids.filter( [:mobileNumber] )
# 
# Branchsets are Enumerable objects, so they can be manipulated using any of the 
# Enumerable methods, such as map, inject, etc.
class Treequel::Branchset
	include Enumerable,
	        Treequel::Loggable,
	        Treequel::Constants,
	        Treequel::Control

	# The default scope to use when searching if none is specified
	DEFAULT_SCOPE = :subtree
	DEFAULT_SCOPE.freeze

	# The default filter to use when searching if non is specified
	DEFAULT_FILTER = :objectClass
	DEFAULT_FILTER.freeze


	# The default options hash for new Branchsets
	DEFAULT_OPTIONS = {
		:filter  => DEFAULT_FILTER,
		:scope   => DEFAULT_SCOPE,
		:timeout => 0,                  # Floating-point timeout -> sec, usec
		:select  => [],                 # Attributes to return -> attrs
		:order   => '',                 # Sorting criteria -> s_attr/s_proc
		:limit   => 0,                  # Limit -> number of results
	}.freeze


	#################################################################
	###	I N S T A N C E   M E T H O D S
	#################################################################

	### Create a new Branchset for a search from the DN of the specified +branch+ (a 
	### Treequel::Branch), with the given +options+.
	def initialize( branch, options={} )
		@branch = branch
		@options = DEFAULT_OPTIONS.merge( options )
		self.log.debug "Setting up %p for branch %p with options: %p" %
			[ self.class, @branch, @options ]

		if @branch.directory.registered_controls.empty?
			self.log.debug "  no registered controls."
		else
			@branch.directory.registered_controls.each do |control|
				self.log.debug "  extending with %p" % [ control ]
				self.extend( control )
			end
		end

		super()
	end


	######
	public
	######

	alias_method :all, :entries

	# The branchset's search options hash
	attr_accessor :options

	# The branchset's base branch that will be used when searching as the basedn
	attr_accessor :branch


	### Extend the Branchset with one or more modules. Overridden to also call the modules'
	### initializers if they have them.
	def extend( *modules )
		super
		modules.each do |mod|
			mod.instance_method( :initialize ).bind( self ).call if
				mod.private_instance_methods.map( &:to_sym ).include?( :initialize )
		end
	end


	### Returns the DN of the Branchset's branch.
	def base_dn
		return self.branch.dn
	end


	### Override the default clone method to support cloning with different options.
	def clone( options={} )
		self.log.debug "cloning %p with options = %p" % [ self, options ]
		newset = super()
		newset.options = @options.merge( options )
		return newset
	end


	### Return a string representation of the Branchset's filter
	def uri
		# :scheme,
		# :host, :port,
		# :dn,
		# :attributes,
		# :scope,
		# :filter,
		# :extensions,
		uri = self.branch.uri
		uri.attributes = self.select.join(',')
		uri.scope = SCOPE_NAME[ self.scope ]
		uri.filter = self.filter_string
		# :TODO: Add extensions? Support extensions in Branchset?

		return uri
	end


	### Return the Branchset as a stringified URI.
	def to_s
		return "%s/%s" % [ self.branch.dn, self.filter_string ]
	end


	### Return a human-readable string representation of the object suitable for debugging.
	def inspect
		"#<%s:0x%0x base_dn='%s', filter=%s, scope=%s, select=%s, limit=%d, timeout=%0.3f>" % [
			self.class.name,
			self.object_id * 2,
			self.base_dn,
			self.filter_string,
			self.scope,
			self.select.empty? ? '*' : self.select.join(','),
			self.limit,
			self.timeout,
		]
	end


	### Return an LDAP filter string made up of the current filter components.
	def filter_string
		return self.filter.to_s
	end


	### Create a BranchCollection from the results of the Branchset and return it.
	def collection
		return Treequel::BranchCollection.new( self.all )
	end


	### If given another Branchset or a BranchCollection, return a BranchCollection that includes
	### them both. If given anything else, execute the search and return 
	### @param [Treequel::Branchset, Treequel::Branch] other  the branchset or branch to combine 
	###                                                       with
	### @return [Treequel::BranchCollection, Array<Treequel::Branch>]
	def +( other )
		if other.is_a?( Treequel::BranchCollection ) || other.is_a?( Treequel::Branchset )
			return Treequel::BranchCollection.new( self, other )
		else
			return self.all + Array( other )
		end
	end


	### Return the results of executing the search without the +other_object+.
	### @param [#dn] other_object  the object to omit from the results; must respond_to #dn.
	### @return [Array<Treequel::Branch>]
	def -( other_object )
		other_dn = other_object.dn
		return self.reject {|branch| branch.dn.downcase == other_dn.downcase }
	end


	### Iterate over the entries which match the current criteria and yield each of them 
	### as Treequel::Branch objects to the supplied block.
	def each( &block )
		raise LocalJumpError, "no block given" unless block

		self.branch.search( self.scope, self.filter,
			:selectattrs => self.select,
			:timeout => self.timeout,
			# :sortby => self.order,
			:limit => self.limit,
			:client_controls => self.get_client_controls,
			:server_controls => self.get_server_controls,
			&block
		  )
	end


	### Fetch the first entry which matches the current criteria and return it as an instance of
	### the object that is set as the +branch+ (e.g., Treequel::Branch).
	def first
		self.branch.search( self.scope, self.filter,
			:selectattrs => self.select,
			:timeout => self.timeout,
			# :sortby => self.order,
			:client_controls => self.get_client_controls,
			:server_controls => self.get_server_controls,
			:limit => 1
		  ).first
	end


	### Return +true+ if no entries match the Branchset's current criteria.
	def empty?
		return self.first.nil? ? true : false
	end


	### Either maps entries which match the current criteria into an Array of the given 
	### +attribute+, or falls back to the block form if no +attribute+ is specified. If both an
	### +attribute+ and a +block+ are given, the +block+ is called once for each +attribute+ value
	### instead of with each Branch.
	def map( attribute=nil, &block ) # :yields: branch or attribute
		if attribute
			if block
				super() {|branch| block.call(branch[attribute]) }
			else
				super() {|branch| branch[attribute] }
			end
		else
			super( &block )
		end
	end


	### Map the results returned by the search into a hash keyed by the first value of +keyattr+
	### in the entry. If the optional +valueattr+ argument is given, the values will be the 
	### first corresponding attribute, else the value will be the whole entry.
	def to_hash( keyattr, valueattr=nil )
		return self.inject({}) do |hash, branch|
			key = branch[ keyattr ]
			key = key.first if key.respond_to?( :first )

			# Extract either the valueattr, or the whole entry hash if no valueattr was given.
			if valueattr
				self.log.debug "  extracting value for attribute %p" % [ valueattr ]
				if branch[ valueattr ].respond_to?( :first )
					hash[ key ] = branch[ valueattr ].first
				else
					hash[ key ] = branch[ valueattr ]
				end
			else
				self.log.debug "  using the whole entry hash (%p)"
				hash[ key ] = branch.entry
			end

			hash
		end
	end


	### 
	### Mutators
	### 

	### Returns a clone of the receiving Branchset with the given +filterspec+ added
	### to it.
	def filter( *filterspec )
		if filterspec.empty?
			opts = self.options
			opts[:filter] = Treequel::Filter.new(opts[:filter]) unless
				opts[:filter].is_a?( Treequel::Filter )
			return opts[:filter]
		else
			self.log.debug "cloning %p with filterspec: %p" % [ self, filterspec ]
			newfilter = Treequel::Filter.new( *filterspec )
			return self.clone( :filter => self.filter + newfilter )
		end
	end


	### Add an alternate filter to an existing filter by ORing them.
	### @param filterspec  the filter spec to OR with the existing filter
	### @raises [Treequel::InvalidOperation]  if there is no existing filter
	### @see Treequel::Filter.new  for specifics on what +filterspec+ can be
	def or( *filterspec )
		opts = self.options
		existing_filter = self.filter
		raise Treequel::ExpressionError, "no existing filter" if
			existing_filter.promiscuous?

		newfilter = Treequel::Filter.new( *filterspec )

		self.log.debug "cloning %p with alternative filterspec: %p" % [ self, filterspec ]
		return self.clone( :filter => (self.filter | newfilter) )
	end


	### If called with no argument, returns the current scope of the Branchset. If 
	### called with an argument (which should be one of the keys of 
	### Treequel::Constants::SCOPE), returns a clone of the receiving Branchset
	### with the +new_scope+.
	def scope( new_scope=nil )
		if new_scope
			self.log.debug "cloning %p with new scope: %p" % [ self, new_scope ]
			return self.clone( :scope => new_scope.to_sym )
		else
			return @options[:scope]
		end
	end


	### If called with one or more +attributes+, returns a clone of the receiving
	### Branchset that will only fetch the +attributes+ specified. If no +attributes+
	### are specified, return the list of attributes that will be fetched by the
	### receiving Branchset. An empty Array means that it should fetch all
	### attributes, which is the default.
	def select( *attributes )
		if attributes.empty?
			return self.options[:select].collect {|attribute| attribute.to_s }
		else
			self.log.debug "cloning %p with new selection: %p" % [ self, attributes ]
			return self.clone( :select => attributes )
		end
	end


	### Returns a clone of the receiving Branchset that will fetch all attributes.
	def select_all
		return self.clone( :select => [] )
	end


	### Return a clone of the receiving Branchset that will fetch the specified
	### +attributes+ in addition to its own.
	def select_more( *attributes )
		return self.select( *(Array(@options[:select]) | attributes) )
	end


	### Return a clone of the receiving Branchset that will fetch any operational attributes
	### in addition to its own. This is exactly equivalent to:
	###
	###    branchset.select( :+ ).
	def with_operational_attributes
		return self.select( :+ )
	end


	### If called with a +new_limit+, returns a clone of the receiving Branchset that will
	### fetch (at most) +new_limit+ Branches. If no +new_limit+ argument is specified,
	### returns the Branchset's current limit. A limit of '0' means that all Branches
	### will be fetched.
	def limit( new_limit=nil )
		if new_limit.nil?
			return self.options[:limit]
		else
			self.log.debug "cloning %p with new limit: %p" % [ self, new_limit ]
			return self.clone( :limit => Integer(new_limit) )
		end
	end


	### Return a clone of the receiving Branchset that has no restriction on the number
	### of Branches that will be fetched.
	def without_limit
		return self.clone( :limit => 0 )
	end


	### Return a clone of the receiving Branchset that will search with its timeout
	### set to +seconds+, which is in floating-point seconds.
	def timeout( seconds=nil )
		if seconds
			return self.clone( :timeout => seconds )
		else
			return @options[:timeout]
		end
	end


	### Return a clone of the receiving Branchset that will not use a timeout when
	### searching.
	def without_timeout
		return self.clone( :timeout => 0 )
	end


	### Return a clone of the receiving Branchset that will return instances of the
	### give +branchclass+ instead of Treequel::Branch objects. This may be a subclass
	### of Treequel::Branch, but it doesn't need to be as long as they duck-type the 
	### same.
	def as( branchclass )
		newset = self.clone
		newset.branch = branchclass.new( self.branch.directory, self.branch.dn )
		return newset
	end


	### Return a clone of the receiving Branchset that will perform its search from
	### +other_dn+ instead of its own.
	### @param [String, #dn]  other_dn  the new base DN of the search
	def from( other_dn )
		newset = self.clone
		other_dn = other_dn.dn if other_dn.respond_to?( :dn )
		newset.branch = newset.branch.class.new( self.branch.directory, other_dn )
		return newset
	end

end # class Treequel::Branchset


