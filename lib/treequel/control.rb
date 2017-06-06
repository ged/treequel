#!/usr/bin/env ruby
require 'ldap'
require 'ldap/control'

require 'treequel'


# Virtual interface methods for Control modules.
#
# == Subclassing
# To make a concrete derivative, include this module in a module that
# implements either #get_client_controls or #get_server_controls and #each. 
# Your implementation of #each should +super+ with a block that does the 
# necessary extraction of the result controls and yields back to the original
# block.
# 
# == Examples
#
#   module Treequel::MyControl
#       include Treequel::Control
#   
#       # The control's OID
#       OID = '1.3.6.1.4.1.984454.16.1'
#   
#       # If your control has some value associated with it, you can provide
#       # an initializer to set up an instance variable or two.
#       def initialize
#           @my_control_value = 18
#       end
#   
#       attr_accessor :my_control_value
#   
#       # This is the interface users will use to set values used in the control,
#       # like so:
#       #   branchset.controlled_somehow( value )
#       def controlled_somehow( value )
#           self.my_control_value = value
#       end
#   
#       # This is overridden so you can fetch controls set by the server before
#       # iterating. The #each in Treequel::Branchset will yield to this block
#       # after performing a search.
#       def each( &block )
#           super do |branch|
#               if my_control = branch.controls.find {|control| control.oid == OID }
#                   server_control_value = my_control.decode
#                   # ... do something with the returned server_control_value
#               end
#   
#               block.call( branch )
#           end
#       end
#   
#       # This is how you inject your control into the search; Treequel::Branchset
#       # will call this before running the search and add the results to its
#       # server_controls. If you're implementing a client control, override
#       # the #get_client_controls method instead. Be sure to super() so that any
#       # controls registered before yours have a chance to add their objects too.
#       def get_server_controls
#           controls = super
#           if self.my_control_value
#               value = LDAP::Control.encode( self.my_control_value )
#               controls << LDAP::Control.new( OID, value, true )
#           end
#   
#           return controls
#       end
#   
#   end
# 
module Treequel::Control

	### Control API interface method.
	###
	### If your control is a client control, you should super() to this method
	### and add your control (in the form of an LDAP::Control object) to the
	### resulting Array before returning it.
	def get_client_controls
		return []
	end


	### Control API interface method.
	###
	### If your control is a server control, you should super() to this method
	### and add your control (in the form of an LDAP::Control object) to the
	### resulting Array before returning it.
	def get_server_controls
		return []
	end

end # module Treequel::Control

# vim: set nosta noet ts=4 sw=4:


