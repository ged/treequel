# -*- ruby -*-
#encoding: utf-8
# coding: utf-8

require 'ldap'

require 'treequel'
require 'treequel/mixins'
require 'treequel/constants'
require 'treequel/branch'


# A Treequel::BranchCollection is a union of Treequel::Branchset
# objects, suitable for performing operations on multiple branches
# of the directory at once.
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
class Treequel::BranchCollection
	include Enumerable,
	        Treequel::Constants

	extend Loggability,
	       Treequel::Delegation


	# Loggability API -- Log to the Treequel module's logger
	log_to :treequel


	#################################################################
	###	C L A S S   M E T H O D S
	#################################################################

	### Create a delegator that will return an instance of the receiver
	### created with the results of iterating over the branchsets and calling
	### the delegated method.
	def self::def_cloning_delegators( *symbols )
		symbols.each do |methname|
			# Create the method body
			methodbody = Proc.new {|*args|

				# Check to be sure the mutator version of the method is being called
				arity = self.branchsets.first.method( methname ).arity
				if arity.nonzero? && args.empty?
					raise ArgumentError, "wrong number of arguments: (0 for %d)" % [ arity.abs ]
				end

				mutated_branchsets = self.branchsets.
					collect {|bs| bs.send(methname, *args) }.flatten
				self.class.new( *mutated_branchsets )
			}

			# ...and install it
			self.send( :define_method, methname, &methodbody )
		end
	end
	private_class_method :def_cloning_delegators


	#################################################################
	###	I N S T A N C E   M E T H O D S
	#################################################################

	### Create a new Treequel::BranchCollection that will operate on the given +branchsets+, which
	### can be either Treequel::Branchset or Treequel::Branch objects.
	def initialize( *branchsets )
		@branchsets = branchsets.flatten.collect do |obj|
			if obj.respond_to?( :each )
				obj
			else
				Treequel::Branchset.new( obj )
			end
		end
	end


	##
	# Delegator methods that clone the receiver with the results of mapping
	# the branchsets with the delegated method.

	def_cloning_delegators :filter, :scope, :select, :select_all, :select_more, :timeout,
		:without_timeout

	##
	# Delegators that some methods through the collection directly

	def_method_delegators :branchsets, :include?


	######
	public
	######

	alias_method :all, :entries


	# The collection's branchsets
	attr_reader :branchsets


	### Return a human-readable string representation of the object suitable for debugging.
	def inspect
		"#<%s:0x%0x %d branchsets: %p>" % [
			self.class.name,
			self.object_id * 2,
			self.branchsets.length,
			self.branchsets.collect {|bs| bs.to_s },
		]
	end


	### Iterate over the Treequel::Branches found by each member branchset, yielding each
	### one in turn.
	def each( &block )
		raise LocalJumpError, "no block given" unless block
		self.branchsets.each do |bs|
			bs.each( &block )
		end
	end


	### Return the first Treequel::Branch that is returned from the collection's branchsets.
	def first
		branch = nil

		self.branchsets.each do |bs|
			break if branch = bs.first
		end

		return branch
	end


	### Return +true+ if none of the collection's branches match any entries.
	def empty?
		return self.branchsets.all? {|bs| bs.empty? } ? true : false
	end


	### Overridden to support Branchset#map
	def map( attribute=nil, &block )
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


	### Return either a new Treequel::BranchCollection that includes both the receiver's
	### Branchsets and those in +other_object+ (if it responds_to #branchsets), or the results
	### from executing the BranchCollection's search with +other_object+ appended if it doesn't.
	def +( other_object )
		if other_object.respond_to?( :branchsets )
			return self.class.new( self.branchsets + other_object.branchsets )
		elsif other_object.respond_to?( :collection )
			return self.class.new( self.branchsets + [other_object] )
		else
			return self.all + Array( other_object )
		end
	end


	### Return the results from each of the receiver's Branchsets without the +other_object+,
	### which must respond to #dn.
	def -( other_object )
		other_dn = other_object.dn
		return self.reject {|branch| branch.dn == other_dn }
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


