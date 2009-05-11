#!/usr/bin/env ruby

require 'ldap'
require 'ldap/schema'

require 'treequel' 


# This is an object that is used to parse and query a directory's schema
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
class Treequel::Schema
	include Treequel::Loggable,
	        Treequel::Constants::Patterns


end # class Treequel::Schema

