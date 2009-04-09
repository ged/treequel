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
#   veteran_davids = davids.filter( :employeeId < 2000 )
#   active_veteran_davids = 
#       veteran_davids.filter([:or, ['deactivated >= ?', Date.today], [:not, [:deactivated]] ])
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
# Please see the file LICENSE in the BASE directory for licensing details.
#
class Treequel::BranchSet
	include Treequel::Loggable,
	        Treequel::Constants


	# SVN Revision
	SVNRev = %q$Rev$

	# SVN Id
	SVNId = %q$Id$

	# The default scope to use when searching if none is specified
	DEFAULT_SCOPE = :subtree
	DEFAULT_SCOPE.freeze
	
	# The default filter to use when searching if none is specified
	DEFAULT_FILTER = '(objectClass=*)'
	DEFAULT_FILTER.freeze
	
	# The default options hash for new BranchSets
	DEFAULT_OPTIONS = {
		:scope   => DEFAULT_SCOPE,
		:filter  => DEFAULT_FILTER,
		:timeout => nil,                 # Floating-point timeout -> sec, usec
		:select  => nil,                 # Attributes to return -> attrs
		:order   => nil,                 # Sorting criteria -> s_attr/s_proc
	}.freeze


	#################################################################
	###	I N S T A N C E   M E T H O D S
	#################################################################

	### Create a new BranchSet for a search from the specified +base+ (a Treequel::Branch) with 
	### the given +options+.
	def initialize( base, options={} )
		@base    = base
		@options = DEFAULT_OPTIONS.merge( options )
	end
	
	
	######
	public
	######

	# The filterset's search options
	attr_reader :options
	

	### Fetch the entries which match the current criteria and return them as Treequel::Branch 
	### objects.
	def all
		directory = @base.directory
		scope     = @options[:scope]
		filter    = @options[:filter]

		# base_dn, scope, filter,
		#   attrs=nil, attrsonly=false,
		#   sec=0, usec=0,
		#   s_attr=nil, s_proc=nil
		return directory.search( @base, scope, filter )
	end
	
	
	### Returns a new +branchset+ 
	def filter( filterspec )
		
	end
	
	
end # class Treequel::BranchSet


