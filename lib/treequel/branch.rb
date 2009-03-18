#!/usr/bin/env ruby

require 'forwardable'

require 'treequel' 
require 'treequel/mixins'
require 'treequel/constants'


# The object in Treequel that wraps an entry. It knows how to construct other branches 
# for the entries below itself, and how to search for those entries.
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
class Treequel::Branch
	include Treequel::Loggable,
	        Treequel::Constants


	# SVN Revision
	SVNRev = %q$Rev$

	# SVN Id
	SVNId = %q$Id$


	#################################################################
	###	C L A S S   M E T H O D S
	#################################################################

	### Create a new Treequel::Branch for the specified +dn+ starting from the
	### given +directory+.
	def self::new_from_dn( dn, directory )
		rdn = directory.rdn_to( dn )

		return rdn.split(/,/).reverse.inject( directory ) do |prev, pair|
			attribute, value = pair.split( /=/, 2 )
			Treequel.logger.debug "new_from_dn: fetching %s=%s from %p" % [ attribute, value, prev ]
			prev.send( attribute, value )
		end
	end
	
	
	### Create a new Treequel::Branch from the given +entry+ hash from the specified +directory+
	### and +parent+.
	def self::new_from_entry( entry, directory )
		dn = entry['dn']
		rdn, base = dn.first.split( /,/, 2 )
		attribute, value = rdn.split( /=/, 2 )
		
		return self.new( directory, attribute, value, base, entry )
	end
	

	#################################################################
	###	I N S T A N C E   M E T H O D S
	#################################################################

	### Create a new Treequel::Branch with the given +directory+, +attribute+, +value+, and
	### +base+. If the optional +entry+ object is given, it will be used to fetch values from
	### the directory; if it isn't provided, it will be fetched from the +directory+ the first
	### time it is needed.
	def initialize( directory, attribute, value, base, entry=nil )
		@directory = directory
		@attribute = attribute
		@value     = value
		@base      = base
		@entry     = entry
	end


	######
	public
	######

	# The directory the branch's entry lives in
	attr_reader :directory
	
	# The DN attribute of the branch
	attr_reader :attribute
	
	# The value of the DN attribute of the branch
	attr_reader :value
	
	# The DN of the base of the branch
	attr_reader :base


	### Return the LDAP::Entry associated with the receiver, fetching it from the
	### directory if necessary.
	def entry
		return @entry ||= self.directory.get_entry( self )
	end
	

	### Return the receiver's DN attribute and value as a attr=value String.
	def attr_pair
		return [ self.attribute, self.value ].join('=')
	end
	
	
	### Return the receiver's DN as a String.
	def dn
		return [ self.attr_pair, self.base ].join(',')
	end
	alias_method :to_s, :dn


	### Returns a human-readable representation of the object suitable for
	### debugging.
	def inspect
		return "#<%s:0x%0x %s @ %s %p>" % [
			self.class.name,
			self.object_id * 2,
			self.dn,
			self.directory,
			self.entry,
		  ]
	end


	#########
	protected
	#########

	### Proxy method: return a new Branch with the new +attribute+ and +value+ as
	### its base.
	def method_missing( attribute, value, *extra_args )
		raise ArgumentError,
			"wrong number of arguments (%d for 1)" % [ extra_args.length + 1 ] unless
			extra_args.empty?
		return self.class.new( self.directory, attribute, value, self )
	end
	
	
end # class Treequel::Branch


