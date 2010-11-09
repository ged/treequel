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
		return self.objectclass_registry[:top] if objectclasses.empty?
		ocsymbols = objectclasses.flatten.collect {|oc| oc.untaint.to_sym }

		# Get the union of all of the mixin sets for the objectclasses in question
		mixins = self.objectclass_registry.
			values_at( *ocsymbols ).
			inject {|set1,set2| set1 | set2 }

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

		# Get the union of all of the mixin sets for the DN and all of its parents
		union = self.base_registry.
			values_at( *dn_keys ).
			inject {|set1,set2| set1 | set2 }

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


	######
	public
	######

	### Override Branch#search to inject the 'objectClass' attribute to the
	### selected attribute list if there is one.
	def search( scope=:subtree, filter='(objectClass=*)', parameters={}, &block )
		parameters[:selectattrs] |= ['objectClass'] unless
			!parameters.key?( :selectattrs ) || parameters[ :selectattrs ].empty?

		super
	end


	### Returns +true+ if the receiver responds to the given method.
	### @param [Symbol,String] sym  the name of the method to test for
	### @return [Boolean]
	def respond_to?( sym, include_priv=false )
		# return super if caller(1).first =~ %r{/spec/} &&
		# 	caller(1).first !~ /respond_to/ # RSpec workaround
		return true if super
		plainsym, _ = attribute_from_method( sym )
		return self.find_attribute_type( plainsym ) ? true : false
	end


	### Return the Treequel::Model::ObjectClass mixins that have been applied to the receiver.
	### @return [Array<Module>]
	def extensions
		eigenclass = ( class << self; self; end )
		return eigenclass.included_modules.find_all do |mod|
			(class << mod; self; end).include?(Treequel::Model::ObjectClass)
		end
	end


	### Return a human-readable representation of the receiving object, suitable for debugging.
	def inspect
		return "#<%s:0x%x (%s)>" % [
			self.class.name,
			self.object_id * 2,
			self.extensions.map( &:name ).join( ', ' )
		]
	end


	#########
	protected
	#########

	### Search for the Treequel::Schema::AttributeType associated with +sym+.
	### 
	### @param [Symbol,String] name  the name of the attribute to find
	### @return [Treequel::Schema::AttributeType,nil]  the associated attributeType, or nil
	###                                                if there isn't one
	def find_attribute_type( name )
		attrtype = nil

		# If the attribute doesn't match as-is, try the camelCased version of it
		camelcased_sym = name.to_s.gsub( /_(\w)/ ) { $1.upcase }.to_sym
		attrtype = self.valid_attribute_type( name ) ||
		           self.valid_attribute_type( camelcased_sym )

		return attrtype
	end


	### Proxy method -- Handle calls to missing methods by searching for an attribute.
	def method_missing( sym, *args )
		self.log.debug "Dynamic dispatch to %p with args: %p" % [ sym, args ]

		# First, if the entry hasn't yet been loaded, try loading it to make sure the 
		# object is already extended with any applicable objectClass mixins. If that ends
		# up defining the method in question, call it.
		if !@entry && self.entry
			self.log.debug "  entry wasn't loaded, looking for methods added by loading it..."
			meth = begin
				self.method( sym )
			rescue NoMethodError, NameError => err
				self.log.debug "  it still didn't define %p: %s: %s" %
					[ sym, err.class.name, err.message ]
				nil
			end
			return meth.call( *args ) if meth
		end

		self.log.debug "  checking to see if it's a traversal call"
		# Next, super to rdn-traversal if it looks like a reader but has arguments
		plainsym, methodtype = attribute_from_method( sym )
		self.log.debug "    method look like a %p" % [ methodtype ]
		return super if methodtype == :reader && !args.empty?
		self.log.debug "  ...but it doesn't have any arguments. Finding attr type."

		# Now make a method body for a new method based on what attributeType it is if 
		# it's a valid attribute
		attrtype = self.find_attribute_type( plainsym ) or return super
		self.log.debug "  attrtype is: %p" % [ attrtype ]
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
		if entry = super
			self.log.debug "  applying mixins to %p" % [ entry ]
			self.apply_applicable_mixins( self.dn, entry )
		else
			self.log.debug "  failed to fetch the entry."
		end
		return entry
	end


	### Apply mixins that are applicable considering the receiver's DN and the 
	### objectClasses from its entry.
	def apply_applicable_mixins( dn, entry )
		schema = self.directory.schema

		ocs = entry['objectClass'].collect do |oc_oid|
			explicit_oc = schema.object_classes[ oc_oid ]
			explicit_oc.ancestors.collect {|oc| oc.name }
		end.flatten.uniq

		oc_mixins = self.class.mixins_for_objectclasses( *ocs )
		dn_mixins = self.class.mixins_for_dn( dn )

		# The applicable mixins are those in the intersection of the ones
		# inferred by its objectclasses and those that apply to its DN
		mixins = ( oc_mixins & dn_mixins )

		self.log.debug "Applying %d mixins to %s: %p" %
			[ mixins.length, dn, mixins.collect(&:inspect) ]
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



