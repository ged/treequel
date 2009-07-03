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
#--
#
# Please see the file LICENSE in the base directory for licensing details.
#
class Treequel::Branchset
	include Enumerable,
	        Treequel::Loggable,
	        Treequel::Constants

	# SVN Revision
	SVNRev = %q$Rev$

	# SVN Id
	SVNId = %q$Id$

	# The default scope to use when searching if none is specified
	DEFAULT_SCOPE = :subtree
	DEFAULT_SCOPE.freeze

	# The default filter to use when searching if non is specified
	DEFAULT_FILTER = :objectClass
	DEFAULT_FILTER.freeze


	# The default options hash for new Branchsets
	DEFAULT_OPTIONS = {
		:base    => nil,
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

	### Create a new Branchset for a search from the specified +base+ (a Treequel::Branch), with 
	### the given +options+.
	def initialize( base, options={} )
		super()
		@base = base
		@options = DEFAULT_OPTIONS.merge( options )
	end


	######
	public
	######

	# The branchset's search options hash
	attr_accessor :options

	# The branchset's base branch that will be used when searching as the basedn
	attr_accessor :base


	### Returns the DN of the Branchset's base Branch.
	def base_dn
		return self.base.dn
	end


	### Override the default clone method to support cloning with different options.
	def clone( options={} )
		self.log.debug "cloning %p with options = %p" % [ self, options ]
		newset = super()
		newset.options = @options.merge( options )
		return newset
	end


	### Return a human-readable string representation of the object suitable for debugging.
	def inspect
		"#<%s:0x%0x base='%s', filter=%s, scope=%s, options=%p>" % [
			self.class.name,
			self.object_id * 2,
			self.base,
			self.filter_string,
			@scope,
			self.options,
		]
	end


	### Return an LDAP filter string made up of the current filter components.
	def filter_string
		return self.filter.to_s
	end


	### Fetch the entries which match the current criteria and return them as Treequel::Branch 
	### objects.
	def all
		directory = self.base.directory
		return directory.search( self.base, self.scope, self.filter,
			:selectattrs => self.select,
			:timeout => self.timeout,
			:sortby => self.order,
			:limit => self.limit
		  )
	end


	### Iterate over the entries which match the current criteria and yield each of them 
	### as Treequel::Branch objects to the supplied block.
	def each
		raise LocalJumpError, "no block given" unless block_given?
		block = Proc.new
		self.all.each( &block )
	end


	### Fetch the first entry which matches the current criteria and return it as an instance of
	### the object that is set as the +base+ (e.g., Treequel::Branch).
	def first
		# :FIXME: This could eventually be implemented with the "paged results" control so
		# it only actually fetches one row, but for now it just fetches everything and returns
		# the first value
		directory = self.base.directory
		return directory.search( self.base, self.scope, self.filter,
			:selectattrs => self.select,
			:timeout => self.timeout,
			:sortby => self.order,
			:limit => 1
		  ).first
	end


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


	### Return a clone of the receiving Branchsest that will order its results by the
	### +attributes+ specified.
	def order( attribute=:__default__ )
		if attribute == :__default__
			if block_given?
				sort_func = Proc.new
				return self.clone( :order => sort_func )
			else
				return self.options[:order]
			end
		elsif attribute.nil?
			self.log.debug "cloning %p with no order" % [ self ]
			return self.clone( :order => nil )
		else
			self.log.debug "cloning %p with new order: %p" % [ self, attribute ]
			return self.clone( :order => attribute.to_sym )
		end
	end


end # class Treequel::Branchset


