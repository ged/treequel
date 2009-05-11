#!/usr/bin/env ruby

require 'treequel'
require 'treequel/schema'


# This is a collection of classes for representing objectClasses in a Treequel::Schema.
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

	# The types of objectClass as specified in the schema, along with which Ruby class
	# corresponds to it. Each class registers itself as it's defined.
	OBJECTCLASS_TYPES = {}


	### objectClass entries in a Treequel::Schema.
	class ObjectClass
		include Treequel::Loggable,
		        Treequel::Constants::Patterns

		private_class_method :new

		### Inheritance callback: Make the constructor method of all inheriting classes
		### public.
		def self::inherited( subclass )
			subclass.instance_eval { public_class_method :new }
		end


		### Parse the given +oidstring+ into an Array of OIDs, with Strings for numeric OIDs and
		### Symbols for aliases.
		def self::parse_oids( oidstring )
			return [] unless oidstring
			return oidstring.split( /#{WSP} #{DOLLAR} #{WSP}/x ).collect do |oid|
				if oid =~ NUMERICOID
					oid
				else
					oid.to_sym
				end
			end
		end


		### Parse an ObjectClass entry from a objectClass description from a schema.
		def self::parse( description )
			unless match = ( LDAP_OBJECTCLASS_DESCRIPTION.match(description) )
				raise Treequel::ParseError, "failed to parse objectClass from %p" % [ description ]
			end

			oid, name, desc, obsolete, sup, kind, must, may, extensions = match.captures
			mustoids = self.parse_oids( must )
			mayoids = self.parse_oids( may )

			# Find the appropriate concrete class to instantiate 
			concrete_class = Treequel::Schema::OBJECTCLASS_TYPES[ kind ] or
				raise Treequel::Exception, "no such objectClass type %p: expected one of: %p" %
					[ kind, Treequel::Schema::OBJECTCLASS_TYPES.keys ]

			return concrete_class.new( oid, name, desc, obsolete, sup, mustoids, mayoids, extensions )
		end


		### Create a new ObjectClass 
		def initialize( oid, name=nil, desc=nil, obsolete=false, sup=nil, mustoids=[], mayoids=[], extensions=nil )
			@oid        = oid
			@name       = name
			@desc       = desc
			@obsolete   = obsolete
			@sup        = sup
			@must       = mustoids
			@may        = mayoids
			@extensions = extensions

			super()
		end


		######
		public
		######

		# The objectClass's oid
		attr_reader :oid

		# The objectClass's name
		attr_accessor :name

		# The objectClass's description
		attr_accessor :desc

		# The objectClass's superior class
		attr_accessor :sup

		# The objectClass's MUST OIDs
		attr_reader :must

		# The objectClass's MAY OIDs
		attr_reader :may

	end # class ObjectClass


	### An LDAP objectClass of type 'ABSTRACT'. From RFC 4512:
	### 
	###   An abstract object class, as the name implies, provides a base of
	###   characteristics from which other object classes can be defined to
	###   inherit from.  An entry cannot belong to an abstract object class
	###   unless it belongs to a structural or auxiliary class that inherits
	###   from that abstract class.
    ###
	###   Abstract object classes cannot derive from structural or auxiliary
	###   object classes.
    ###
	###   All structural object classes derive (directly or indirectly) from
	###   the 'top' abstract object class.  Auxiliary object classes do not
	###   necessarily derive from 'top'.
	###
	class AbstractObjectClass < Treequel::Schema::ObjectClass
		Treequel::Schema::OBJECTCLASS_TYPES[ 'ABSTRACT' ] = self

	end # class AbstractObjectClass


	### An LDAP objectClass of type 'AUXILIARY'. From FC4512:
	### 
	###   Auxiliary object classes are used to augment the characteristics of
	###   entries.  They are commonly used to augment the sets of attributes
	###   required and allowed to be present in an entry.  They can be used to
	###   describe entries or classes of entries.
    ###
	###   Auxiliary object classes cannot subclass structural object classes.
    ###
	###   An entry can belong to any subset of the set of auxiliary object
	###   classes allowed by the DIT content rule associated with the
	###   structural object class of the entry.  If no DIT content rule is
	###   associated with the structural object class of the entry, the entry
	###   cannot belong to any auxiliary object class.
    ###
	###   The set of auxiliary object classes that an entry belongs to can
	###   change over time.
	class AuxiliaryObjectClass < Treequel::Schema::ObjectClass
		Treequel::Schema::OBJECTCLASS_TYPES[ 'AUXILIARY' ] = self

	end # class AuxiliaryObjectClass


	### An LDAP objectClass of type 'STRUCTURAL'. From RFC4512:
	### 
	###   As stated in [X.501]:
    ###   
	###         An object class defined for use in the structural specification of
	###         the DIT is termed a structural object class.  Structural object
	###         classes are used in the definition of the structure of the names
	###         of the objects for compliant entries.
    ###   
	###         An object or alias entry is characterized by precisely one
	###         structural object class superclass chain which has a single
	###         structural object class as the most subordinate object class.
	###         This structural object class is referred to as the structural
	###         object class of the entry.
    ###   
	###         Structural object classes are related to associated entries:
    ###   
	###           - an entry conforming to a structural object class shall
	###             represent the real-world object constrained by the object
	###             class;
    ###   
	###           - DIT structure rules only refer to structural object classes;
	###             the structural object class of an entry is used to specify the
	###             position of the entry in the DIT;
    ###   
	###           - the structural object class of an entry is used, along with an
	###             associated DIT content rule, to control the content of an
	###             entry.
    ###   
	###         The structural object class of an entry shall not be changed.
    ###   
	###      Each structural object class is a (direct or indirect) subclass of
	###      the 'top' abstract object class.
    ###   
	###      Structural object classes cannot subclass auxiliary object classes.
    ###   
	###      Each entry is said to belong to its structural object class as well
	###      as all classes in its structural object class's superclass chain.
	### 
	class StructuralObjectClass < Treequel::Schema::ObjectClass
		Treequel::Schema::OBJECTCLASS_TYPES[ 'STRUCTURAL' ] = self

	end

end # class Treequel::Schema

