#!ruby

require 'treequel'
#require 'treequel/model'

class Treequel::Model

	@branchset = nil
	class << self; attr_accessor :branchset; end

	def self::inherited( mod )
		mod.instance_variable_set( :@branchset, nil )
		super
	end

	def self::model_branchset( bs )
		if bs
			bs = bs.branchset if bs.respond_to?( :branchset )
			self.branchset = bs
		end

		return self.branchset
	end
end


# This is an experiment to see how LDAP entries can be mapped into
# Ruby object-space. Since LDAP has a freeform, class+mixin-based
# object model of its own, it should map pretty easily into Ruby-land,
# but it can't work like ActiveRecord or something that depends on
# objects mapping fairly one-to-one with rows in a database. This is
# an attempt to model it more faithfully to LDAP's principles.

class Employee < Treequel::Model
	model_branchset DIR.ou( :people ).filter( :objectClass => 'posixAccount' )

	def_branchset_method( :active ) do
		self.filter( :activated <= Time.now, :deactivated >= Time.now )
	end

end


