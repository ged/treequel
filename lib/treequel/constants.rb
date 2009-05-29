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

		begin

			# attr-type-chars		   = ALPHA / DIGIT / "-"
			attr_type_chars = %r{ [[:alpha:][:digit:]\-] }x

			# ldap-oid				   = 1*DIGIT 0*1("." 1*DIGIT)
			#							 ; An LDAPOID, as defined in [4]
			LDAP_OID		= %r{ [[:digit:]]+ (?:\.[[:digit:]]+)* }x

			# AttributeType			   = ldap-oid / (ALPHA *(attr-type-chars))
			LDAP_ATTRIBUTE_TYPE = %r{
				#{LDAP_OID}
				|
				[[:alpha:]] #{attr_type_chars}*
			}x

			# opt-char				   = attr-type-chars
			opt_char = attr_type_chars

			# option				   = 1*opt-char
			option = %r{ #{opt_char}+ }x

			#
			# AttributeDescription	   = AttributeType [";" options]
			LDAP_ATTRIBUTE_DESCRIPTION = %r{
				(#{LDAP_ATTRIBUTE_TYPE})		# $1: attribute oid or name
				((?:
					;
					#{option}					# $2: attribute options
				)*)
			}x

			# If a value should contain any of the following characters
			#
			#			 Character		 ASCII value
			#			 ---------------------------
			#			 *				 0x2a
			#			 (				 0x28
			#			 )				 0x29
			#			 \				 0x5c
			#			 NUL			 0x00
			#
			# the character must be encoded as the backslash '\' character (ASCII
			# 0x5c) followed by the two hexadecimal digits representing the ASCII
			# value of the encoded character. The case of the two hexadecimal
			# digits is not significant.
			LDAP_ATTRIBUTE_VALUE = %r{[^\*\(\)\\\0]+|\\(?i:[0-9a-z]{2})}


			# initial	 = value
			initial = LDAP_ATTRIBUTE_VALUE

			# any		 = "*" *(value "*")
			any = %r{
				\*
				(?:#{LDAP_ATTRIBUTE_VALUE}+\*)*
			}x

			# final		 = value
			final = LDAP_ATTRIBUTE_VALUE

			# The value part of a substring filter
			LDAP_SUBSTRING_VALUE = %r{ #{initial}* #{any} #{final}* }x

			# substring	 = attr "=" [initial] any [final]
			LDAP_SUBSTRING_FILTER = %r{
				(#{LDAP_ATTRIBUTE_DESCRIPTION})
				=
				(#{LDAP_SUBSTRING_VALUE})
			}x


		end

		# Schema-parsing patterns based on the BNF in 
		# RFC 4512 (http://tools.ietf.org/html/rfc4512#section-4.1.1)

		begin

			#	ALPHA   = %x41-5A / %x61-7A   ; "A"-"Z" / "a"-"z"
			ALPHA = '[:alpha:]'

			#	LDIGIT  = %x31-39             ; "1"-"9"
			LDIGIT = '1-9'

			#	DIGIT   = %x30 / LDIGIT       ; "0"-"9"
			DIGIT  = '\d'

			#	HEX     = DIGIT / %x41-46 / %x61-66 ; "0"-"9" / "A"-"F" / "a"-"f"
			HEX = '[:xdigit:]'

			#	
			#	SP      = 1*SPACE  ; one or more " "
			#	WSP     = 0*SPACE  ; zero or more " "
			SP = '[ ]+'
			WSP = '[ ]*'

			### These are inlined for simplicity
			#	NULL    = %x00 ; null (0)
			#	SPACE   = %x20 ; space (" ")
			#	DQUOTE  = %x22 ; quote (""")
			#	SHARP   = %x23 ; octothorpe (or sharp sign) ("#")
			#	DOLLAR  = %x24 ; dollar sign ("$")
			DOLLAR = '\x24'

			#	SQUOTE  = %x27 ; single quote ("'")
			SQUOTE = '\x27'

			#	LPAREN  = %x28 ; left paren ("(")
			#	RPAREN  = %x29 ; right paren (")")
			LPAREN = '\x28'
			RPAREN = '\x29'

			#	PLUS    = %x2B ; plus sign ("+")
			#	COMMA   = %x2C ; comma (",")
			#	HYPHEN  = %x2D ; hyphen ("-")
			HYPHEN = '\x2d'

			#	DOT     = %x2E ; period (".")
			DOT = '\x2e'

			#	SEMI    = %x3B ; semicolon (";")
			#	LANGLE  = %x3C ; left angle bracket ("<")
			#	EQUALS  = %x3D ; equals sign ("=")
			#	RANGLE  = %x3E ; right angle bracket (">")
			#	ESC     = %x5C ; backslash ("\")
			ESC = '\x5c'

			#	USCORE  = %x5F ; underscore ("_")
			USCORE = '\x5f'

			#	LCURLY  = %x7B ; left curly brace "{"
			#	RCURLY  = %x7D ; right curly brace "}"
			LCURLY = '\x7b'
			RCURLY = '\x7d'

			#	; Any UTF-8 [RFC3629] encoded Unicode [Unicode] character
			#	UTF0    = %x80-BF
			#	UTF1    = %x00-7F
			#	UTF2    = %xC2-DF UTF0
			UTF0 = '\x80-\xbf'
			UTF1 = '\x00-\x7f'
			UTF2 = '\xc2-\xdf' + UTF0

			#	UTF3    = %xE0 %xA0-BF UTF0 / %xE1-EC 2(UTF0) / %xED %x80-9F UTF0 / %xEE-EF 2(UTF0)
			UTF3 = /
				\xe0 [\xa0-\xbf] [#{UTF0}]
				|
				[\xe1-\xec] [#{UTF0}]{2} 
				|
				\xed [\x80-\x9f] [#{UTF0}]
				|
				[\xee-\xef] [#{UTF0}]{2}
			/x

			#	UTF4    = %xF0 %x90-BF 2(UTF0) / %xF1-F3 3(UTF0) / %xF4 %x80-8F 2(UTF0)
			UTF4 = /
				\xf0 [\x90-\xbf] [#{UTF0}]{2}
				|
				[\xf1-\xf3] [#{UTF0}]{3}
				|
				\xf4 [\x80-\x8f] [#{UTF0}]{2}
			/x

			#	UTFMB   = UTF2 / UTF3 / UTF4
			UTFMB = Regexp.union( UTF2, UTF3, UTF4 )

			#	UTF8    = UTF1 / UTFMB
			UTF8 = Regexp.union( UTF1, UTFMB )

			#	OCTET   = %x00-FF ; Any octet (8-bit data unit)
			OCTET = '.'

			#	leadkeychar = ALPHA
			LEADKEYCHAR = /[#{ALPHA}]/

			#	keychar = ALPHA / DIGIT / HYPHEN
			KEYCHAR = /[#{ALPHA}#{DIGIT}\-]/

			#	number  = DIGIT / ( LDIGIT 1*DIGIT )
			NUMBER = /[#{LDIGIT}]#{DIGIT}+|#{DIGIT}/ # Reversed for greediness

			#	keystring = leadkeychar *keychar
			KEYSTRING = /#{LEADKEYCHAR}#{KEYCHAR}*/

			# Object identifiers (OIDs) [X.680] are represented in LDAP using a
			# dot-decimal format conforming to the ABNF:

			#	numericoid = number 1*( DOT number )
			NUMERICOID = /#{NUMBER}(?: #{DOT} #{NUMBER} )+/x


			# Short names, also known as ¨iptors, are used as more readable
			# aliases for object identifiers.  Short names are case insensitive and
			# conform to the ABNF:

			#	descr = keystring
			DESCR = KEYSTRING

			# Where either an object identifier or a short name may be specified,
			# the following production is used:

			#    oid = descr / numericoid
			OID = / #{DESCR} | #{NUMERICOID} /x


			# len = number
			LEN = NUMBER

			# noidlen = numericoid [ LCURLY len RCURLY ]
			NOIDLEN = /#{NUMERICOID} (?:#{LCURLY} #{LEN} #{RCURLY})?/x

			# oidlist = oid *( WSP DOLLAR WSP oid )
			OIDLIST = /#{OID} (?: #{WSP} #{DOLLAR} #{WSP} #{OID} )*/x

			# oids = oid / ( LPAREN WSP oidlist WSP RPAREN )
			OIDS = / #{OID} | #{LPAREN} #{WSP} #{OIDLIST} #{WSP} #{RPAREN} /x

			# xstring = "X" HYPHEN 1*( ALPHA / HYPHEN / USCORE )
			XSTRING = / X #{HYPHEN} [#{ALPHA}#{HYPHEN}#{USCORE}]+ /x

			# qdescr = SQUOTE descr SQUOTE
			# qdescrlist = [ qdescr *( SP qdescr ) ]
			# qdescrs = qdescr / ( LPAREN WSP qdescrlist WSP RPAREN )
			QDESCR = / #{SQUOTE} #{DESCR} #{SQUOTE} /x
			QDESCRLIST = /(?: #{QDESCR} (?: #{SP} #{QDESCR} )* )?/x
			QDESCRS = / #{QDESCR} | #{LPAREN} #{WSP} #{QDESCRLIST} #{WSP} #{RPAREN} /x

			# ; Any ASCII character except %x27 ("\'") and %x5C ("\")
			# QUTF1    = %x00-26 / %x28-5B / %x5D-7F
			QUTF1 = /[\x00-\x26\x28-\x5b\x5d-\x7f]/

			# ; Any UTF-8 encoded Unicode character
			# ; except %x27 ("\'") and %x5C ("\")
			# QUTF8    = QUTF1 / UTFMB
			QUTF8 = Regexp.union( QUTF1, UTFMB )

			# QQ =  ESC %x32 %x37 ; "\27"
			# QS =  ESC %x35 ( %x43 / %x63 ) ; "\5C" / "\5c"
			QQ = / #{ESC} 27 /x
			QS = / #{ESC} 5c /xi


			### NOTE: QDSTRING is zero-or-more despite the RFC's specifying it as 1 or more 
			### to support empty DESC attributes in the wild (e.g., the ones in the 
			### attributeTypes from the 'retcode' overlay in OpenLDAP)

			# dstring = 1*( QS / QQ / QUTF8 )   ; escaped UTF-8 string
			# qdstring = SQUOTE dstring SQUOTE
			# qdstringlist = [ qdstring *( SP qdstring ) ]
			# qdstrings = qdstring / ( LPAREN WSP qdstringlist WSP RPAREN )
			DSTRING = / (?: #{QS} | #{QQ} | #{QUTF8} )* /x
			QDSTRING = / #{SQUOTE} #{DSTRING} #{SQUOTE} /x
			QDSTRINGLIST = /(?: #{QDSTRING} (?: #{SP} #{QDSTRING} )* )?/x
			QDSTRINGS = / #{QDSTRING} | #{LPAREN} #{WSP} #{QDSTRINGLIST} #{WSP} #{RPAREN} /x

			# extensions = *( SP xstring SP qdstrings )
			EXTENSIONS = /(?: #{SP} #{XSTRING} #{SP} #{QDSTRINGS} )*/x

			#   kind = "ABSTRACT" / "STRUCTURAL" / "AUXILIARY"
			KIND = Regexp.union( 'ABSTRACT', 'STRUCTURAL', 'AUXILIARY' )

			# Object Class definitions are written according to the ABNF:

			#   ObjectClassDescription = LPAREN WSP
			#       numericoid                 ; object identifier
			#       [ SP "NAME" SP qdescrs ]   ; short names (descriptors)
			#       [ SP "DESC" SP qdstring ]  ; description
			#       [ SP "OBSOLETE" ]          ; not active
			#       [ SP "SUP" SP oids ]       ; superior object classes
			#       [ SP kind ]                ; kind of class
			#       [ SP "MUST" SP oids ]      ; attribute types
			#       [ SP "MAY" SP oids ]       ; attribute types
			#       extensions WSP RPAREN

			LDAP_OBJECTCLASS_DESCRIPTION = %r{
				#{LPAREN} #{WSP}
					(#{NUMERICOID})                         # $1 = oid
					(?:#{SP} NAME #{SP} (#{QDESCRS}) )?     # $2 = name
					(?:#{SP} DESC #{SP} (#{QDSTRING}))?     # $3 = desc
					(?:#{SP} (OBSOLETE) )?                  # $4 = obsolete
					(?:#{SP} SUP #{SP} (#{OIDS}) )?         # $5 = sup
					(?:#{SP} (#{KIND}) )?                   # $6 = kind
					(?:#{SP} MUST #{SP} (#{OIDS}) )?        # $7 = must attrs
					(?:#{SP} MAY #{SP} (#{OIDS}) )?         # $8 = may attrs
					(#{EXTENSIONS})                         # $9 = extensions
				#{WSP} #{RPAREN}
			}x


			# usage = "userApplications"     /  ; user
			#         "directoryOperation"   /  ; directory operational
			#         "distributedOperation" /  ; DSA-shared operational
			#         "dSAOperation"            ; DSA-specific operational
			USAGE = Regexp.union(
				'userApplications',
				'directoryOperation',
				'distributedOperation',
				'dSAOperation'
			  )

			# Attribute Type definitions are written according to the ABNF:
			#
			#   AttributeTypeDescription = LPAREN WSP
			#            numericoid                    ; object identifier
			#            [ SP "NAME" SP qdescrs ]      ; short names (descriptors)
			#            [ SP "DESC" SP qdstring ]     ; description
			#            [ SP "OBSOLETE" ]             ; not active
			#            [ SP "SUP" SP oid ]           ; supertype
			#            [ SP "EQUALITY" SP oid ]      ; equality matching rule
			#            [ SP "ORDERING" SP oid ]      ; ordering matching rule
			#            [ SP "SUBSTR" SP oid ]        ; substrings matching rule
			#            [ SP "SYNTAX" SP noidlen ]    ; value syntax
			#            [ SP "SINGLE-VALUE" ]         ; single-value
			#            [ SP "COLLECTIVE" ]           ; collective
			#            [ SP "NO-USER-MODIFICATION" ] ; not user modifiable
			#            [ SP "USAGE" SP usage ]       ; usage
			#            extensions WSP RPAREN         ; extensions
			LDAP_ATTRIBUTE_TYPE_DESCRIPTION = %r{
				#{LPAREN} #{WSP}
					(#{NUMERICOID})                         # $1  = oid
					(?:#{SP} NAME #{SP} (#{QDESCRS}) )?     # $2  = name
					(?:#{SP} DESC #{SP} (#{QDSTRING}) )?    # $3  = description
					(?:#{SP} (OBSOLETE) )?                  # $4  = obsolete flag
					(?:#{SP} SUP #{SP} (#{OID}) )?          # $5  = superior type oid
					(?:#{SP} EQUALITY #{SP} (#{OID}) )?     # $6  = equality matching rule oid
					(?:#{SP} ORDERING #{SP} (#{OID}) )?     # $7  = ordering matching rule oid
					(?:#{SP} SUBSTR #{SP} (#{OID}) )?       # $8  = substring matching rule oid
					(?:#{SP} SYNTAX #{SP} (#{NOIDLEN}) )?   # $9  = value syntax matching oid
					(?:#{SP} (SINGLE-VALUE) )?              # $10 = single value flag
					(?:#{SP} (COLLECTIVE) )?                # $11 = collective flag
					(?:#{SP} (NO-USER-MODIFICATION) )?      # $12 = no user modification flag
					(?:#{SP} USAGE #{SP} (#{USAGE}) )?      # $13 = usage type
					(#{EXTENSIONS})                         # $14 = extensions
				#{WSP} #{RPAREN}
			}x


			# MatchingRuleDescription = LPAREN WSP
			# 	         numericoid                 ; object identifier
			# 	         [ SP "NAME" SP qdescrs ]   ; short names (descriptors)
			# 	         [ SP "DESC" SP qdstring ]  ; description
			# 	         [ SP "OBSOLETE" ]          ; not active
			# 	         SP "SYNTAX" SP numericoid  ; assertion syntax
			# 	         extensions WSP RPAREN      ; extensions
			LDAP_MATCHING_RULE_DESCRIPTION = %r{
				#{LPAREN} #{WSP}
					(#{NUMERICOID})                        # $1  = oid
					(?:#{SP} NAME #{SP} (#{QDESCRS}) )?    # $2  = name
					(?:#{SP} DESC #{SP} (#{QDSTRING}) )?   # $3  = description
					(?:#{SP} (OBSOLETE) )?                 # $4  = obsolete flag
					#{SP} SYNTAX #{SP} (#{NUMERICOID})     # $5  = syntax numeric OID
					(#{EXTENSIONS})                        # $6 = extensions
				#{WSP} #{RPAREN}
			}x


		end

	end # module Patterns

end # module Treequel::Constants

# vim: set nosta noet ts=4 sw=4:


