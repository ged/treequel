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


			# 		(#{NUMERICOID})				# $1
			# 		#{WHSP}                 	
			# 		(?:NAME (#{QDESCRS}))?		# $2
			# 		#{WHSP}						# missing from the rfc's bnf, but necessary
			# 		(?:DESC (#{QDSTRING}))? 	# $3
			# 		#{WHSP}                 	
			# 		(?:(OBSOLETE) )?			# $4
			# 		#{WHSP}                 	
			# 		(?:SUP (#{OIDS}))?			# $5
			# 		(							# $6
			# 			ABSTRACT
			# 			|
			# 			STRUCTURAL
			# 			|
			# 			AUXILIARY
			# 		)?
			# 		#{WHSP}
			# 		(?:MUST (#{OIDS}))?			# $7
			# }ix
			# %{
			# 		(?:MAY (#{OIDS}))?			# $8

	ObjectClass = Struct.new( 'ObjectClass', :oid, :name, :desc, :obsolete?, :sup, :type, :must, :may )

	### Parse the objectClass +description+ specified and return an equivalent 
	### Treequel::Schema::ObjectClass instance.
	def self::parse_objectclass( description )

	end


end # class Treequel::Filter

