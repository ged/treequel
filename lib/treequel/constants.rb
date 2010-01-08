#!/usr/bin/ruby

require 'uri'
require 'ldap'
require 'treequel'


### A collection of constants that are shared across the library
module Treequel::Constants

	### Mapping of various symbolic names to LDAP integer LDAP_SCOPE_* values. Valid
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

	### Mapping of LDAP integer scope (LDAP_SCOPE_*) values to their names.
	SCOPE_NAME = {
		LDAP::LDAP_SCOPE_ONELEVEL => 'one',
		LDAP::LDAP_SCOPE_BASE     => 'base',
		LDAP::LDAP_SCOPE_SUBTREE  => 'subtree',
	}

	### Names and OIDs of various controls
	CONTROL_OIDS = {
		:sortrequest         => '1.2.840.113556.1.4.473',
		:sortresult          => '1.2.840.113556.1.4.474',
		:vlvrequest          => '2.16.840.1.113730.3.4.9',
		:vlvresponse         => '2.16.840.1.113730.3.4.10',
		:proxyauthentication => '2.16.840.1.113730.3.4.18',
		:paged               => '1.2.840.113556.1.4.319',
		:tree_delete         => '1.2.840.113556.1.4.805',
		:matchedvals         => '1.2.826.0.1.3344810.2.2',
		:matchedvalues       => '1.2.826.0.1.3344810.2.3',
		:managedsait         => '2.16.840.1.113730.3.4.2',
		:persistentsearch    => '2.16.840.1.113730.3.4.3',
		:entrychange         => '2.16.840.1.113730.3.4.7',
		:pwexpired           => '2.16.840.1.113730.3.4.4',
		:pwexpiring          => '2.16.840.1.113730.3.4.5',
		:referrals           => '1.2.840.113556.1.4.616',
		:passwordpolicy      => '1.3.6.1.4.1.42.2.27.8.5.1',
		:preread             => '1.3.6.1.1.13.1',
		:postread            => '1.3.6.1.1.13.2',
		:assertion           => '1.3.6.1.1.12',
		:sync                => '1.3.6.1.4.1.4203.1.9.1.1',
		:sync_state          => '1.3.6.1.4.1.4203.1.9.1.2',
		:sync_done           => '1.3.6.1.4.1.4203.1.9.1.3',
	}.freeze
	CONTROL_NAMES = CONTROL_OIDS.invert.freeze


	### OIDs of RFC values
	module OIDS

		# :stopdoc:

		### Object Classes (from RFC 4519)
		TOP_OBJECTCLASS = '2.5.6.0'

		### Syntaxes (from RFC 4517)
		RDN_SYNTAX                         = '1.2.36.79672281.1.5.0'
		RFC2307_NIS_NETGROUP_TRIPLE_SYNTAX = '1.3.6.1.1.1.0.0'
		RFC2307_BOOT_PARAMETER_SYNTAX      = '1.3.6.1.1.1.0.1'
		UUID_SYNTAX                        = '1.3.6.1.1.16.1'
		AUDIO_SYNTAX                       = '1.3.6.1.4.1.1466.115.121.1.4'
		BINARY_SYNTAX                      = '1.3.6.1.4.1.1466.115.121.1.5'
		BIT_STRING_SYNTAX                  = '1.3.6.1.4.1.1466.115.121.1.6'
		BOOLEAN_SYNTAX                     = '1.3.6.1.4.1.1466.115.121.1.7'
		CERTIFICATE_SYNTAX                 = '1.3.6.1.4.1.1466.115.121.1.8'
		CERTIFICATE_LIST_SYNTAX            = '1.3.6.1.4.1.1466.115.121.1.9'
		CERTIFICATE_PAIR_SYNTAX            = '1.3.6.1.4.1.1466.115.121.1.10'
		COUNTRY_STRING_SYNTAX              = '1.3.6.1.4.1.1466.115.121.1.11'
		DISTINGUISHED_NAME_SYNTAX          = '1.3.6.1.4.1.1466.115.121.1.12'
		DELIVERY_METHOD_SYNTAX             = '1.3.6.1.4.1.1466.115.121.1.14'
		DIRECTORY_STRING_SYNTAX            = '1.3.6.1.4.1.1466.115.121.1.15'
		STRING_SYNTAX                      = DIRECTORY_STRING_SYNTAX  # Alias
		FACSIMILE_TELEPHONE_NUMBER_SYNTAX  = '1.3.6.1.4.1.1466.115.121.1.22'
		GENERALIZED_TIME_SYNTAX            = '1.3.6.1.4.1.1466.115.121.1.24'
		IA5_STRING_SYNTAX                  = '1.3.6.1.4.1.1466.115.121.1.26'
		INTEGER_SYNTAX                     = '1.3.6.1.4.1.1466.115.121.1.27'
		JPEG_SYNTAX                        = '1.3.6.1.4.1.1466.115.121.1.28'
		NAME_AND_OPTIONAL_UID_SYNTAX       = '1.3.6.1.4.1.1466.115.121.1.34'
		NUMERIC_STRING_SYNTAX              = '1.3.6.1.4.1.1466.115.121.1.36'
		OID_SYNTAX                         = '1.3.6.1.4.1.1466.115.121.1.38'
		OTHER_MAILBOX_SYNTAX               = '1.3.6.1.4.1.1466.115.121.1.39'
		OCTET_STRING_SYNTAX                = '1.3.6.1.4.1.1466.115.121.1.40'
		POSTAL_ADDRESS_SYNTAX              = '1.3.6.1.4.1.1466.115.121.1.41'
		PRINTABLE_STRING_SYNTAX            = '1.3.6.1.4.1.1466.115.121.1.44'
		SUBTREESPECIFICATION_SYNTAX        = '1.3.6.1.4.1.1466.115.121.1.45'
		SUPPORTED_ALGORITHM_SYNTAX         = '1.3.6.1.4.1.1466.115.121.1.49'
		TELEPHONE_NUMBER_SYNTAX            = '1.3.6.1.4.1.1466.115.121.1.50'
		TELEX_NUMBER_SYNTAX                = '1.3.6.1.4.1.1466.115.121.1.52'
		UTC_TIME_SYNTAX                    = '1.3.6.1.4.1.1466.115.121.1.53'

		constants.each do |constname|
			const_get( constname ).freeze
		end
	end


	### A collection of Regexps to match various LDAP values
	module Patterns

		# Steal the URIREF regexp from the URI library. We have to look in
		# both places to support both 1.9.1 and 1.8.x.
		URI_REF = if URI::REGEXP.const_defined?( :PATTERN )
				/#{URI::REGEXP::PATTERN::URI_REF}/
			elsif URI::REGEXP.const_defined?( :URI_REF )
				/#{URI::REGEXP::URI_REF}/
			else
				raise "Couldn't find the URI_REF constant in the URI library!"
			end

		# :stopdoc:

		# Schema-parsing patterns based on the BNF in 
		# RFC 4512 (http://tools.ietf.org/html/rfc4512#section-4.1.1)

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
		NULL = '\x00'

		#	SPACE   = %x20 ; space (" ")
		SPACE = '\x20'

		#	DQUOTE  = %x22 ; quote (""")
		DQUOTE = '\x22'

		#	SHARP   = %x23 ; octothorpe (or sharp sign) ("#")
		SHARP = '\x23'

		#	DOLLAR  = %x24 ; dollar sign ("$")
		DOLLAR = '\x24'

		#	SQUOTE  = %x27 ; single quote ("'")
		SQUOTE = '\x27'

		#	LPAREN  = %x28 ; left paren ("(")
		#	RPAREN  = %x29 ; right paren (")")
		LPAREN = '\x28'
		RPAREN = '\x29'

		#	PLUS    = %x2B ; plus sign ("+")
		PLUS = '\x2b'

		#	COMMA   = %x2C ; comma (",")
		COMMA = '\x2c'

		#	HYPHEN  = %x2D ; hyphen ("-")
		HYPHEN = '\x2d'

		#	DOT     = %x2E ; period (".")
		DOT = '\x2e'

		#	SEMI    = %x3B ; semicolon (";")
		SEMI = '\x3b'

		#	LANGLE  = %x3C ; left angle bracket ("<")
		#	EQUALS  = %x3D ; equals sign ("=")
		#	RANGLE  = %x3E ; right angle bracket (">")
		LANGLE = '\x3c'
		EQUALS = '\x3d'
		RANGLE = '\x3e'

		#	ESC     = %x5C ; backslash ("\")
		ESC = '\x5c'

		#	USCORE  = %x5F ; underscore ("_")
		USCORE = '\x5f'

		#	LCURLY  = %x7B ; left curly brace "{"
		#	RCURLY  = %x7D ; right curly brace "}"
		LCURLY = '\x7b'
		RCURLY = '\x7d'

		# EXCLAMATION    = %x21 ; exclamation mark ("!")
		# AMPERSAND      = %x26 ; ampersand (or AND symbol) ("&")
		# ASTERISK       = %x2A ; asterisk ("*")
		# COLON          = %x3A ; colon (":")
		# VERTBAR        = %x7C ; vertical bar (or pipe) ("|")
		# TILDE          = %x7E ; tilde ("~")
		EXCLAMATION = '\x21'
		AMPERSAND = '\x26'
		ASTERISK = '\x2a'
		COLON = '\x3a'
		VERTBAR = '\x7c'
		TILDE = '\x7e'

		#	; Any UTF-8 [RFC3629] encoded Unicode [Unicode] character
		#	UTF0    = %x80-BF
		#	UTF1    = %x00-7F
		#	UTF2    = %xC2-DF UTF0
		UTF0 = /[\x80-\xbf]/
		UTF1 = /[\x00-\x7f]/
		UTF2 = /[\xc2-\xdf] #{UTF0}/x

		#	UTF3    = %xE0 %xA0-BF UTF0 / %xE1-EC 2(UTF0) / %xED %x80-9F UTF0 / %xEE-EF 2(UTF0)
		UTF3 = /
			\xe0 [\xa0-\xbf] #{UTF0}
			|
			[\xe1-\xec] #{UTF0}{2} 
			|
			\xed [\x80-\x9f] #{UTF0}
			|
			[\xee-\xef] #{UTF0}{2}
		/x

		#	UTF4    = %xF0 %x90-BF 2(UTF0) / %xF1-F3 3(UTF0) / %xF4 %x80-8F 2(UTF0)
		UTF4 = /
			\xf0 [\x90-\xbf] #{UTF0}{2}
			|
			[\xf1-\xf3] #{UTF0}{3}
			|
			\xf4 [\x80-\x8f] #{UTF0}{2}
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
		# 	numericoid                 ; object identifier
		# 	[ SP "NAME" SP qdescrs ]   ; short names (descriptors)
		# 	[ SP "DESC" SP qdstring ]  ; description
		# 	[ SP "OBSOLETE" ]          ; not active
		# 	SP "SYNTAX" SP numericoid  ; assertion syntax
		# 	extensions WSP RPAREN      ; extensions
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


		# Matching rule use descriptions are written according to the following
		# ABNF:
		# 
		#   MatchingRuleUseDescription = LPAREN WSP
		#       numericoid                 ; object identifier
		#       [ SP "NAME" SP qdescrs ]   ; short names (descriptors)
		#       [ SP "DESC" SP qdstring ]  ; description
		#       [ SP "OBSOLETE" ]          ; not active
		#       SP "APPLIES" SP oids       ; attribute types
		#       extensions WSP RPAREN      ; extensions
		LDAP_MATCHING_RULE_USE_DESCRIPTION = %r{
			#{LPAREN} #{WSP}
				(#{NUMERICOID})                        # $1  = oid
				(?:#{SP} NAME #{SP} (#{QDESCRS}) )?    # $2  = name
				(?:#{SP} DESC #{SP} (#{QDSTRING}) )?   # $3  = description
				(?:#{SP} (OBSOLETE) )?                 # $4  = obsolete flag
				#{SP} APPLIES #{SP} (#{OIDS})          # $5  = attribute types
				(#{EXTENSIONS})                        # $6 = extensions
			#{WSP} #{RPAREN}
		}x


		# LDAP syntax definitions are written according to the ABNF:
		# 
		#   SyntaxDescription = LPAREN WSP
		#       numericoid                 ; object identifier
		#       [ SP "DESC" SP qdstring ]  ; description
		#       extensions WSP RPAREN      ; extensions
		#   
		LDAP_SYNTAX_DESCRIPTION = %r{
			#{LPAREN} #{WSP}
				(#{NUMERICOID})                        # $1  = oid
				(?:#{SP} DESC #{SP} (#{QDSTRING}) )?   # $2  = description
				(#{EXTENSIONS})                        # $3 = extensions
			#{WSP} #{RPAREN}
		}x


		# UTF1SUBSET     = %x01-27 / %x2B-5B / %x5D-7F
		#                     ; UTF1SUBSET excludes 0x00 (NUL), LPAREN,
		#                     ; RPAREN, ASTERISK, and ESC.
		UTF1SUBSET = %r{
			[\x01-\x27\x2b-\x5b\x50-\x7f]
		}x

		# normal         = UTF1SUBSET / UTFMB
		NORMAL = %r{ #{UTF1SUBSET} | #{UTFMB} }x

		# escaped        = ESC HEX HEX
		ESCAPED = %r{ #{ESC} [[:xdigit:]]{2} }x

		# valueencoding  = 0*(normal / escaped)
		VALUEENCODING = %r{ (?:#{NORMAL} | #{ESCAPED})* }x

		# assertionvalue = valueencoding
		# ; The <valueencoding> rule is used to encode an <AssertionValue>
		# ; from Section 4.1.6 of [RFC4511].
		ASSERTIONVALUE = VALUEENCODING

		# The value part of a substring filter
		#   initial        = assertionvalue
		#   any            = ASTERISK *(assertionvalue ASTERISK)
		#   final          = assertionvalue
		LDAP_SUBSTRING_FILTER_VALUE = %r{
			#{ASSERTIONVALUE}
			#{ASTERISK} 
				(?: #{ASSERTIONVALUE} #{ASTERISK} )*
			#{ASSERTIONVALUE}
		}x

		# An AttributeDescription (same as LDAPString)
		#   attributedescription = attributetype options
		#        attributetype = oid
		#        options = *( SEMI option )
		#        option = 1*keychar
		LDAP_ATTRIBUTE_DESCRIPTION = %r{
			(#{OID})                          # $1: the OID
			(                                 # $2: attribute options
				(?:;#{KEYCHAR}+)*
			)
		}x

		# A substring filter, from RFC4511, section 4.5.1
		#     SubstringFilter ::= SEQUENCE {
		#         type           AttributeDescription,
		#         substrings     SEQUENCE SIZE (1..MAX) OF substring CHOICE {
		#              initial [0] AssertionValue,  -- can occur at most once
		#              any     [1] AssertionValue,
		#              final   [2] AssertionValue } -- can occur at most once
		#         }
		LDAP_SUBSTRING_FILTER = %r{
			(#{LDAP_ATTRIBUTE_DESCRIPTION})            # $1: AttributeDescription
			=
			(#{LDAP_SUBSTRING_FILTER_VALUE})           # $2: value
		}x


		# 
		# Distinguished Names (RFC4514)
		# 

		# hexpair = HEX HEX
		HEXPAIR = /#{HEX}{2}/

		# hexstring = SHARP 1*hexpair
		HEXSTRING = %r{ #{SHARP} #{HEXPAIR}+ }x

		# escaped = DQUOTE / PLUS / COMMA / SEMI / LANGLE / RANGLE
		DN_ESCAPED = %r{ #{DQUOTE} | #{PLUS} | #{COMMA} | #{SEMI} | #{LANGLE} | #{RANGLE} }x

		# special = escaped / SPACE / SHARP / EQUALS
		SPECIAL = %r{ #{DN_ESCAPED} | #{SPACE} | #{SHARP} | #{EQUALS} }x

		# pair = ESC ( ESC / special / hexpair )
		PAIR = %r{
			#{ESC}
			(?:
				#{ESC}
				| #{SPECIAL}
				| #{HEXPAIR}
			)
		}x

		# SUTF1 = %x01-21 / %x23-2A / %x2D-3A / %x3D / %x3F-5B / %x5D-7F
		SUTF1 = /[\x01-\x21\x23-\x2a\x2d-\x3a\x3d\x3f-\x5b\x5d-\x7f]/

		# stringchar = SUTF1 / UTFMB
		STRINGCHAR = %r{ #{SUTF1} | #{UTFMB} }x

		# TUTF1 = %x01-1F / %x21 / %x23-2A / %x2D-3A / %x3D / %x3F-5B / %x5D-7F
		TUTF1 = /[\x01-\x1f\x21\x23-\x2a\x2d-\x3a\x3d\x3f-\x5b\x5d-\x7f]/

		# trailchar  = TUTF1 / UTFMB
		TRAILCHAR = %r{ #{TUTF1} | #{UTFMB} }x

		# LUTF1 = %x01-1F / %x21 / %x24-2A / %x2D-3A / %x3D / %x3F-5B / %x5D-7F
		LUTF1 = /[\x01-\x1f\x21\x24-\x2a\x2d-\x3a\x3d\x3f-\x5b\x5d-\x7f]/

		# leadchar = LUTF1 / UTFMB
		LEADCHAR = %r{ #{LUTF1} | #{UTFMB} }x

		# ; The following characters are to be escaped when they appear
		# ; in the value to be encoded: ESC, one of <escaped>, leading
		# ; SHARP or SPACE, trailing SPACE, and NULL.
		# string =   [ ( leadchar / pair ) [ *( stringchar / pair )
		#    ( trailchar / pair ) ] ]
		# NOTE: the RFC specifies that all characters are optional in a STRING, which means that
		#       the RDN 'cn=' is valid. While I hesitate to deviate from the RFC, I can't currently
		#       conceive of a way such an RDN would be useful, so I'm defining this as requiring at
		#       least one character. If this becomes a problem later, we can just surround it
		#       with non-capturing parens with a optional qualifier.
		STRING = %r{
			(?:
				#{LEADCHAR}
				| #{PAIR}
			)
			(?:
				(?: #{STRINGCHAR} | #{PAIR} )*
				#{TRAILCHAR} | #{PAIR}
			)?
		}x

		# attributeValue = string / hexstring
		ATTRIBUTE_VALUE = %r{
			#{HEXSTRING}			# Since STRING can match the empty string, try HEXSTRING first
			| #{STRING}
		}x

		# attributeType = descr / numericoid
		ATTRIBUTE_TYPE = %r{
			#{DESCR}
			|
			#{NUMERICOID}
		}x

		# attributeTypeAndValue = attributeType EQUALS attributeValue
		ATTRIBUTE_TYPE_AND_VALUE = %r{
			#{ATTRIBUTE_TYPE} = #{ATTRIBUTE_VALUE}
		}x

		# relativeDistinguishedName = attributeTypeAndValue
		#     *( PLUS attributeTypeAndValue )
		RELATIVE_DISTINGUISHED_NAME = %r{
			#{ATTRIBUTE_TYPE_AND_VALUE}
			(?:
				\+
				#{ATTRIBUTE_TYPE_AND_VALUE}
			)*
		}x

		# distinguishedName = [ relativeDistinguishedName
		#     *( COMMA relativeDistinguishedName ) ]
		DISTINGUISHED_NAME = %r{
			#{RELATIVE_DISTINGUISHED_NAME}
			(?:
				,
				#{RELATIVE_DISTINGUISHED_NAME}
			)*
		}x


		# 
		# LDIF (RFC 2849)
		# 

		# attr-type-chars          = ALPHA / DIGIT / "-"
		# opt-char                 = attr-type-chars
		#   same as KEYCHAR
		LDIF_ATTR_TYPE_CHARS = KEYCHAR
		LDIF_OPT_CHAR = KEYCHAR

		# option                   = 1*opt-char
		LDIF_ATTRTYPE_OPTION = %r{ #{LDIF_OPT_CHAR}+ }x

		# options                  = option / (option ";" options)
		LDIF_ATTRTYPE_OPTIONS = %r{
			#{LDIF_ATTRTYPE_OPTION}
			(?: ; #{LDIF_ATTRTYPE_OPTION} )*
		}x

		# AttributeType            = ldap-oid / (ALPHA *(attr-type-chars))
		LDIF_ATTRIBUTE_TYPE = %r{
			#{NUMERICOID}
			|
			[#{ALPHA}] #{LDIF_ATTR_TYPE_CHARS}*
		}x

		# AttributeDescription     = AttributeType [";" options]
		#                            ; Definition taken from [4]
		LDIF_ATTRIBUTE_DESCRIPTION = %r{
			#{LDIF_ATTRIBUTE_TYPE}
			(?: ; #{LDIF_ATTRTYPE_OPTIONS} )?
		}x

		# SPACE                    = %x20  ; ASCII SP, space
		# FILL                     = *SPACE
		FILL = '\x20+'

		# SAFE-CHAR                = %x01-09 / %x0B-0C / %x0E-7F
		#                            ; any value <= 127 decimal except NUL, LF,
		#                            ; and CR
		LDIF_SAFE_CHAR = %r{[\x01-\x09\x0b-\x0c\x0e-\x7f]}

		# SAFE-INIT-CHAR           = %x01-09 / %x0B-0C / %x0E-1F /
		#                            %x21-39 / %x3B / %x3D-7F
		#                            ; any value <= 127 except NUL, LF, CR,
		#                            ; SPACE, colon (":", ASCII 58 decimal)
		#                            ; and less-than ("<" , ASCII 60 decimal)
		LDIF_SAFE_INIT_CHAR = %r{[\x01-\x09\x0B-\x0C\x0E-\x1F\x21-\x39\x3B\x3D-\x7F]}

		# SAFE-STRING              = [SAFE-INIT-CHAR *SAFE-CHAR]
		LDIF_SAFE_STRING = %r{
			#{LDIF_SAFE_INIT_CHAR}
			#{LDIF_SAFE_CHAR}*
		}x


		# BASE64-CHAR              = %x2B / %x2F / %x30-39 / %x3D / %x41-5A /
		#                            %x61-7A
		#                            ; +, /, 0-9, =, A-Z, and a-z
		#                            ; as specified in [5]
		BASE64_CHAR = %r{[\x2B\x2F\x30-\x39\x3D\x41-\x5A\x61-\x7A]}

		# BASE64-STRING            = [*(BASE64-CHAR)]
		BASE64_STRING = %r{ #{BASE64_CHAR}* }x

		# value-spec               = ":" (    FILL 0*1(SAFE-STRING) /
		#                                 ":" FILL (BASE64-STRING) /
		#                                 "<" FILL url)
		LDIF_VALUE_SPEC = %r{
			:
			(
				#{FILL} #{LDIF_SAFE_STRING}+
				|
				: #{FILL} #{BASE64_STRING}
				|
				< #{FILL} #{URI_REF}
			)
		}x

		# SEP                      = (CR LF / LF)
		SEP = %r{\r?\n}

		# attrval-spec             = AttributeDescription value-spec SEP
		LDIF_ATTRVAL_SPEC = %r{
			(#{LDIF_ATTRIBUTE_DESCRIPTION})
			#{LDIF_VALUE_SPEC}
			#{SEP}
		}xm

		# Freeze all the pattern constants so they don't get clobbered
		constants.each do |const|
			const_get( const ).freeze
		end

	end # module Patterns

end # module Treequel::Constants

# vim: set nosta noet ts=4 sw=4:


