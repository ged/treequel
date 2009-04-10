#!/usr/bin/env ruby

require 'forwardable'
require 'ldap'

require 'treequel' 
require 'treequel/mixins'
require 'treequel/constants'
require 'treequel/branch'


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
#---
#
# Please see the file LICENSE in the base directory for licensing details.
#
class Treequel::BranchSet
	include Treequel::Loggable,
	        Treequel::Constants

	require 'treequel/branchset/clauses'

	# SVN Revision
	SVNRev = %q$Rev$

	# SVN Id
	SVNId = %q$Id$

	# The default scope to use when searching if none is specified
	DEFAULT_SCOPE = :subtree
	DEFAULT_SCOPE.freeze
	
	# The default filter to use when searching if none is specified
	DEFAULT_FILTER = [ :objectClass, '*' ]
	DEFAULT_FILTER.freeze
	
	# The default options hash for new BranchSets
	DEFAULT_OPTIONS = {
		:filter  => DEFAULT_FILTER,
		:scope   => DEFAULT_SCOPE,
		:timeout => nil,                 # Floating-point timeout -> sec, usec
		:select  => nil,                 # Attributes to return -> attrs
		:order   => nil,                 # Sorting criteria -> s_attr/s_proc
	}.freeze


	#################################################################
	###	I N S T A N C E   M E T H O D S
	#################################################################

	### Create a new BranchSet for a search from the specified +base+ (a Treequel::Branch), with 
	### the given +options+.
	def initialize( base, options={} )
		options = DEFAULT_OPTIONS.merge( options )
		
		@base           = base
		@filter_clauses = [ options.delete(:filter) ]
		@scope          = options.delete( :scope )

		@options        = options
	end

	
	######
	public
	######

	# The base branchset
	attr_reader :base

	# The filterset's search options
	attr_reader :options

	# The Array of filter clauses
	attr_reader :filter_clauses


	### Return a human-readable string representation of the object suitable for debugging.
	def inspect
		"#<%s:0x%0x filter=%s, scope=%s, options=%p>" % [
			self.class.name,
			self.object_id * 2,
			self.filter_string,
			@scope,
			self.options
		]
	end
	

	### Fetch the entries which match the current criteria and return them as Treequel::Branch 
	### objects.
	def all
		directory = @base.directory

		# base_dn, scope, filter,
		#   attrs=nil, attrsonly=false,
		#   sec=0, usec=0,
		#   s_attr=nil, s_proc=nil
		return directory.search( @base, @scope, self.filter_string )
	end

	
	### Returns a clone of the receiving +branchset+ with the given +filterspec+ added
	### to it.
	def filter( filterspec )
		if self.filter_clauses == [ DEFAULT_FILTER ]
			self.log.debug "replacing default filter with %p" % [ filterspec ]
			clauses = filterspec.to_a
		else
			self.log.debug "adding filterspec: %p" % [ filterspec ]
			clauses = self.filter_clauses + [ filterspec.to_a ]
		end

		options = self.options.merge( :filter => clauses )

		self.log.debug "cloning %p with options: %p" % [ self, options ]
		return self.class.new( self.base, options )
	end


	### Return an LDAP filter string made up of the current filter clauses.
	def filter_string
		return self.filter_clauses.
			collect {|attribute,value| "(#{attribute}=#{value})" }.
			join
	end
	
	
end # class Treequel::BranchSet


