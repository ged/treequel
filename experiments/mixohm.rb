#!ruby

# This is an experiment to see how LDAP entries can be mapped into
# Ruby object-space, but only using mostly mixins instead of the
# approach in ohm.rb.

require 'pp'
require 'set'
require 'treequel'
require 'treequel/mixins'
#require 'treequel/model'

# A Treequel::Model object:
# * Knows what its Treequel::Branch is
# * has one or more mixins applied to it based on its objectclasses
# 
# module Employee
#   extend Treequel::Model::ObjectClass
# 	model_bases 'ou=people'
# 	model_objectclasses :acmeAccount, :inetOrgPerson
# end
# 
# pp Employee.find( ~:userDisabledPassword )
# 


class Treequel::Model < Treequel::Branch

	module ObjectClass
		extend Treequel::Delegation

		def_method_delegators :branchset, :filter, :scope, :select, :limit, :timeout, :order

		def self::extended( mod )
			mod.instance_variable_set( :@model_directory, nil )
			mod.instance_variable_set( :@model_bases, [] )
			mod.instance_variable_set( :@model_objectclasses, [] )
			super
		end

		def self::included( mod )
			mod.send( :extend, self )
		end


		def model_directory( uri=nil )
			@model_directory = Treequel.directory( uri ) if uri
			return @model_directory || Treequel.directory_from_config()
		end

		def model_bases( *rdns )
			unless rdns.empty?
				@model_bases = rdns
			end
			return @model_bases
		end

		def model_objectclasses( *objectclasses )
			unless objectclasses.empty?
				@model_objectclasses = objectclasses
				objectclasses.each do |oc|
					Treequel::Model.register_objectclass( oc, self )
				end
			end
			return @model_objectclasses
		end

		def branchset
			directory = self.model_directory or
				raise "No directory associated with %p" % [ self ]
			objectclasses = self.model_objectclasses
			branchsets = self.model_bases.collect do |dn|
				Treequel::Model.new( directory, dn ).filter( :objectClass => objectclasses )
			end
			return Treequel::BranchCollection.new( *branchsets )
		end

	end # ObjectClass


	@objectclass_registry = {}
	class << self
		attr_reader :objectclass_registry
	end


	### Register +mixin+ as a decoration for model objects with the given +objectclass+.
	def self::register_objectclass( objectclass, mixin )
		# $stderr.puts "Registering %p as a mixin for entries with the %s objectclass" %
		# 	[ mixin, objectclass ]
		self.objectclass_registry[ objectclass.to_sym ] ||= []
		self.objectclass_registry[ objectclass.to_sym ] << mixin
	end


	### Return an Array of modules that should be mixed into Model objects that have the
	### given +objectclasses+.
	def self::mixins_for_objectclasses( *objectclasses )
		ocsymbols = objectclasses.collect {|oc| oc.to_sym }
		mixins = self.objectclass_registry.values_at( *ocsymbols ).flatten.compact.uniq
		# $stderr.puts "Got candidate mixins: %p for objectClasses: %p" %
		# 	[ mixins, ocsymbols ]
		return mixins.select do |mixin|
			# $stderr.puts "  %p requires objectclasses: %p" % [ mixin, mixin.model_objectclasses ]
			mixin.model_objectclasses.all? {|oc| ocsymbols.include?(oc) }
		end
	end


	### Create a new Treequel::Model object from the given +entry+ hash from the 
	### specified +directory+.
	### 
	### @param [LDAP::Entry] entry  The raw entry object the Branch is wrapping.
	### @param [Treequel::Directory] directory  The directory object the Branch is from.
	### 
	### @return [Treequel::Model]  The new model object.
	def self::new_from_entry( entry, directory )
		obj = self.new( directory, entry['dn'].first, entry )
		self.mixins_for_objectclasses( *obj[:objectClass] ).each do |mixin|
			# $stderr.puts "  extending %p with %p" % [ obj, mixin ]
			obj.extend( mixin )
		end
		return obj
	end


	### Handle calls to missing methods by searching for an attribute 
	def method_missing( sym, *args )
		plainsym = sym.to_s.sub( /[=\?]$/, '' ).to_sym
		return super unless self.valid_attribute_oids.include?( plainsym )

		if sym.to_s[ -1 ] == ?=
			return self[ plainsym ] = args
		elsif sym.to_s[ -1 ] == ??
			if self.directory.schema.attribute_types[ plainsym ].single?
				return self[ plainsym ] ? true : false
			else
				return self[ plainsym ].first ? true : false
			end
		else
			return self[ plainsym ]
		end
	end


end


module AcmeAccount
	extend Treequel::Model::ObjectClass

#	model_directory 'ldap://localhost/dc=acme,dc=com'
	model_bases 'ou=people,dc=acme,dc=com'
	model_objectclasses :acmeAccount

	def accountConfig
		return self[:accountConfig].inject({}) do |config, pair|
			key, val = pair.split( '=', 2 )
			config[ key ] = val
			config
		end
	end

end


module Group
	extend Treequel::Model::ObjectClass

#	model_directory 'ldap://localhost/dc=acme,dc=com'
	model_bases 'ou=groups,dc=acme,dc=com'
	model_objectclasses :posixGroup

	def members
		Person.filter( :uid => self.memberUid ).all
	end
end


module Person
	extend Treequel::Model::ObjectClass

#	model_directory 'ldap://localhost/dc=acme,dc=com'
	model_bases 'ou=people,dc=acme,dc=com'
	model_objectclasses :inetOrgPerson, :acmeAccount

	### Returns the employee's name in "First Last" form.
	def displayname
		return self[:displayName] ||
			[ self.givenName, self.sn ].compact.join( ' ' )
	end


	### Returns the employee's name in the form: "Last, First"
	def name_lastfirst
		return [ self.sn, self.givenName ].compact.join( ', ' )
	end

	def groups
		return Group.filter( :memberUid => self.uid ).all
	end

end # Person


Treequel.logger.level = Logger::DEBUG
Treequel.logger.formatter = Treequel::ColorLogFormatter.new( Treequel.logger )
people = Person.filter( :givenName => 'Michael' ).all
pp people

people.collect do |person|
	if person.is_a?( AcmeAccount )
		$stderr.puts( person.name_lastfirst )
	end

	$stderr.puts "Groups: %s" % [ person.groups.collect {|gr| gr.cn }.join(", ") ]
end

pp Group.filter( :cn => :sysadmin ).first

