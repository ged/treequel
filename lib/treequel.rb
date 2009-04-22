#!/usr/bin/env ruby

require 'logger' 
require 'uri'
require 'uri/ldap'


### Add an LDAPS URI type
module URI
	class LDAPS < LDAP
		DEFAULT_PORT = 636
	end
	@@schemes['LDAPS'] = LDAPS
end


# A Sequel-like DSL for hierarchical datasets.
# 
# == Subversion Id
#
#  $Id$
# 
# == Authors
# 
# * Michael Granger <ged@FaerieMUD.org>
# 
# :include: LICENSE
#
#---
#
# Please see the file LICENSE in the base directory for licensing details.
#
module Treequel

	# SVN Revision
	SVNRev = %q$Rev$

	# SVN Id
	SVNId = %q$Id$

	# Library version
	VERSION = '0.0.1'

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
		vstring << " (build %d)" % [ SVNRev[/\d+/].to_i ] if include_buildnum
		return vstring
	end

	### Create a Treequel::Directory object by URI and return it.
	def self::directory( ldapurl )
		uri = URI.parse( ldapurl )
		raise ArgumentError, "malformed LDAP URL %p" % [ uri ] unless
			uri.scheme =~ /ldaps?/
		
		options = self.make_options_from_uri( uri )
		return Treequel::Directory.new( options )
	end

	
	### Make an options hash suitable for passing to Treequel::Directory.new from the
	### given +uri+.
	def self::make_options_from_uri( uri )
		uri = URI( uri ) unless uri.is_a?( URI )
		options = {}

		if uri.port
			options[:port] = uri.port
		elsif uri.scheme == 'ldaps'
			options[:port] = LDAP::LDAPS_PORT
		end

		options[:host] = uri.host if uri.host
		options[:base] = uri.dn if uri.dn

		return options
	end

	# Now load the rest of the library
	require 'treequel/directory'
	require 'treequel/branch'
	require 'treequel/branchset'
	require 'treequel/filter'
	
end # module Treequel


