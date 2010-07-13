#!/usr/bin/env ruby
# coding: utf-8

require 'set'

require 'treequel'
require 'treequel/branch'
require 'treequel/branchset'


# An object interface to LDAP entries.
class Treequel::Model < Treequel::Branch
	include Treequel::Loggable,
	        Treequel::Constants,
	        Treequel::Normalization,
	        Treequel::Constants::Patterns

	require 'treequel/model/objectclass'


	# A prototype Hash that autovivifies its members as Sets, for use in
	# the objectclass_registry and the base_registry
	SET_HASH = Hash.new {|h,k| h[k] = Set.new }


	#################################################################
	###	C L A S S   M E T H O D S
	#################################################################

	@objectclass_registry = SET_HASH.dup
	@base_registry = SET_HASH.dup

	class << self
		attr_reader :objectclass_registry
		attr_reader :base_registry
	end


	### Inheritance callback -- add a class-specific objectclass registry to inheriting classes.
	### @param [Class] subclass  the inheriting class
	def self::inherited( subclass )
		super
		subclass.instance_variable_set( :@objectclass_registry, SET_HASH.dup )
		subclass.instance_variable_set( :@base_registry, SET_HASH.dup )
	end


	### Register the given +mixin+ for the specified +objectclasses+. Instances that 
	### have all the specified +objectclasses+ will be extended with the +mixin+.
	###
	### @param [Module] mixin                 the mixin to be applied; it should be extended with 
	###                                       Treequel::Model::ObjectClass.
	def self::register_mixin( mixin )
		objectclasses = mixin.model_objectclasses
		bases = mixin.model_bases
		bases << '' if bases.empty?

		Treequel.logger.debug "registering %p [objectClasses: %p, base DNs: %p]" %
			[ mixin, objectclasses, bases ]

		# Register it with each of its objectClasses
		objectclasses.each do |oc|
			@objectclass_registry[ oc.to_sym ].add( mixin )
		end

		# ...and each of its bases
		bases.each do |dn|
			@base_registry[ dn.downcase ].add( mixin )
		end
	end


	### Unregister the given +mixin+ for the specified +objectclasses+.
	### @param [Module] mixin  the mixin that should no longer be applied
	def self::unregister_mixin( mixin )
		objectclasses = mixin.model_objectclasses
		bases = mixin.model_bases
		bases << '' if bases.empty?

		Treequel.logger.debug "un-registering %p [objectclasses: %p, base DNs: %p]" %
			[ mixin, objectclasses, bases ]

		# Unregister it from each of its bases
		bases.each do |dn|
			@base_registry[ dn.downcase ].delete( mixin )
		end

		# ...and each of its objectClasses
		objectclasses.each do |oc|
			@objectclass_registry[ oc.to_sym ].delete( mixin )
		end
	end


	### Return the mixins that should be applied to an entry with the given +objectclasses+.
	### @param [Array<Symbol>] objectclasses  the objectclasses from the entry
	### @return [Set<Module>] the Set of mixin modules which apply
	def self::mixins_for_objectclasses( *objectclasses )
		ocsymbols = objectclasses.flatten.collect {|oc| oc.to_sym }

		# Get the union of all of the mixin sets for the objectclasses in question
		mixins = self.objectclass_registry.
			values_at( *ocsymbols ).
			inject {|set1,set2| set1 | set2 }

		Treequel.logger.debug "Got candidate mixins: %p for objectClasses: %p" %
			[ mixins, ocsymbols ]

		# Return the mixins whose objectClass requirements are met by the 
		# specified objectclasses
		return mixins.delete_if do |mixin|
			!mixin.model_objectclasses.all? {|oc| ocsymbols.include?(oc) }
		end
	end


	### Return the mixins that should be applied to an entry with the given +dn+.
	### @param [String] dn  the DN of the entry
	### @return [Set<Module>] the Set of mixin modules which apply
	def self::mixins_for_dn( dn )
		dn_tuples = dn.downcase.split( /\s*,\s*/ )
		dn_keys = dn_tuples.reverse.inject(['']) do |keys, dnpair|
			dnpair += ',' + keys.last unless keys.last.empty?
			keys << dnpair
		end

		Treequel.log.debug "Finding mixins for DN keys: %p" % [ dn_keys ]

		# Get the union of all of the mixin sets for the DN and all of its parents
		union = self.base_registry.
			values_at( *dn_keys ).
			inject {|set1,set2| set1 | set2 }
		Treequel.log.debug "  found: %p" % [ union ]

		return union
	end



	#################################################################
	###	I N S T A N C E   M E T H O D S
	#################################################################

	### Override the default to extend new instances with applicable mixins if their
	### entry is set.
	def initialize( *args )
		super
		self.apply_applicable_mixins( @dn, @entry ) if @entry
	end


	#########
	protected
	#########

	### Proxy method -- Handle calls to missing methods by searching for an attribute.
	def method_missing( sym, *args )
		plainsym, methodtype = attribute_from_method( sym )

		unless attrtype = self.valid_attribute_type( plainsym )

			# If the attribute doesn't match as-is, try stripping underscores so
			# attribute_name -> attributeName works.
			camelcased_sym = plainsym.to_s.gsub( /_(\w)/ ) { $1.upcase }.to_sym

			unless camelcased_sym != plainsym &&
				   (attrtype = self.valid_attribute_type( camelcased_sym ))
				self.log.error "method_missing: No valid attribute named %p; falling through" %
					[ plainsym ]
				return super
			end
		end

		# Get the attribute's canonical name from the schema
		attrname = attrtype.name

		# Make a method body for a new method based on what kind it is
		methodbody = case methodtype
			when :writer
				self.make_writer( attrtype )
			when :predicate
				self.make_predicate( attrtype )
			else
				self.make_reader( attrtype )
			end

		# Define the new method and call it by fetching the corresponding Method object
		# so we don't loop back through #method_missing if something goes wrong
		self.class.send( :define_method, sym, &methodbody )
		return self.method( sym ).call( *args )
	end


	### Make a reader method body for the given +attrtype+.
	###
	### @param [Treequel::Mode::AttributeType] attrtype  the attributeType to create the reader
	###                                                  for.
	### @return [Proc]  the body of the reader method.
	def make_reader( attrtype )
		self.log.debug "Generating an attribute reader for %p" % [ attrtype ]
		attrname = attrtype.name
		return lambda {|*args|
			if args.empty?
				self[ attrname ]
			else
				self.traverse_branch( attrname, *args )
			end
		}
	end


	### Make a writer method body for the given +attrtype+.
	###
	### @param [Treequel::Mode::AttributeType] attrtype  the attributeType to create the accessor
	###                                                  for.
	### @return [Proc]  the body of the writer method.
	def make_writer( attrtype )
		self.log.debug "Generating an attribute writer for %p" % [ attrtype ]
		attrname = attrtype.name
		if attrtype.single?
			self.log.debug "  attribute is SINGLE, so generating a scalar writer..."
			return lambda {|newvalue| self[attrname] = newvalue }
		else
			self.log.debug "  attribute isn't SINGLE, so generating an array writer..."
			return lambda {|*newvalues| self[attrname] = newvalues }
		end
	end


	### Make a predicate method body for the given +attrtype+.
	###
	### @param [Treequel::Mode::AttributeType] attrtype  the attributeType to create the method
	###                                                  for.
	### @return [Proc]  the body of the predicate method.
	def make_predicate( attrtype )
		self.log.debug "Generating an attribute predicate for %p" % [ attrtype ]
		attrname = attrtype.name
		if attrtype.single?
			self.log.debug "  attribute is SINGLE, so generating a scalar predicate..."
			return lambda { self[attrname] ? true : false }
		else
			self.log.debug "  attribute isn't SINGLE, so generating an array predicate..."
			return lambda { self[attrname].any? {|val| val} }
		end
	end


	### Overridden to apply applicable mixins to lazily-loaded objects once their entry 
	### has been looked up.
	### @return [LDAP::Entry]  the fetched entry object
	def lookup_entry
		entry = super
		self.apply_applicable_mixins( self.dn, entry )
		return entry
	end


	### Apply mixins that are applicable considering the receiver's DN and the 
	### objectClasses from its entry.
	def apply_applicable_mixins( dn, entry )
		oc_mixins = self.class.mixins_for_objectclasses( entry['objectClass'] )
		dn_mixins = self.class.mixins_for_dn( dn )

		# The applicable mixins are those in the intersection of the ones
		# inferred by its objectclasses and those that apply to its DN
		mixins = ( oc_mixins & dn_mixins )
		self.log.debug "Applying %d mixins to %s" % [ mixins.length, dn ]

		mixins.each {|mod| self.extend(mod) }
	end


	#######
	private
	#######

	### Given the symbol from an attribute accessor or predicate, return the
	### name of the corresponding LDAP attribute/
	### @param [Symbol] methodname  the method being called
	### @return [Symbol] the attribute name that corresponds to the method
	def attribute_from_method( methodname )

		case methodname.to_s
		when /^(?:has_)?([a-z]\w+)\?$/i
			return $1.to_sym, :predicate
		when /^([a-z]\w+)(=)?$/i
			return $1.to_sym, ($2 ? :writer : :reader )
		end
	end


	### Turn a String DN into a reversed set of DN attribute/value pairs
	def make_dn_tuples( dn )
		return dn.split( /\s*,\s*/ ).reverse
	end

end # class Treequel::Model



