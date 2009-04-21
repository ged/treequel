#!/usr/bin/ruby

require 'ldap'
require 'treequel'


### A collection of constants that are shared across the library
module Treequel::Constants # :nodoc:

	### Scope constants that map symbolic names to LDAP integer values. Valid
	### values are:
	###
	###   :onelevel, :one, :base, :subtree, :sub
	### 
	SCOPE = {
		:onelevel => LDAP::LDAP_SCOPE_ONELEVEL,
		:one      => LDAP::LDAP_SCOPE_ONELEVEL,
		:base     => LDAP::LDAP_SCOPE_BASE,
		:subtree  => LDAP::LDAP_SCOPE_SUBTREE,
		:sub      => LDAP::LDAP_SCOPE_SUBTREE,
	}.freeze
	

	### A collection of Regexps to match various LDAP values
	module Patterns

		# 
		# Terminals
		# 
		begin
			# attr-type-chars          = ALPHA / DIGIT / "-"
			attr_type_chars = %r{ [[:alpha:][:digit:]\-] }x

			# ldap-oid                 = 1*DIGIT 0*1("." 1*DIGIT)
			#                            ; An LDAPOID, as defined in [4]
			ldap_oid        = %r{ [[:digit:]]+ (?:\.[[:digit:]]+)* }x

			# AttributeType            = ldap-oid / (ALPHA *(attr-type-chars))
			LDAP_ATTRIBUTE_TYPE = %r{
				#{ldap_oid}
				|
				[[:alpha:]] #{attr_type_chars}*
			}x
			
			# opt-char                 = attr-type-chars
			opt_char = attr_type_chars
			
			# option                   = 1*opt-char
			option = %r{ #{opt_char}+ }x
			
            # 
			# AttributeDescription     = AttributeType [";" options]
			LDAP_ATTRIBUTE_DESCRIPTION = %r{
				(#{LDAP_ATTRIBUTE_TYPE})		# $1: attribute oid or name
				((?:
					;
					#{option}					# $2: attribute options
				)*)
			}x
			
			# If a value should contain any of the following characters
			# 
			#            Character       ASCII value
			#            ---------------------------
			#            *               0x2a
			#            (               0x28
			#            )               0x29
			#            \               0x5c
			#            NUL             0x00
			# 
			# the character must be encoded as the backslash '\' character (ASCII
			# 0x5c) followed by the two hexadecimal digits representing the ASCII
			# value of the encoded character. The case of the two hexadecimal
			# digits is not significant.
			LDAP_ATTRIBUTE_VALUE = %r{[^\*\(\)\\\0]+|\\(?i:[0-9a-z]{2})}
			
			
			# initial    = value
			initial = LDAP_ATTRIBUTE_VALUE

			# any        = "*" *(value "*")
			any = %r{
				\*
				(?:#{LDAP_ATTRIBUTE_VALUE}+\*)*
			}x

			# final      = value
			final = LDAP_ATTRIBUTE_VALUE

			# The value part of a substring filter
			LDAP_SUBSTRING_VALUE = %r{ #{initial}* #{any} #{final}* }x

			# substring  = attr "=" [initial] any [final]
			LDAP_SUBSTRING_FILTER = %r{
				(#{LDAP_ATTRIBUTE_DESCRIPTION})
				=
				(#{LDAP_SUBSTRING_VALUE})
			}x

			
		end
	
	end # module Patterns

end # module Treequel::Constants

# vim: set nosta noet ts=4 sw=4:


