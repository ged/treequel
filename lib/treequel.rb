#!/usr/bin/env ruby

require 'ldap'
require 'ldap/schema'
require 'ldap/control'

require 'logger'

require 'uri'
require 'uri/ldap'


### Add an LDAPS URI type if none exists (ruby pre 1.8.7)
unless URI.const_defined?( :LDAPS )
	module URI
		class LDAPS < LDAP
			DEFAULT_PORT = 636
		end
		@@schemes['LDAPS'] = LDAPS
	end
end


# A library for interacting with LDAP modelled after Sequel.
#
# == Authors
#
# * Michael Granger <ged@FaerieMUD.org>
# * Mahlon E. Smith <mahlon@martini.nu>
#
# :include: LICENSE
#
#--
#
# Please see the file LICENSE in the base directory for licensing details.
#
module Treequel

	# Library version
	VERSION = '1.0.1'

	# VCS revision
	REVISION = %q$rev$

	# Load the logformatters and some other stuff first
	require 'treequel/constants'
	require 'treequel/utils'

	include Treequel::Constants


	### Logging
	@default_logger = Logger.new( $stderr )
	@default_logger.level = $DEBUG ? Logger::DEBUG : Logger::WARN

	@default_log_formatter = Treequel::LogFormatter.new( @default_logger )
	@default_logger.formatter = @default_log_formatter

	@logger = @default_logger


	class << self
		# The log formatter that will be used when the logging subsystem is reset
		attr_accessor :default_log_formatter

		# The logger that will be used when the logging subsystem is reset
		attr_accessor :default_logger

		# The logger that's currently in effect
		attr_accessor :logger
		alias_method :log, :logger
		alias_method :log=, :logger=
	end


	### Reset the global logger object to the default
	def self::reset_logger
		self.logger = self.default_logger
		self.logger.level = Logger::WARN
		self.logger.formatter = self.default_log_formatter
	end


	### Returns +true+ if the global logger has not been set to something other than
	### the default one.
	def self::using_default_logger?
		return self.logger == self.default_logger
	end


	### Return the library's version string
	def self::version_string( include_buildnum=false )
		vstring = "%s %s" % [ self.name, VERSION ]
		vstring << " (build %s)" % [ REVISION ] if include_buildnum
		return vstring
	end

	### Create a Treequel::Directory object, either from a Hash of options or an LDAP URL.
	def self::directory( *args )
		options = {}

		args.each do |arg|
			case arg
			when String, URI
				options.merge!( self.make_options_from_uri(arg) )
			when Hash
				options.merge!( arg )
			else
				raise ArgumentError, "unknown directory option %p: expected URL or Hash" % [ arg ]
			end
		end

		return Treequel::Directory.new( options )
	end


	### Make an options hash suitable for passing to Treequel::Directory.new from the
	### given +uri+.
	def self::make_options_from_uri( uri )
		uri = URI( uri ) unless uri.is_a?( URI )
		raise ArgumentError, "not an LDAP URL: %p" % [ uri ] unless
			uri.scheme =~ /ldaps?/
		options = {}

		if uri.port
			options[:port] = uri.port
		elsif uri.scheme == 'ldaps'
			options[:port] = LDAP::LDAPS_PORT
		end

		options[:connect_type] = :ssl if uri.scheme == 'ldaps'

		options[:host]    = uri.host if uri.host
		options[:base_dn] = uri.dn unless uri.dn.nil? || uri.dn.empty?
		options[:bind_dn] = uri.user if uri.user
		options[:pass]    = uri.password if uri.password

		return options
	end

	# Now load the rest of the library
	require 'treequel/exceptions'
	require 'treequel/directory'
	require 'treequel/branch'
	require 'treequel/branchset'
	require 'treequel/filter'

end # module Treequel


