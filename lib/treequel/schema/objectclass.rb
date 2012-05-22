#!/usr/bin/env ruby

require 'English'

require 'treequel'
require 'treequel/schema'
require 'treequel/exceptions'


# This is a collection of classes for representing objectClasses in a Treequel::Schema.
# 
# == Authors
# 
# * Michael Granger <ged@FaerieMUD.org>
# * Mahlon E. Smith <mahlon@martini.nu>
# 
# :include: LICENSE
#
#--
#
# Please see the file LICENSE in the base directory for licensing details.
#
class Treequel::Schema

	# The types of objectClass as specified in the schema, along with which Ruby class
	# corresponds to it. Each class registers itself as it's defined.
	OBJECTCLASS_TYPES = {}


	### objectClass entries in a Treequel::Schema.
	class ObjectClass
		include Treequel::Constants::Patterns

		extend Loggability,
		       Treequel::AttributeDeclarations


		# Loggability API -- Log to the Treequel module's logger
		log_to :treequel


		# Hide the constructor
		private_class_method :new

		# The 'kind' of objectClasses which don't specify a 'kind' explicitly
		DEFAULT_OBJECTCLASS_KIND = 'STRUCTURAL'


		#############################################################
		###	C L A S S   M E T H O D S
		#############################################################

		### Inheritance callback: Make the constructor method of all inheriting classes
		### public.
		def self::inherited( subclass )
			subclass.instance_eval { public_class_method :new }
		end


		### Parse an ObjectClass entry from a RFC4512-format objectClass +description+ from a 
		### +schema+.
		def self::parse( schema, description )
			oid, names, desc, obsolete, sup, kind, must, may, extensions = nil

			# :FIXME: Change this to some sort of strategy that extracts the pieces from the
			# description and checks to be sure everything was consumed instead of depending
			# on the RFC's BNF. It appears people expect to be able to arbitrarily reorder
			# them, and making a different Regexp for each exception isn't going to work
			# long-term.
			case description.gsub( /[\n\t]+/, ' ' ).squeeze( ' ' )
			when LDAP_OBJECTCLASS_DESCRIPTION
				oid, names, desc, obsolete, sup, kind, must, may, extensions = $~.captures
			when LDAP_MISORDERED_KIND_OBJECTCLASS_DESCRIPTION
				oid, names, desc, obsolete, kind, sup, must, may, extensions = $~.captures
				self.handle_malformed_parse( "transposed KIND (#{kind}) and SUP (#{sup})",
				                              description )
			when LDAP_TRAILING_KIND_OBJECTCLASS_DESCRIPTION
				oid, names, desc, obsolete, sup, must, may, kind, extensions = $~.captures
				self.handle_malformed_parse( "misordered KIND (#{kind})", description )
			when LDAP_MISORDERED_DESC_OBJECTCLASS_DESCRIPTION
				oid, names, obsolete, sup, kind, desc, must, may, extensions = $~.captures
				self.handle_malformed_parse( "misordered DESC (#{desc})", description )
			else
				raise Treequel::ParseError, "failed to parse objectClass from %p" % [ description ]
			end

			# Normalize the attributes
			must_oids  = Treequel::Schema.parse_oids( must )
			may_oids   = Treequel::Schema.parse_oids( may )
			names      = Treequel::Schema.parse_names( names )
			desc       = Treequel::Schema.unquote_desc( desc )
			extensions = extensions.strip

			# Default the 'kind' attribute
			kind ||= DEFAULT_OBJECTCLASS_KIND

			# Find the appropriate concrete class to instantiate 
			concrete_class = Treequel::Schema::OBJECTCLASS_TYPES[ kind ] or
				raise Treequel::Error, "no such objectClass type %p: expected one of: %p" %
					[ kind, Treequel::Schema::OBJECTCLASS_TYPES.keys ]

			return concrete_class.new( schema, oid, names, desc, obsolete, sup,
			                           must_oids, may_oids, extensions )
		end


		### Handle the parse of an objectClass that matches one of the non-standard objectClass
		### definitions found in several RFCs. If Treequel::Schema.strict_parse_mode? is +true+,
		### this method will raise an exception.
		def self::handle_malformed_parse( message, oc_desc )
			raise Treequel::ParseError, "Malformed objectClass: %s: %p" % [ message, oc_desc ] if
				Treequel::Schema.strict_parse_mode?
			Treequel.log.info "Working around malformed objectClass: %s: %p" % [ message, oc_desc ]
		end


		#############################################################
		###	I N S T A N C E   M E T H O D S
		#############################################################

		### Create a new ObjectClass 
		def initialize( schema, oid, names=nil, desc=nil, obsolete=false, sup=nil, must_oids=[],
		                may_oids=[], extensions=nil )
			@schema     = schema

			@oid        = oid
			@names      = names
			@desc       = desc
			@obsolete   = obsolete ? true : false
			@sup_oid    = sup
			@must_oids  = must_oids
			@may_oids   = may_oids
			@extensions = extensions

			super()
		end


		######
		public
		######

		# The schema the objectClass belongs to
		attr_reader :schema

		# The objectClass's oid
		attr_reader :oid

		# The Array of the objectClass's names
		attr_reader :names

		# The objectClass's description
		attr_accessor :desc

		# Is the objectClass obsolete?
		predicate_attr :obsolete

		# The OID of the objectClass's superior class (if specified)
		attr_accessor :sup_oid

		# The objectClass's extensions (as a String)
		attr_accessor :extensions


		### Return the first of the objectClass's names, if it has any, or +nil+.
		def name
			return self.names.first
		end


		### Return the objectClass's MUST OIDs as Symbols (for symbolic OIDs) or Strings (for
		### dotted-numeric OIDs). If include_sup is true, include MUST OIDs inherited from the 
		### objectClass's SUP, if it has one.
		def must_oids( include_sup=true )
			oids = @must_oids.dup

			if include_sup && superclass = self.sup
				oids.unshift( *superclass.must_oids )
			end

			return oids.flatten
		end


		### Return Treequel::Schema::AttributeType objects for each of the objectClass's
		### MUST attributes.
		def must( include_sup=true )
			self.must_oids( include_sup ).collect do |oid|
				self.log.warn "No attribute type for OID %p (case bug?)" % [ oid ] unless
					self.schema.attribute_types.key?( oid )
				self.schema.attribute_types[oid]
			end.compact
		end


		### Return the objectClass's MAY OIDs as Symbols (for symbolic OIDs) or Strings (for
		### dotted-numeric OIDs). If include_sup is true, include MAY OIDs inherited from the 
		### objectClass's SUP, if it has one.
		def may_oids( include_sup=true )
			oids = @may_oids.dup

			if include_sup && superclass = self.sup
				oids.unshift( *superclass.may_oids )
			end

			return oids.flatten
		end


		### Return Treequel::Schema::AttributeType objects for each of the objectClass's
		### MAY attributes.
		def may( include_sup=true )
			self.may_oids( include_sup ).collect do |oid|
				self.log.warn "No attribute type for OID %p (case bug?)" % [ oid ] unless
					self.schema.attribute_types.key?( oid )
				self.schema.attribute_types[oid]
			end.compact
		end


		### Returns +true+ if this objectClass is STRUCTURAL. Defaults to +false+ and then
		### overridden in StructuralObjectClass.
		def structural?
			return false
		end


		### Returns the objectClass as a String, which is the RFC4512-style schema
		### description.
		def to_s
			# ObjectClassDescription = LPAREN WSP
		    #     numericoid                 ; object identifier
		    #     [ SP "NAME" SP qdescrs ]   ; short names (descriptors)
		    #     [ SP "DESC" SP qdstring ]  ; description
		    #     [ SP "OBSOLETE" ]          ; not active
		    #     [ SP "SUP" SP oids ]       ; superior object classes
		    #     [ SP kind ]                ; kind of class
		    #     [ SP "MUST" SP oids ]      ; attribute types
		    #     [ SP "MAY" SP oids ]       ; attribute types
		    #     extensions WSP RPAREN
            #
		    # kind = "ABSTRACT" / "STRUCTURAL" / "AUXILIARY"

			parts = [ self.oid ]

			parts << "NAME %s" % Treequel::Schema.qdescrs( self.names ) unless self.names.empty?
			parts << "DESC %s" % [ Treequel::Schema.qdstring(self.desc) ] if self.desc
			parts << "OBSOLETE" if self.obsolete?
			parts << "SUP %s" % [ Treequel::Schema.oids(self.sup_oid) ] if self.sup_oid
			parts << self.kind
			parts << "MUST %s" % [ Treequel::Schema.oids(self.must_oids(false)) ] unless
				self.must_oids(false).empty?
			parts << "MAY %s" % [ Treequel::Schema.oids(self.may_oids(false)) ] unless
				self.may_oids(false).empty?
			parts << self.extensions.strip unless self.extensions.empty?

			return "( %s )" % [ parts.join(' ') ]
		end


		### Return a human-readable representation of the object suitable for debugging
		def inspect
			return %{#<%s:0x%0x %s(%s) < %s "%s" MUST: %p, MAY: %p>} % [
				self.class.name,
				self.object_id / 2,
				self.name,
				self.oid,
				self.sup_oid,
				self.desc,
				self.must_oids,
				self.may_oids,
			]
		end


		### Return the ObjectClass for the receiver's SUP. If this is called on
		### 'top', returns nil.
		def sup
			unless name = self.sup_oid
				return nil if self.oid == Treequel::Constants::OIDS::TOP_OBJECTCLASS
				return self.schema.object_classes[ :top ]
			end
			return self.schema.object_classes[ name.to_sym ]
		end


		### Return the SUP chain for the receiver up to 'top', including the receiver
		### itself, as an Array of Treequel::Schema::ObjectClass objects.
		def ancestors
			rval = [ self ]

			if parent = self.sup
				rval += parent.ancestors
			end

			return rval
		end


		### Return the string that represents the kind of objectClass the receiver represents.
		### It will be one of: 'ABSTRACT', 'STRUCTURAL', 'AUXILIARY'
		def kind
			return Treequel::Schema::OBJECTCLASS_TYPES.invert[ self.class ]
		end

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
	###   An object class defined for use in the structural specification of
	###   the DIT is termed a structural object class.  Structural object
	###   classes are used in the definition of the structure of the names
	###   of the objects for compliant entries.
    ###   
	###   An object or alias entry is characterized by precisely one
	###   structural object class superclass chain which has a single
	###   structural object class as the most subordinate object class.
	###   This structural object class is referred to as the structural
	###   object class of the entry.
    ###   
	###   Structural object classes are related to associated entries:
    ###   
	###     - an entry conforming to a structural object class shall
	###       represent the real-world object constrained by the object
	###       class;
    ###   
	###     - DIT structure rules only refer to structural object classes;
	###       the structural object class of an entry is used to specify the
	###       position of the entry in the DIT;
    ###   
	###     - the structural object class of an entry is used, along with an
	###       associated DIT content rule, to control the content of an
	###       entry.
    ###   
	###   The structural object class of an entry shall not be changed.
    ### 
	###   Each structural object class is a (direct or indirect) subclass of
	###   the 'top' abstract object class.
    ### 
	###   Structural object classes cannot subclass auxiliary object classes.
    ### 
	###   Each entry is said to belong to its structural object class as well
	###   as all classes in its structural object class's superclass chain.
	### 
	class StructuralObjectClass < Treequel::Schema::ObjectClass
		Treequel::Schema::OBJECTCLASS_TYPES[ 'STRUCTURAL' ] = self

		### Returns +true+, indicating that instances of this class are STRUCTURAL.
		def structural?
			return true
		end

	end # class StructuralObjectClass

end # class Treequel::Schema

