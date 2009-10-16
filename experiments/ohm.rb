#!ruby

# This is an experiment to see how LDAP entries can be mapped into
# Ruby object-space. Since LDAP has a freeform, class+mixin-based
# object model of its own, it should map pretty easily into Ruby-land,
# but it can't work like ActiveRecord or something that depends on
# objects mapping fairly one-to-one with rows in a database. This is
# an attempt to model it more faithfully to LDAP's principles.

require 'pp'
require 'rubygems'
require 'treequel'
require 'treequel/mixins'
#require 'treequel/model'

dir = Treequel.directory

# A model is specialized kind of Branch that:
# * Knows what its directory is
# * Has a pre-filtered BranchSet
# * Has a collection of anonymous modules, one for each objectclass
# class Treequel::Model < Treequel::Branch
# 
# 	@directory = nil
# 	@branchset = nil
# 
# 	def self::directory
# 		@directory ||= super
# 		raise "No Directory set!" unless @directory
# 		return @directory
# 	end
# 
# 	def self::directory=( new_directory )
# 		@directory = new_directory
# 		@object_classes
# 	end
# 
# 	def self::inherited( mod )
# 		mod.instance_variable_set( :@branchset, nil )
# 		super
# 	end
# 
# 	def self::model_branchset( bs )
# 		return self.branchset = bs
# 	end
# 
# 	def self::all
# 		self.branchset.all
# 	end
# 
# end
# 
# 
# class Employee < Treequel::Model
# 	model_branchset DIR.ou( :people ).filter( :objectClass => :laikaAccount )
# 	model_objectClasses :laikaAccount, :inetOrgPerson
# end
# 
# pp Employee.find( :firstname => 'Scarlet' )
# 
# 
# 


@abstract = {}
@structural = {}
@auxiliary = {}

def fetch_objectclass( oc )
	case oc
	when Treequel::Schema::AbstractObjectClass
		fetch_abstract_objectclass( oc )
	when Treequel::Schema::StructuralObjectClass
		fetch_structural_objectclass( oc )
	when Treequel::Schema::AuxiliaryObjectClass
		fetch_auxiliary_objectclass( oc )
	else
		raise "Ack! I don't know how to fetch a class/module for %s instances" %
			[ oc.class ]
	end
rescue => err
	$stderr.puts "Problems fetching representation of %p" % [ oc ]
	return nil
end


def fetch_abstract_objectclass( oc )
	return Object if oc.nil?

	unless classobj = @abstract[ oc.oid ]
		parent = fetch_abstract_objectclass( oc.sup )
		$stderr.puts "Creating abstract objectClass %s (%s)" % [ oc.name, oc.oid ]
		classobj = @abstract[ oc.oid ] = Class.new( parent || Object ) do
			@objectClass = oc
			oc.must do |attrtype|
				attr_accessor attrtype.name
			end
			oc.may do |attrtype|
				attr_accessor attrtype.name
			end
		end
	end

	return classobj
end

def fetch_structural_objectclass( oc )
	unless classobj = @structural[ oc.oid ]
		parent = fetch_objectclass( oc.sup )
		$stderr.puts "Creating structural objectClass %s (%s)" % [ oc.name, oc.oid ]
		classobj = @structural[ oc.oid ] = Class.new( parent ) do
			@objectClass = oc
			oc.must do |attrtype|
				attr_accessor attrtype.name
			end
			oc.may do |attrtype|
				attr_accessor attrtype.name
			end
		end
	end

	return classobj
end

def fetch_auxiliary_objectclass( oc )
	unless mod = @auxiliary[ oc.oid ]
		$stderr.puts "Creating auxiliary objectClass %s (%s)" % [ oc.name, oc.oid ]
		mod = @auxiliary[ oc.oid ] = Module.new do
			@objectClass = oc
			oc.must do |attrtype|
				attr_accessor attrtype.name
			end
			oc.may do |attrtype|
				attr_accessor attrtype.name
			end
		end
	end

	return mod
end


objectclasses = dir.schema.object_classes.values.uniq.inject({}) do |hash, oc|
	hash[oc.name] = fetch_objectclass( oc )
	hash
end


pp objectclasses


