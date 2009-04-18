#!/usr/bin/ruby

require 'ldap'
require 'treequel'


### A collection of constants that are shared across the library
module Treequel::Constants # :nodoc:

	### Scope constants that map symbolic names to LDAP integer values
	SCOPE = {
		:onelevel => LDAP::LDAP_SCOPE_ONELEVEL,
		:base     => LDAP::LDAP_SCOPE_BASE,
		:subtree  => LDAP::LDAP_SCOPE_SUBTREE,
	}.freeze
	

	module Patterns

		# 
		# Terminals
		# 
		begin
			# attr-type-chars          = ALPHA / DIGIT / "-"
			attr_type_chars = %r{ [[:alpha:][:digit:]\-] }x

			# ldap-oid                 = 1*DIGIT 0*1("." 1*DIGIT)
			#                            ; An LDAPOID, as defined in [4]
			ldap_oid        = %r{ [[:digit:]]+ (\.[[:digit:]]+)* }x

			# AttributeType            = ldap-oid / (ALPHA *(attr-type-chars))
			LDAP_ATTRIBUTE_TYPE = %r{
				#{ldap_oid}
				|
				[[:alpha:]] #{attr_type_chars}
			}x
			
			# opt-char                 = attr-type-chars
			opt_char = attr_type_chars
			
			# option                   = 1*opt-char
			option = %r{ #{opt_char}+ }x
			
			# options                  = option / (option ";" options)
			options = %r{
				#{option}(;#{option})*
			}x
			
            # 
			# AttributeDescription     = AttributeType [";" options]
			LDAP_ATTRIBUTE_DESCRIPTION = %r{
				(#{LDAP_ATTRIBUTE_TYPE})		# $1: attribute oid or name
				(?:
					;
					(#{options})				# $2: attribute options
				)
			}
			
			# An LDAP attribute value
			LDAP_ATTRIBUTE_VALUE = %r{.+?}
		end
	
	end # module Patterns

end # module Treequel::Constants

# vim: set nosta noet ts=4 sw=4:


