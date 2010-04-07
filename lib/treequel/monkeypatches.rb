#!/usr/bin/env ruby

require 'ldap'
require 'ldap/control'

require 'treequel'

### Extensions to LDAP::Control to make them grok ==.
module Treequel::LDAPControlExtensions

	### Returns +true+ if the +other+ LDAP::Control is equivalent to the receiver.
	def ==( other )
		return ( other.class == self.class ) &&
			other.oid == self.oid &&
			other.value == self.value &&
			other.iscritical == self.iscritical
	end

end # module Treequel::LDAPControlExtensions


# Include Treequel-specific extensions as a mixin.
# @private
class LDAP::Control
	include Treequel::LDAPControlExtensions
end



