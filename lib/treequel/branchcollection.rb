#!/usr/bin/env ruby
# coding: utf-8

require 'ldap'

require 'treequel'
require 'treequel/mixins'
require 'treequel/constants'
require 'treequel/branch'


# A Treequel::BranchCollection is a union of Treequel::BranchSets,
# suitable for performing operations on multiple branches of the
# directory at once.
# 
# For example, if you have hosts under ou=Hosts in two different
# subdomains (e.g., acme.com, seattle.acme.com, and newyork.acme.com),
# and you want to search for a host by its CN, you could do so like
# this:
# 
#   # Top-level hosts, and those in the 'seattle' subdomain, but not
#   # those in the 'newyork' subdomain:
#   west_coast_hosts = dir.ou( :hosts ) + dir.dc( :seattle ).ou( :hosts )
#   west_coast_www_hosts = west_coast_hosts.filter( :cn => 'www' )
#   
#   # And one that includes hosts in all three DCs:
#   all_hosts = west_coast_hosts + dir.dc( :newyork ).ou( :hosts )
#   all_ns_hosts = all_hosts.filter( :cn => 'ns*' )
# 
# Note that you could accomplish most of what BranchCollection does
# using filters, but some people might find this a bit more readable.
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
class Treequel::BranchCollection
	include Treequel::Loggable,
	        Treequel::Constants

	extend Treequel::Delegation

	# SVN Revision
	SVNRev = %q$Rev$

	# SVN Id
	SVNId = %q$Id$


	#################################################################
	###	C L A S S   M E T H O D S
	#################################################################

	### Create a delegator that will return an instance of the receiver created with the results of
	### iterating over the branchsets and calling the delegated method.
	def self::def_cloning_delegators( *symbols )
		symbols.each do |methname|
			# Create the method body
			methodbody = Proc.new {|*args|
				mutated_branchsets = self.branchsets.
					collect {|bs| bs.send(methname, *args) }.flatten
				self.class.new( *mutated_branchsets )
			}

			# ...and install it
			self.send( :define_method, methname, &methodbody )
		end
	end


	#################################################################
	###	I N S T A N C E   M E T H O D S
	#################################################################

	### Create a new Treequel::BranchCollection that will operate on the given +branchsets+.
	def initialize( *branchsets )
		@branchsets = branchsets.flatten
	end


	### Declare some delegator methods that clone the receiver with the results of mapping
	### the branchsets with the delegated method.
	def_cloning_delegators :filter, :scope, :select, :select_all, :select_more, :timeout,
		:without_timeout, :order

	### Delegate some methods through the collection directly
	def_method_delegators :branchsets, :include?


	######
	public
	######

	# The collection's branchsets
	attr_reader :branchsets


	### Return all of the Treequel::Branches returned from the collection's branchsets.
	def all
		return self.branchsets.collect {|bs| bs.all }.flatten
	end


	### Return the first Treequel::Branch that is returned from the collection's branchsets.
	def first
		branch = nil

		self.branchsets.each do |bs|
			break if branch = bs.first
		end

		return branch
	end


	### Append operator: add the specified +object+ (either a Treequel::Branchset or an object 
	### that responds to #branchset and returns a Treequel::Branchset) to the collection 
	### and return the receiver.
	def <<( object )
		if object.respond_to?( :branchset )
			self.branchsets << object.branchset
		else
			self.branchsets << object
		end

		return self
	end


	### Return a new Treequel::BranchCollection that includes both the receiver's Branchsets and
	### those in +other_object+ (or +other_object+ itself if it's a Branchset).
	def +( other_object )
		if other_object.respond_to?( :branchsets )
			return self.class.new( self.branchsets + other_object.branchsets )
		elsif other_object.respond_to?( :branchset )
			return self.class.new( self.branchsets + [other_object.branchset] )
		else
			return self.class.new( self.branchsets + [other_object] )
		end
	end


	### Return a new Treequel::BranchCollection that contains the union of the branchsets from both
	### collections.
	def &( other_collection )
		return self.class.new( self.branchsets & other_collection.branchsets )
	end


	### Return a new Treequel::BranchCollection that contains the intersection of the branchsets 
	### from both collections.
	def |( other_collection )
		return self.class.new( self.branchsets | other_collection.branchsets )
	end


	### Return the base DN of all of the collection's Branchsets.
	def base_dns
		return self.branchsets.collect {|bs| bs.base_dn }
	end


end # class Treequel::BranchCollection


