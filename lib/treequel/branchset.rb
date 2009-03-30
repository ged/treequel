#!/usr/bin/env ruby

require 'forwardable'

require 'treequel' 
require 'treequel/mixins'
require 'treequel/constants'
require 'treequel/branch'


# The object in Treequel that wraps a set of Treequel::Branches
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

	
end # class Treequel::Branch


