#!/usr/bin/ruby
# coding: utf-8

BEGIN {
	require 'pathname'
	basedir = Pathname.new( __FILE__ ).dirname.parent

	libdir = basedir + "lib"

	$LOAD_PATH.unshift( libdir.to_s ) unless $LOAD_PATH.include?( libdir.to_s )
}

require 'rspec'

require 'treequel'

require 'spec/lib/constants'
require 'spec/lib/matchers'


### RSpec helper functions.
module Treequel::SpecHelpers
	include Treequel::TestConstants

	class ArrayLogger
		### Create a new ArrayLogger that will append content to +array+.
		def initialize( array )
			@array = array
		end

		### Write the specified +message+ to the array.
		def write( message )
			@array << message
		end

		### No-op -- this is here just so Logger doesn't complain
		def close; end

	end # class ArrayLogger


	unless defined?( LEVEL )
		LEVEL = {
			:debug => Logger::DEBUG,
			:info  => Logger::INFO,
			:warn  => Logger::WARN,
			:error => Logger::ERROR,
			:fatal => Logger::FATAL,
		  }
	end

	###############
	module_function
	###############

	### Make an easily-comparable version vector out of +ver+ and return it.
	def vvec( ver )
		return ver.split('.').collect {|char| char.to_i }.pack('N*')
	end


	### Reset the logging subsystem to its default state.
	def reset_logging
		Treequel.reset_logger
	end


	### Alter the output of the default log formatter to be pretty in SpecMate output
	def setup_logging( level=Logger::FATAL )

		# Turn symbol-style level config into Logger's expected Fixnum level
		if Treequel::LOG_LEVELS.key?( level.to_s )
			level = Treequel::LOG_LEVELS[ level.to_s ]
		end

		logger = Logger.new( $stderr )
		Treequel.logger = logger
		Treequel.logger.level = level

		# Only do this when executing from a spec in TextMate
		if ENV['HTML_LOGGING'] || (ENV['TM_FILENAME'] && ENV['TM_FILENAME'] =~ /_spec\.rb/)
			Thread.current['logger-output'] = []
			logdevice = ArrayLogger.new( Thread.current['logger-output'] )
			Treequel.logger = Logger.new( logdevice )
			# Treequel.logger.level = level
			Treequel.logger.formatter = Treequel::HtmlLogFormatter.new( logger )
		end
	end


	### Make a Treequel::Directory that will use the given +conn+ object as its
	### LDAP connection. Also pre-loads the schema object and fixtures some other
	### external data.
	def get_fixtured_directory( conn )
		LDAP::SSLConn.stub( :new ).and_return( @conn )
		conn.stub( :search_ext2 ).
			with( "", 0, "(objectClass=*)", ["+"], false, nil, nil, 0, 0, 0, "", nil ).
			and_return( TEST_DSE )
		conn.stub( :set_option )

		# Avoid parsing the whole schema with every example
		directory = Treequel.directory( TEST_LDAPURI )
		directory.stub( :schema ).and_return( SCHEMA )

		return directory
	end

	### Shorthand method for creating LDAP::Mod DELETE objects 
	def ldap_mod_delete( attribute, *values )
		return LDAP::Mod.new( LDAP::LDAP_MOD_DELETE, attribute.to_s, values.flatten )
	end


	### Shorthand method for creating LDAP::Mod REPLACE objects 
	def ldap_mod_replace( attribute, *values )
		return LDAP::Mod.new( LDAP::LDAP_MOD_REPLACE, attribute.to_s, values.flatten )
	end


	### Shorthand method for creating LDAP::Mod ADD objects 
	def ldap_mod_add( attribute, *values )
		return LDAP::Mod.new( LDAP::LDAP_MOD_ADD, attribute.to_s, values.flatten )
	end


end


### Mock with Rspec
Rspec.configure do |c|
	c.mock_with :rspec

	c.extend( Treequel::TestConstants )

	c.include( Treequel::TestConstants )
	c.include( Treequel::SpecHelpers )
	c.include( Treequel::Matchers )

	c.filter_run_excluding( :ruby_1_8_only => true ) if
		Treequel::SpecHelpers.vvec( RUBY_VERSION ) >= Treequel::SpecHelpers.vvec('1.9.1')
end

# vim: set nosta noet ts=4 sw=4:

