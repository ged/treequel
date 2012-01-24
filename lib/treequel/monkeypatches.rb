#!/usr/bin/env ruby

require 'date'

require 'diff/lcs'
require 'diff/lcs/change'

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
class LDAP::Control
	include Treequel::LDAPControlExtensions
end


### Extensions to LDAP::Mods to make them grok ==.
module Treequel::LDAPModExtensions

	### Returns +true+ if the +other+ LDAP::Record is equivalent to the receiver.
	def ==( other )
		return ( other.class == self.class ) &&
			( self.mod_op == other.mod_op ) &&
			( self.mod_type == other.mod_type ) &&
			( self.mod_vals == other.mod_vals )
	end

end # module Treequel::LDAPModExtensions


# Include Treequel-specific extensions as a mixin.
class LDAP::Mod
	include Treequel::LDAPModExtensions

	# The following is a nasty hack to work around memory-corruption issues in
	# LDAP::Mod. The RSTRING_PTR of the second argument to LDAP::Mod#initialize 
	# is used without strdup()ing it, which means if the String object that was
	# passed to it is garbage-collected, the attribute name of the Mod object
	# gets corrupted. This hack works around that by storing the String as an
	# instance variable of the Mod object, ensuring it doesn't get collected
	# until the Mod object itself does. Ick.

	# Turn off warnings, alias away the C initialize, then restore the verbose
	# level to what it was before
	begin
		oldwarnlvl = $VERBOSE
		$VERBOSE = nil
		alias :_initialize_ext :initialize
		remove_method :initialize
	ensure
		$VERBOSE = oldwarnlvl
	end

	### Override the initializer to keep the +attribute+ around while the object
	### is alive to prevent the underlying C String pointer from going away.
	###
	### See line 151 of mod.c.
	def initialize( op, attribute, vals=[] )
		@attribute = attribute
		_initialize_ext( op, attribute, vals )
	end

end # class LDAP::Mod


### Extensions to the Time class to add LDAP (RFC4517) Generalized Time syntax
module Treequel::TimeExtensions

	### Return +self+ as a String formatted as specified in RFC4517 
	### (LDAP Generalized Time).
	def ldap_generalized( fraction_digits=0 )
		fractional_seconds =
			if fraction_digits == 0
				''
			elsif fraction_digits <= 6
				'.' + sprintf('%06d', self.usec)[0, fraction_digits]
			else
				'.' + sprintf('%06d', self.usec) + '0' * (fraction_digits - 6)
			end
		tz =
			if self.utc?
				'Z'
			else
				off  = self.utc_offset
				sign = off < 0 ? '-' : '+'
				"%s%02d%02d" % [ sign, *(off.abs / 60).divmod(60) ]
			end

		return "%02d%02d%02d%02d%02d%02d%s%s" % [
			self.year,
			self.mon,
			self.day,
			self.hour,
			self.min,
			self.sec,
			fractional_seconds,
			tz
		]

	end

	### Returns +self+ as a String formatted as specified in RFC4517
	### (UTC Time)
	def ldap_utc
		tz =
			if self.utc?
				'Z'
			else
				off  = self.utc_offset
				sign = off < 0 ? '-' : '+'
				"%s%02d%02d" % [ sign, *(off.abs / 60).divmod(60) ]
			end

		return "%02d%02d%02d%02d%02d%02d%s" % [
			self.year.divmod(100).last,
			self.mon,
			self.day,
			self.hour,
			self.min,
			self.sec,
			tz
		]
	end

end # module Treequel::TimeExtensions

class Time
	include Treequel::TimeExtensions
end


### Extensions to the Date class to add LDAP (RFC4517) Generalized Time syntax
module Treequel::DateExtensions

	### Return +self+ as a String formatted as specified in RFC4517 
	### (LDAP Generalized Time).
	def ldap_generalized( fraction_digits=0 )
		fractional_seconds =
			if fraction_digits == 0
				''
			else
				'.' + ('0' * fraction_digits)
			end

		off  = Time.now.utc_offset
		sign = off < 0 ? '-' : '+'
		tz   = "%s%02d%02d" % [ sign, *(off.abs / 60).divmod(60) ]

		return "%02d%02d%02d%02d%02d%02d%s%s" % [
			self.year,
			self.mon,
			self.day,
			0,
			0,
			1,
			fractional_seconds,
			tz
		]

	end

	### Returns +self+ as a String formatted as specified in RFC4517
	### (UTC Time)
	def ldap_utc
		off  = Time.now.utc_offset
		sign = off < 0 ? '-' : '+'
		tz   = "%s%02d%02d" % [ sign, *(off.abs / 60).divmod(60) ]

		return "%02d%02d%02d%02d%02d%02d%s" % [
			self.year.divmod(100).last,
			self.mon,
			self.day,
			0,
			0,
			1,
			tz
		]
	end

end # module Treequel::TimeExtensions

class Date
	include Treequel::DateExtensions
end

