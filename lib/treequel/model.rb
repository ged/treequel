#!/usr/bin/env ruby
# coding: utf-8

require 'set'

require 'treequel'
require 'treequel/branch'
require 'treequel/branchset'


# An object interface to LDAP entries.
class Treequel::Model < Treequel::Branch
	require 'treequel/model/objectclass'
	require 'treequel/model/errors'
	require 'treequel/model/schemavalidations'

	include Treequel::Loggable,
	        Treequel::Constants,
	        Treequel::Normalization,
	        Treequel::Constants::Patterns,
	        Treequel::Model::SchemaValidations


	# A prototype Hash that autovivifies its members as Sets, for use in
	# the objectclass_registry and the base_registry
	SET_HASH = Hash.new {|h,k| h[k] = Set.new }


	# The hooks that are called before an action
	BEFORE_HOOKS = [
		:before_create,
		:before_update,
		:before_save,
		:before_destroy,
		:before_validation,
	  ]

	# The hooks that are called after an action
	AFTER_HOOKS = [
		:after_initialize,
		:after_create,
		:after_update,
		:after_save,
		:after_destroy,
		:after_validation,
	  ]

	# Hooks the user can override
	HOOKS = BEFORE_HOOKS + AFTER_HOOKS

	# Defaults for #validate options
	DEFAULT_VALIDATION_OPTIONS = {
		:with_schema => true,
	}

	# Defaults for #save options
	DEFAULT_SAVE_OPTIONS = {
		:raise_on_failure => true,
	}

	# Defaults for #destroy options
	DEFAULT_DESTROY_OPTIONS = {
		:raise_on_failure => true,
	}


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


	### Never freeze converted values in Model objects.
	def self::freeze_converted_values?; false; end


	### Create a new Treequel::Model object with the given +entry+ hash from the 
	### specified +directory+. Overrides Treequel::Branch.new_from_entry to pass the
	### +from_directory+ flag to mark it as unmodified.
	### 
	### @see Treequel::Branch.new_from_entry
	def self::new_from_entry( entry, directory )
		entry = Treequel::HashUtilities.stringify_keys( entry )
		dnvals = entry.delete( 'dn' ) or
			raise ArgumentError, "no 'dn' attribute for entry"

		Treequel.logger.debug "Creating %p from entry: %p in directory: %s" %
			[ self, dnvals.first, directory ]
		return self.new( directory, dnvals.first, entry, true )
	end


	#################################################################
	###	I N S T A N C E   M E T H O D S
	#################################################################

	### Override the default to extend new instances with applicable mixins if their
	### entry is set.
	def initialize( directory, dn, entry=nil, from_directory=false )
		if from_directory
			super( directory, dn, entry )
			@dirty = false
		else
			super( directory, dn )
			@values = entry ? symbolify_keys( entry ) : {}
			@dirty  = true
		end

		self.apply_applicable_mixins( @dn, @entry )
		self.after_initialize
	end


	### Copy initializer -- re-apply mixins to duplicates, too.
	def initialize_copy( other )
		super
		self.apply_applicable_mixins( @dn, @entry )
		self.after_initialize
	end


	######
	public
	######

	### Set up the empty hook methods
	HOOKS.each do |hook|
		define_method( hook ) do |*args|
			self.log.debug "#{hook} default hook called."
			true
		end
	end


	### Tests whether the object has been modified since it was loaded from
	### the directory.
	def modified?
		return @dirty ? true : false
	end


	### Mark the object as unmodified.
	def reset_dirty_flag
		@dirty = false
	end


	### Index set operator -- set attribute +attrname+ to a new +value+.
	### Overridden to make Model objects defer writing changes until 
	### {Treequel::Model#save} is called.
	### 
	### @param [Symbol, String] attrname  attribute name
	### @param [Object] value  the attribute value
	def []=( attrname, value )
		attrtype = self.find_attribute_type( attrname.to_sym ) or
			raise ArgumentError, "unknown attribute %p" % [ attrname ]
		value = Array( value ) unless attrtype.single?

		self.mark_dirty
		@values[ attrtype.name.to_sym ] = value

		# If the objectClasses change, we (may) need to re-apply mixins
		if attrname.to_s.downcase == 'objectclass'
			self.log.debug "  objectClass change -- reapplying mixins"
			self.apply_applicable_mixins( self.dn )
		else
			self.log.debug "  no objectClass changes -- no need to reapply mixins"
		end

		return value
	end


	### Make the changes to the object specified by the given +attributes+.
	### Overridden to make Model objects defer writing changes until 
	### {Treequel::Model#save} is called.
	### 
	### @param attributes (see Treequel::Directory#modify)
	### @return [TrueClass] if the merge succeeded
	def merge( attributes )
		attributes.each do |attrname, value|
			self[ attrname ] = value
		end
	end


	### Delete the specified attributes.
	### Overridden to make Model objects defer writing changes until 
	### {Treequel::Model#save} is called.
	### 
	### @see Treequel::Branch#delete
	def delete( *attributes )
		return super if attributes.empty?

		self.log.debug "Deleting attributes: %p" % [ attributes ]
		self.mark_dirty

		attributes.flatten.each do |attribute|

			# With a hash, delete each value for each key
			if attribute.is_a?( Hash )
				self.delete_specific_values( attribute )

			# With an array of attributes to delete, replace 
			# MULTIPLE attribute types with an empty array, and SINGLE 
			# attribute types with nil
			elsif attribute.respond_to?( :to_sym )
				attrtype = self.find_attribute_type( attribute.to_sym )
				if attrtype.single?
					@values[ attribute.to_sym ] = nil
				else
					@values[ attribute.to_sym ] = []
				end
			else
				raise ArgumentError,
					"can't convert a %p to a Symbol or a Hash" % [ attribute.class ]
			end
		end

		return true
	end


	### Returns the validation errors associated with this object.
	### @see Treequel::Model::Errors.
	def errors
		return @errors ||= Treequel::Model::Errors.new
	end


	### Return +true+ if the model object passes all of its validations.
	def valid?( opts={} )
		self.errors.clear
		self.validate( opts )
		return self.errors.empty? ? true : false
	end


	### Validate the object with the specified +options+. Appending validation errors onto
	### the #errors object.
	### @param [Hash] options  options for validation.
	### @option options [Boolean] :with_schema  whether or not to run the schema validations
	def validate( options={} )
		options = DEFAULT_VALIDATION_OPTIONS.merge( options )

		self.before_validation or
			raise Treequel::BeforeHookFailed, :validation
		self.errors.add( :objectClass, 'must have at least one' ) if self.object_classes.empty?

		super( options )
		self.after_validation
	end


	### Write any pending changes in the model object to the directory.
	### @param [Hash] opts  save options
	### @option opts [Boolean] :raise_on_failure  (true) raise a Treequel::ValidationFailed or
	###      Treequel::BeforeHookFailed if either the validations or before_{save,create}
	def save( opts={} )
		opts = DEFAULT_SAVE_OPTIONS.merge( opts )

		self.log.debug "Saving %s..." % [ self.dn ]
		raise Treequel::ValidationFailed, self.errors unless self.valid?( opts )
		self.log.debug "  validation succeeded."

		unless mods = self.modifications
			self.log.debug "  no modifications... no save necessary."
			return false
		end

		self.log.debug "  got %d modifications." % [ mods.length ]
		self.before_save( mods ) or
			raise Treequel::BeforeHookFailed, :save

		if self.exists?
			self.update( mods )
		else
			self.create( mods )
		end

		self.after_save( mods )

		return true
	rescue Treequel::BeforeHookFailed => err
		self.log.info( err.message )
		raise if opts[:raise_on_failure]
	rescue Treequel::ValidationFailed => err
		self.log.error( "Save aborted: validation failed." )
		self.log.info( err.errors.full_messages.join(', ') )
		raise if opts[:raise_on_failure]
	end


	### Return any pending changes in the model object.
	### @return [Array<LDAP::Mod>]  the changes as LDAP modifications
	def modifications
		return unless self.modified?
		self.log.debug "Gathering modifications..."

		mods = []
		entry = self.entry || {}
		self.log.debug "  directory entry is: %p" % [ entry ]

		@values.sort_by {|k, _| k.to_s }.each do |attribute, vals|
			vals = [ vals ] unless vals.is_a?( Array )
			vals = vals.compact
			vals.collect! {|val| self.get_converted_attribute(attribute, val) }
			self.log.debug "  comparing %s values to entry: %p vs. %p" %
				[ attribute, vals, entry[attribute.to_s] ]

			entryvals = (entry[attribute.to_s] || [])
			attrmods = { :add => [], :delete => [] }

			Diff::LCS.sdiff( entryvals.sort, vals.sort ) do |change|
				self.log.debug "    found a change: %p" % [ change ]
				if change.adding?
					attrmods[:add] << change.new_element
				elsif change.changed?
					attrmods[:add] << change.new_element
					attrmods[:delete] << change.old_element
				elsif change.deleting?
					attrmods[:delete] << change.old_element
				# else
				# 	self.log.debug "      no mod necessary for %p" % [ change.action ]
				end
			end

			self.log.debug "  attribute %p has %d adds and %d deletes" %
				[ attribute, attrmods[:add].length, attrmods[:delete].length ]
			mods << LDAP::Mod.new( LDAP::LDAP_MOD_DELETE, attribute.to_s, attrmods[:delete] ) unless
				attrmods[:delete].empty?
			mods << LDAP::Mod.new( LDAP::LDAP_MOD_ADD, attribute.to_s, attrmods[:add] ) unless
				attrmods[:add].empty?
		end

		self.log.debug "  mods are: %p" % [ mods ]

		return mods
	end


	### Return the pending modifications for the object as an LDIF string.
	def modification_ldif
		mods = self.modifications
		return LDAP::LDIF.mods_to_ldif( self.dn, mods )
	end


	### Revert to the attributes in the directory, discarding any pending changes.
	def revert
		self.clear_caches
		@dirty = false

		return true
	end


	### Like #delete, but runs destroy hooks before and after deleting.
	def destroy( opts={} )
		opts = DEFAULT_DESTROY_OPTIONS.merge( opts )

		self.before_destroy or raise Treequel::BeforeHookFailed, :destroy
		self.delete
		self.after_destroy

		return true
	rescue Treequel::BeforeHookFailed => err
		self.log.info( err.message )
		raise if opts[:raise_on_failure]
	end


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
		return super if caller(1).first =~ %r{/r?spec/} &&
			caller(1).first !~ /respond_to/ # RSpec workaround
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
		return "#<%s:0x%x (%s): %s>" % [
			self.class.name,
			self.object_id * 2,
			self.loaded? ?
			    self.extensions.map( &:name ).join( ', ' ) :
			    'not yet loaded',
			self.dn
		]
	end


	#########
	protected
	#########


	### Mark the object as having been modified.
	def mark_dirty
		@dirty = true
	end


	### Update the object's entry with the specified +mods+.
	### @param [Array<LDAP::Mod>] mods  the modifications to make
	def update( mods )
		self.log.debug "    entry already exists: updating..."
		self.before_update( mods ) or
			raise Treequel::BeforeHookFailed, :update
		self.modify( mods )
		self.after_update( mods )
	end


	### Create the entry for the object, using the specified +mods+ to set the attributes.
	### @param [Array<LDAP::Mod>] mods  the modifications to set attributes
	def create( mods )
		self.log.debug "    entry doesn't exist: creating..."
		self.before_create( mods ) or
			raise Treequel::BeforeHookFailed, :create
		super( mods )
		self.after_create( mods )
	end


	### Delete specific key/value +pairs+ from the entry.
	### @param [Hash] pairs  key/value pairs to delete from the entry.
	def delete_specific_values( pairs )
		self.log.debug "  hash-delete..."

		# Ensure the value exists, and its values converted and cached, as
		# the delete needs Ruby object instead of string comparison
		pairs.each do |key, vals|
			next unless self[ key ]
			self.log.debug "    deleting %p: %p" % [ key, vals ]

			@values[ key ].delete_if {|val| vals.include?(val) }
		end
	end


	### Search for the Treequel::Schema::AttributeType associated with +sym+.
	### 
	### @param [Symbol,String] name  the name of the attribute to find
	### @return [Treequel::Schema::AttributeType,nil]  the associated attributeType, or nil
	###                                                if there isn't one
	def find_attribute_type( name )
		attrtype = nil

		# Try both the name as-is, and the camelCased version of it
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
		self.log.debug "    method looks like a %p" % [ methodtype ]
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
		return lambda do |*args|
			if args.empty?
				self[ attrname ]
			else
				self.traverse_branch( attrname, *args )
			end
		end
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
			return lambda {|*newvalues| self[attrname] = newvalues.flatten }
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
		if entryhash = super
			self.apply_applicable_mixins( self.dn, entryhash )
		end

		return entryhash
	end


	### Apply mixins that are applicable considering the receiver's DN and the 
	### objectClasses from the given +entryhash+ merged with any unsaved values.
	def apply_applicable_mixins( dn, entryhash=nil )
		objectclasses = @values[:objectClass] ||
			(entryhash && entryhash['objectClass'])
		return unless objectclasses

		# self.log.debug "Applying mixins applicable to %s" % [ dn ]
		schema = self.directory.schema

		ocs = objectclasses.collect do |oc_oid|
			explicit_oc = schema.object_classes[ oc_oid ]
			explicit_oc.ancestors.collect {|oc| oc.name }
		end.flatten.uniq
		# self.log.debug "  got %d candidate objectClasses: %p" % [ ocs.length, ocs ]

		# The applicable mixins are those in the intersection of the ones
		# inferred by its objectclasses and those that apply to its DN
		oc_mixins = self.class.mixins_for_objectclasses( *ocs )
		dn_mixins = self.class.mixins_for_dn( dn )
		mixins = ( oc_mixins & dn_mixins )

		# self.log.debug "  %d mixins remain after intersection: %p" % [ mixins.length, mixins ]

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
		when /^(?:has_)?([a-z]\w*)\?$/i
			return $1.to_sym, :predicate
		when /^([a-z]\w*)(=)?$/i
			return $1.to_sym, ($2 ? :writer : :reader )
		end
	end


	### Turn a String DN into a reversed set of DN attribute/value pairs
	def make_dn_tuples( dn )
		return dn.split( /\s*,\s*/ ).reverse
	end

end # class Treequel::Model



