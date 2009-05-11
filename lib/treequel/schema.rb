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

	# (#{NUMERICOID})                           # $1 = oid
	# (?:#{SP} NAME #{SP} (#{QDESCRS}) )?       # $2 = name
	# (?:#{SP} DESC #{SP} (#{QDSTRING}))?       # $3 = desc
	# (?:#{SP} (OBSOLETE) )?                    # $4 = obsolete
	# (?:#{SP} SUP #{SP} (#{OIDS}) )?           # $5 = sup
	# (?:#{SP} (#{KIND}) )?                     # $6 = kind
	# (?:#{SP} MUST #{SP} (#{OIDS}) )?          # $7 = must attrs
	# (?:#{SP} MAY #{SP} (#{OIDS}) )?           # $8 = may attrs
	# (#{EXTENSIONS})                           # $9 = extensions
	ObjectClass = Struct.new( 'ObjectClass', :oid, :name, :desc, :obsolete?, :sup, :type, :must, :may, :extensions )

	### Parse the objectClass +description+ specified and return an equivalent 
	### Treequel::Schema::ObjectClass instance.
	def self::parse_objectclass( description )

	end


end # class Treequel::Filter

