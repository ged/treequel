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

		# Schema-parsing patterns based on the BNF in 
		# RFC 4512 (http://tools.ietf.org/html/rfc4512#section-4.1.1)
		# 
		begin

			#	ALPHA   = %x41-5A / %x61-7A   ; "A"-"Z" / "a"-"z"
			ALPHA = '[:alpha:]'

			#	LDIGIT  = %x31-39             ; "1"-"9"
			LDIGIT = '1-9'

			#	DIGIT   = %x30 / LDIGIT       ; "0"-"9"
			DIGIT  = '[:digit:]'

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
			#	SQUOTE  = %x27 ; single quote ("'")
			#	LPAREN  = %x28 ; left paren ("(")
			#	RPAREN  = %x29 ; right paren (")")
			#	PLUS    = %x2B ; plus sign ("+")
			#	COMMA   = %x2C ; comma (",")
			#	HYPHEN  = %x2D ; hyphen ("-")
			#	DOT     = %x2E ; period (".")
			DOT = '\x2e'

			#	SEMI    = %x3B ; semicolon (";")
			#	LANGLE  = %x3C ; left angle bracket ("<")
			#	EQUALS  = %x3D ; equals sign ("=")
			#	RANGLE  = %x3E ; right angle bracket (">")
			#	ESC     = %x5C ; backslash ("\")
			#	USCORE  = %x5F ; underscore ("_")
			#	LCURLY  = %x7B ; left curly brace "{"
			#	RCURLY  = %x7D ; right curly brace "}"
			#	
			#	; Any UTF-8 [RFC3629] encoded Unicode [Unicode] character
			#	UTF8    = UTF1 / UTFMB
			#	UTFMB   = UTF2 / UTF3 / UTF4
			#	UTF0    = %x80-BF
			#	UTF1    = %x00-7F
			#	UTF2    = %xC2-DF UTF0
			#	UTF3    = %xE0 %xA0-BF UTF0 / %xE1-EC 2(UTF0) / %xED %x80-9F UTF0 / %xEE-EF 2(UTF0)
			#	UTF4    = %xF0 %x90-BF 2(UTF0) / %xF1-F3 3(UTF0) / %xF4 %x80-8F 2(UTF0)
			#	OCTET   = %x00-FF ; Any octet (8-bit data unit)
			# 
			#	leadkeychar = ALPHA
			leadkeychar = /[#{ALPHA}]/

			#	keychar = ALPHA / DIGIT / HYPHEN
			keychar = /[#{ALPHA}#{DIGIT}\-]/

			#	number  = DIGIT / ( LDIGIT 1*DIGIT )
			number = /[#{DIGIT}]|[#{LDIGIT}][#{DIGIT}]+/

			#	keystring = leadkeychar *keychar
			keystring = /#{leadkeychar}#{keychar}*/

			# Object identifiers (OIDs) [X.680] are represented in LDAP using a
			# dot-decimal format conforming to the ABNF:
			# 
			#	numericoid = number 1*( DOT number )
			numericoid = /#{number}( #{DOT} #{number} )+/x

			# 
			# Short names, also known as descriptors, are used as more readable
			# aliases for object identifiers.  Short names are case insensitive and
			# conform to the ABNF:
			# 
			#	descr = keystring
			# 
			# Where either an object identifier or a short name may be specified,
			# the following production is used:
			# 
			#    oid = descr / numericoid


		### -- ^^ new stuff / old stuff vv -- 

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



			# a				  = "a" / "b" / "c" / "d" / "e" / "f" / "g" / "h" / "i" /
			#					"j" / "k" / "l" / "m" / "n" / "o" / "p" / "q" / "r" /
			#					"s" / "t" / "u" / "v" / "w" / "x" / "y" / "z" / "A" /
			#					"B" / "C" / "D" / "E" / "F" / "G" / "H" / "I" / "J" /
			#					"K" / "L" / "M" / "N" / "O" / "P" / "Q" / "R" / "S" /
			#					"T" / "U" / "V" / "W" / "X" / "Y" / "Z"
			a = '[[:alpha:]]'

			# d				  = "0" / "1" / "2" / "3" / "4" /
			#					"5" / "6" / "7" / "8" / "9"
			d = '[[:digit:]]'

			# hex-digit		  =	 d / "a" / "b" / "c" / "d" / "e" / "f" /
			#						 "A" / "B" / "C" / "D" / "E" / "F"
			hexdigit = '[[:xdigit:]]'

			# k				  = a / d / "-" / ";"
			k = '[[:alpha:][:digit:];\-]'

			# p				  = a / d / """ / "(" / ")" / "+" / "," /
			#					"-" / "." / "/" / ":" / "?" / " "
			p = '[[:alpha:][:digit:]"\(\)\+,\-\./:\? ]'

		 	# letterstring    = 1*a
		 	letterstring = "#{a}+"

		 	# numericstring   = 1*d
			numericstring = "#{d}+"

			# anhstring		  = 1*k
			ANHSTRING = /#{k}+/

			# keystring		  = a [ anhstring ]
			KEYSTRING = /#{a}#{ANHSTRING}?/

			# space			  = 1*" "
			# whsp			  = [ space ]
			WHSP = /[ ]*/

			# descr           = keystring
			DESCR = KEYSTRING

			# numericoid      = numericstring *( "." numericstring )
			NUMERICOID = /#{numericstring} (?: \. #{numericstring} )*/x

			# oid             = descr / numericoid
			OID = /#{DESCR}|#{NUMERICOID}/

			# woid            = WHSP oid whsp
			WOID = /#{WHSP}#{OID}#{WHSP}/

			# oidlist         = woid *( "$" woid )
			OIDLIST = /#{WOID} (?:\$ #{WOID})*/x

			# ; set of oids of either form
			# oids            = woid / ( "(" oidlist ")" )
			OIDS = /#{WOID} | #{WHSP} \( #{OIDLIST} \) #{WHSP} /x

			# ; object descriptors used as schema element names
			# qdescr		  = whsp "'" descr "'" whsp
			QDESCR	= %r{ #{WHSP} ' #{DESCR} ' #{WHSP} }x

			# qdescrlist      = [ qdescr *( qdescr ) ]
			QDESCRLIST = /#{QDESCR}+/x

			# qdescrs         = qdescr / ( whsp "(" qdescrlist ")" whsp )
			QDESCRS = /#{QDESCR} | #{WHSP} \( #{QDESCRLIST} \) #{WHSP}/x

			# utf8			  = <any sequence of octets formed from the UTF-8 [9]
			#					 transformation of a character from ISO10646 [10]>
			# 
			# dstring		  = 1*utf8
			# 
			# qdstring		  = whsp "'" dstring "'" whsp
			# 
			# qdstringlist	  = [ qdstring *( qdstring ) ]
			# 
			# qdstrings		  = qdstring / ( whsp "(" qdstringlist ")" whsp )
			QDSTRING = /#{WHSP} ' (?:[^']+|\\')+ ' #{WHSP} /x
			QDSTRINGLIST = /#{QDSTRING}+/
			QDSTRINGS = /#{QDSTRING} | #{WHSP} \( #{QDSTRINGLIST} \) #{WHSP} /x

			# ObjectClassDescription = "(" whsp
			#	  numericoid whsp	   ; ObjectClass identifier
			#	  [ "NAME" qdescrs ]
			#	  [ "DESC" qdstring ]
			#	  [ "OBSOLETE" whsp ]
			#	  [ "SUP" oids ]	   ; Superior ObjectClasses
			#	  [ ( "ABSTRACT" / "STRUCTURAL" / "AUXILIARY" ) whsp ]
			#						   ; default structural
			#	  [ "MUST" oids ]	   ; AttributeTypes
			#	  [ "MAY" oids ]	   ; AttributeTypes
			# whsp ")"
			LDAP_OBJECTCLASS_DESCRIPTION = %r{
				\( #{WHSP}
					(#{NUMERICOID})				# $1
					#{WHSP}                 	
					(?:NAME (#{QDESCRS}))?		# $2
					#{WHSP}						# missing from the rfc's bnf, but necessary
					(?:DESC (#{QDSTRING}))? 	# $3
					#{WHSP}                 	
					(?:(OBSOLETE) )?			# $4
					#{WHSP}                 	
					(?:SUP (#{OIDS}))?			# $5
					(							# $6
						ABSTRACT
						|
						STRUCTURAL
						|
						AUXILIARY
					)?
					#{WHSP}
					(?:MUST (#{OIDS}))?			# $7
					(?:MAY (#{OIDS}))?			# $8
				#{WHSP} \)
			}ix
		end

	end # module Patterns

end # module Treequel::Constants

# vim: set nosta noet ts=4 sw=4:


