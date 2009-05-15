#!/usr/bin/env ruby

require 'ldap'
require 'ldap/schema'

require 'treequel'
require 'treequel/constants'
require 'treequel/mixins'


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

	require 'treequel/schema/objectclass'
	require 'treequel/schema/attributetype'

	#################################################################
	###	C L A S S   M E T H O D S
	#################################################################

	### Parse the given +oidstring+ into an Array of OIDs, with Strings for numeric OIDs and
	### Symbols for aliases.
	def self::parse_oids( oidstring )
		return [] unless oidstring

		unless match = OIDLIST.match( oidstring )
			raise Treequel::ParseError, "couldn't find an OIDLIST in %p" % [ oidstring ]
		end

		parse_oid = self.method( :parse_oid )
		return $MATCH.split( /#{WSP} #{DOLLAR} #{WSP}/x ).collect( &parse_oid )
	end


	### Parse a single OID into either a numeric OID string or a Symbol.
	def self::parse_oid( oidstring )
		if oidstring =~ NUMERICOID
			return oid
		else
			return oidstring.to_sym
		end
	end


	### Parse the given short +names+ string (a 'qdescrs' in the BNF) into an Array of zero or
	### more Strings.
	def self::parse_names( names )

		# Unspecified
		if names.nil?
			return []

		# Multi-value
		elsif names =~ /#{LPAREN} #{WSP} (#{QDESCRLIST}) #{WSP} #{RPAREN}/x
			return $1.scan( QDESCR ).collect {|qd| qd[1..-2].to_sym }

		# Single-value
		else
			# Return the name without the quotes
			return [ names[1..-2].to_sym ]
		end
	end


	### Return a new string which is +desc+ with quotes stripped and any escaped characters 
	### un-escaped.
	def self::unquote_desc( desc )
		return nil if desc.nil?
		return desc.gsub( QQ, "'" ).gsub( QS, '\\' )[ 1..-2 ]
	end


	#################################################################
	###	I N S T A N C E   M E T H O D S
	#################################################################

	### Create a new Treequel::Schema from the specified +hash+. The +hash+ should be of the same
	### form as the one returned by LDAP::Conn.schema, i.e., a Hash of Arrays associated with the
	### keys "objectClasses", "ldapSyntaxes", "matchingRuleUse", "attributeTypes", and 
	### "matchingRules".
	def initialize( hash )
		@object_classes    = self.parse_objectclasses( hash['objectClasses'] )
		@attribute_types   = self.parse_attribute_types( hash['attributeTypes'] )
		@ldap_syntaxes     = self.parse_ldap_syntaxes( hash['ldapSyntaxes'] )
		@matching_rules    = self.parse_matching_rules( hash['matchingRules'] )
		@matching_rule_use = self.parse_matching_rule_use( hash['matchingRuleUse'] )
	end


	######
	public
	######

	# The Hash of Treequel::Schema::ObjectClass objects, keyed by OID and any associated NAME 
	# attributes (as Symbols), that describes the objectClasses in the directory's schema.
	attr_reader :object_classes

	# The hash of Treequel::Schema::AttributeType objects, keyed by OID and any associated NAME
	# attributes (as Symbols), that describe the attributeTypes in the directory's schema.
	attr_reader :attribute_types

	attr_reader :ldap_syntaxes
	attr_reader :matching_rules
	attr_reader :matching_rule_use


	#########
	protected
	#########

	### Parse the given objectClass +descriptions+ into Treequel::Schema::ObjectClass objects, and
	### return them as a Hash keyed both by numeric OID and by each of its NAME attributes (if it
	### has any).
	def parse_objectclasses( descriptions )
		return descriptions.inject( {} ) do |hash, desc|
			oc = Treequel::Schema::ObjectClass.parse( self, desc ) or
				raise Treequel::Error, "couldn't create an objectClass from %p" % [ desc ]

			hash[ oc.oid ] = oc
			oc.names.inject( hash ) {|h, name| h[name] = oc; h }

			hash
		end
	end


	### Parse the given attributeType +descriptions+ into Treequel::Schema::AttributeType objects
	### and return them as a Hash keyed both by numeric OID and by each of its NAME attributes 
	### (if it has any).
	def parse_attribute_types( descriptions )
		return descriptions.inject( {} ) do |hash, desc|
			attrtype = Treequel::Schema::AttributeType.parse( self, desc ) or
				raise Treequel::Error, "couldn't create an attributeType from %p" % [ desc ]

			hash[ attrtype.oid ] = attrtype
			attrtype.names.inject( hash ) {|h, name| h[name] = attrtype; h }

			hash
		end
	end


	def parse_ldap_syntaxes( descriptions )
		{}
	end


	def parse_matching_rules( descriptions )
		{}
	end


	def parse_matching_rule_use( descriptions )
		{}
	end


end # class Treequel::Schema

