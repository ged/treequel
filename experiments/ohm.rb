#!ruby

require 'treequel/model'

# This is an experiment to see how LDAP entries can be mapped into
# Ruby object-space. Since LDAP has a freeform, class+mixin-based
# object model of its own, it should map pretty easily into Ruby-land,
# but it can't work like ActiveRecord or something that depends on
# objects mapping fairly one-to-one with rows in a database. This is
# an attempt to model it more faithfully to LDAP's principles.

class Employee < Treequel::Model
	model_base DIR.ou( :people ) +
		DIR.dc( :ny ).ou( :people ) +
		DIR.dc( :la ).ou( :people )

	model_filter :objectClass => 'posixAccount'

	def_branchset_method( :active ) do
		self.filter([ :and [:activated >= Time.today, :deactivated <= Time.today] ])
	end

end


