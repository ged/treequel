#!ruby

# This is an experiment to see how LDAP entries can be mapped into
# Ruby object-space. Since LDAP has a freeform, class+mixin-based
# object model of its own, it should map pretty easily into Ruby-land,
# but it can't work like ActiveRecord or something that depends on
# objects mapping fairly one-to-one with rows in a database. This is
# an attempt to model it more faithfully to LDAP's principles.

require 'treequel'
#require 'treequel/model'

DIR = Treequel.directory


class Treequel::Model < Treequel::Branch

	@branchset = nil
	@base = nil
	class << self
		attr_accessor :branchset, :base
	end

	def self::inherited( mod )
		mod.instance_variable_set( :@branchset, nil )
		super
	end

	def self::model_branchset( bs )
		return self.branchset
	end

	def self::all
		self.branchset.all
	end


	def self::new_from_entry( entry, directory )
		dn = entry['dn']
		rdn, base = dn.first.split( /,/, 2 )

		return self.new( directory, rdn, base, entry )
	end

	def initialize( directory, rdn )
		
	end
end


class Employee < Treequel::Model
	model_branchset DIR.ou( :people ).filter( :objectClass => :acmeAccount )

	model_objectClasses :acmeAccount, :inetOrgPerson
end


