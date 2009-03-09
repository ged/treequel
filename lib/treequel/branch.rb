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
	
	
	
end # class Treequel::Branch


