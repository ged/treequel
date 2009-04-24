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
			LDAP_OID        = %r{ [[:digit:]]+ (?:\.[[:digit:]]+)* }x

			# AttributeType            = ldap-oid / (ALPHA *(attr-type-chars))
			LDAP_ATTRIBUTE_TYPE = %r{
				#{LDAP_OID}
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

			
		end # terminals
		
		# 
		# objectClass schema entry
		# 
		begin
			
			# a     = "a" / "b" / "c" / "d" / "e" / "f" / "g" / "h" / "i" /
			#         "j" / "k" / "l" / "m" / "n" / "o" / "p" / "q" / "r" /
			#         "s" / "t" / "u" / "v" / "w" / "x" / "y" / "z" / "A" /
			#         "B" / "C" / "D" / "E" / "F" / "G" / "H" / "I" / "J" /
			#         "K" / "L" / "M" / "N" / "O" / "P" / "Q" / "R" / "S" /
			#         "T" / "U" / "V" / "W" / "X" / "Y" / "Z"
            a = '[[:alpha:]]'

			# d               = "0" / "1" / "2" / "3" / "4" /
			#                   "5" / "6" / "7" / "8" / "9"
			d = '[[:digit:]]'
            
			# hex-digit       =  d / "a" / "b" / "c" / "d" / "e" / "f" /
			#                        "A" / "B" / "C" / "D" / "E" / "F"
			hexdigit = '[[:xdigit:]]'

			# k               = a / d / "-" / ";"
			k = '[[:alpha:][:digit:];\-]'

			# p               = a / d / """ / "(" / ")" / "+" / "," /
			#                   "-" / "." / "/" / ":" / "?" / " "
			p = '[[:alpha:][:digit:]"\(\)\+,\-\./:\? ]'

			# anhstring       = 1*k
            anhstring = /#{k}+/

			# keystring       = a [ anhstring ]
            keystring = /#{a}#{anhstring}/

			# printablestring = 1*p
            #
			# space           = 1*" "
            # 
			# whsp            = [ space ]
            # 
			# utf8            = <any sequence of octets formed from the UTF-8 [9]
			#                    transformation of a character from ISO10646 [10]>
            # 
			# dstring         = 1*utf8
            # 
			# qdstring        = whsp "'" dstring "'" whsp
            # 
			# qdstringlist    = [ qdstring *( qdstring ) ]
            # 
			# qdstrings       = qdstring / ( whsp "(" qdstringlist ")" whsp )

			# ObjectClassDescription = "(" whsp
			#     numericoid whsp      ; ObjectClass identifier
			#     [ "NAME" qdescrs ]
			#     [ "DESC" qdstring ]
			#     [ "OBSOLETE" whsp ]
			#     [ "SUP" oids ]       ; Superior ObjectClasses
			#     [ ( "ABSTRACT" / "STRUCTURAL" / "AUXILIARY" ) whsp ]
			#                          ; default structural
			#     [ "MUST" oids ]      ; AttributeTypes
			#     [ "MAY" oids ]       ; AttributeTypes
			# whsp ")"
			whsp = /[ ]+/
			
			# object descriptors used as schema element names
			#     qdescrs         = qdescr / ( whsp "(" qdescrlist ")" whsp )
			#     qdescrlist      = [ qdescr *( qdescr ) ]
			#     qdescr          = whsp "'" descr "'" whsp
			qdescr  = %r{ #{whsp} ' '}
			qdescrs = 
			
			
			LDAP_OBJECTCLASS_DESCRIPTION = %r{
				\( #{whsp}
					(#{LDAP_OID})
					#{whsp}
					(NAME )
				#{whsp} \)
			}x
			
		end # objectClass
	
	end # module Patterns

end # module Treequel::Constants

# vim: set nosta noet ts=4 sw=4:


