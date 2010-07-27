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


### Extensions to the Time class to add LDAP (RFC4517) Generalized Time syntax
module Treequel::TimeExtensions

	### Return +self+ as a String formatted as specified in RFC4517 
	### (LDAP Generalized Time).
	def ldap_generalized( fraction_digits=0 )
		fractional_seconds =
			if fraction_digits == 0
				''
			elsif fraction_digits <= 6
				'.' + sprintf('%06d', usec)[0, fraction_digits]
			else
				'.' + sprintf('%06d', usec) + '0' * (fraction_digits - 6)
			end
		tz =
			if utc?
				'Z'
			else
				off  = utc_offset
				sign = off < 0 ? '-' : '+'
				"%s%02d%02d" % [ sign, *(off.abs / 60).divmod(60) ]
			end

		return "%02d%02d%02d%02d%02d%02d%s%s" % [
			year,
			mon,
			day,
			hour,
			min,
			sec,
			fractional_seconds,
			tz
		]

	end

	### Returns +self+ as a String formatted as specified in RFC4517
	### (UTC Time)
	def ldap_utc
		tz =
			if utc?
				'Z'
			else
				off  = utc_offset
				sign = off < 0 ? '-' : '+'
				"%s%02d%02d" % [ sign, *(off.abs / 60).divmod(60) ]
			end

		return "%02d%02d%02d%02d%02d%02d%s" % [
			year.divmod(100).last,
			mon,
			day,
			hour,
			min,
			sec,
			tz
		]
	end

end # module Treequel::TimeExtensions

class Time
	include Treequel::TimeExtensions
end


