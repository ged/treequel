#!/usr/bin/env ruby

require 'ldap'

require 'treequel' 
require 'treequel/branchset'


# This is a collection of classes used to represent a filter specification
# in a Treequel::BranchSet internally. They aren't intended to be used directly.
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
class Treequel::BranchSet

	# :stopdoc:

	### This is the abstract base class for filter clauses in a Treequel::BranchSet.
	class Clause
		private_class_method :new
		
		### Return the stringified clause -- this should be overridden by subclasses
		def to_s
			raise NotImplementedError, "%s doesn't implement #to_s" % [ self.class.name ]
		end
		
	end

	### Clauses which are formed when a user passes a literal String as a filter. It is assumed
	### to be a valid LDAP filter, and is just included as-is in any resulting filter.
	class LiteralClause < Clause
		
		### Create a new LiteralClause out of the specified +filterstring+.
		def initialize( filterstring )
			@string = filterstring
		end
		
		
		### Return the stringified clause
		def to_s
			if @string[0,1] == '('
				return "(#@string)"
			else
				return @string
			end
		end
		
	end
	
end # class Treequel::BranchSet


