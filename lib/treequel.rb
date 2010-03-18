#!/usr/bin/env ruby

require 'ldap'
require 'ldap/schema'
require 'ldap/control'

require 'logger'
require 'pathname'

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
	VERSION = '1.0.3'

	# VCS revision
	REVISION = %q$Revision$

	# Common paths for ldap.conf
	COMMON_LDAP_CONF_PATHS = %w[
		./ldaprc
		~/.ldaprc
		~/ldaprc
		/etc/ldap/ldap.conf
		/etc/openldap/ldap.conf
		/etc/ldap.conf
		/usr/local/etc/openldap/ldap.conf
		/usr/local/etc/ldap.conf
		/opt/local/etc/openldap/ldap.conf
		/opt/local/etc/ldap.conf
	]

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
		vstring << " (build %s)" % [ REVISION[/: ([[:xdigit:]]+)/, 1] || '0' ] if include_buildnum
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


	### Read the configuration from the specified +configfile+ and/or values in ENV and return 
	### a Treequel::Directory for the resulting configuration. Supports OpenLDAP and nss-style 
	### configuration-file directives, and honors the various OpenLDAP environment variables; 
	### see ldap.conf(5) for details.
	def self::directory_from_config( configfile=nil )
		configfile ||= self.find_configfile or
			raise ArgumentError, "No configfile specified, and no defaults present."

		# Read options from ENV and the config file
		fileopts    = self.read_opts_from_config( configfile )
		envopts     = self.read_opts_from_environment

		# Now merge all the options together with env > file > default
		options = Treequel::Directory::DEFAULT_OPTIONS.merge( fileopts.merge(envopts) )

		return Treequel::Directory.new( options )
	end


	### Make an options hash suitable for passing to Treequel::Directory.new from the
	### given +uri+.
	def self::make_options_from_uri( uri )
		uri = URI( uri ) unless uri.is_a?( URI )
		raise ArgumentError, "not an LDAP URL: %p" % [ uri ] unless
			uri.scheme =~ /ldaps?/
		options = {}

		# Use either the scheme or the port from the URI to set the port
		if uri.port
			options[:port] = uri.port
		elsif uri.scheme == 'ldaps'
			options[:port] = LDAP::LDAPS_PORT
		end

		# Set the connection type if the scheme dictates it
		options[:connect_type] = :ssl if uri.scheme == 'ldaps'

		options[:host]    = uri.host if uri.host
		options[:base_dn] = uri.dn unless uri.dn.nil? || uri.dn.empty?
		options[:bind_dn] = uri.user if uri.user
		options[:pass]    = uri.password if uri.password

		return options
	end


	### Find a valid ldap.conf config file by first looking in the LDAPCONF and LDAPRC environment 
	### variables, then searching the defaults in 
	def self::find_configfile
		# LDAPCONF may be set to the path of a configuration file. This path can
		# be absolute or relative to the current working directory.
		if configfile = ENV['LDAPCONF']
			Treequel.log.info "Using LDAPCONF environment variable for path to ldap.conf"
			configpath = Pathname( configfile ).expand_path
			raise "Config file #{configfile}, specified in the LDAPCONF environment variable, " +
				"does not exist or isn't readable." unless configpath.readable?
			return configpath

		# The LDAPRC, if defined, should be the basename of a file in the current working 
		# directory or in the user's home directory.
		elsif rcname = ENV['LDAPRC']
			Treequel.log.info "Using LDAPRC environment variable for path to ldap.conf"
			rcpath = Pathname( rcname ).expand_path
			return rcpath if rcpath.readable?
			rcpath = Pathname( "~" ).expand_path + rcname
			return rcpath if rcpath.readable?

			raise "Config file '#{rcname}', specified in the LDAPRC environment variable, does not " +
				"exist or isn't readable."
		else
			Treequel.log.info "Searching common paths for ldap.conf"
			return COMMON_LDAP_CONF_PATHS.collect {|path| Pathname(path) }.
				find {|path| path.readable? }
		end
	end


	### Read the ldap.conf-style configuration from +configfile+ and return it as a Hash.
	def self::read_opts_from_config( configfile )
		opts = {}

		File.readlines( configfile ) do |line|
			case line

			# URI <ldap[si]://[name[:port]] ...>
			# :TODO: Support multiple URIs somehow?
			when /^\s*URI\s+(\S+)/
				uriopts = self.make_options_from_uri( $1 )
				opts.merge!( uriopts )

			# BASE <base>
			when /^\s*BASE\s+(\S+)/
				opts[:base_dn] = $1

			# BINDDN <dn>
			when /^\s*BINDDN\s+(\S+)/
				opts[:bind_dn] = $1

			# HOST <name[:port] ...>
			when /^\s*HOST\s+(\S+)/
				opts[:host] = $1

			# PORT <port>
			when /^\s*PORT\s+(\S+)/
				opts[:port] = $1.to_i

			end
		end

		return opts
	end


	### Read OpenLDAP-style connection options from ENV and return them as a Hash.
	def self::read_opts_from_environment
		opts = {}

		opts.merge!( self.make_options_from_uri(ENV['LDAPURI']) ) if ENV['LDAPURI']
		opts[:host]    = ENV['LDAPHOST']      if ENV['LDAPHOST']
		opts[:port]    = ENV['LDAPPORT'].to_i if ENV['LDAPPORT']
		opts[:bind_dn] = ENV['LDAPBINDDN']    if ENV['LDAPBINDDN']
		opts[:base_dn] = ENV['LDAPBASE']      if ENV['LDAPBASE']

		return opts
	end


	# Now load the rest of the library
	require 'treequel/exceptions'
	require 'treequel/directory'
	require 'treequel/branch'
	require 'treequel/branchset'
	require 'treequel/filter'

end # module Treequel


