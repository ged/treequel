#!/usr/bin/ruby

require 'ldap'
require 'ldap/control'

require 'treequel'


### Virtual interface methods for Control modules.
module Treequel::Control

	### Control API interface method
	###
	### If your control is a client control, you should super() to this method
	### and add your control (in the form of an LDAP::Control object) to the
	### resulting Array before returning it.
	def get_client_controls
		return []
	end


	### Control API interface method
	###
	### If your control is a server control, you should super() to this method
	### and add your control (in the form of an LDAP::Control object) to the
	### resulting Array before returning it.
	def get_server_controls
		return []
	end

end # module Treequel::Control

# vim: set nosta noet ts=4 sw=4:


