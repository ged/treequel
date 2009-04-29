#!/usr/bin/ruby

BEGIN {
	require 'pathname'
	basedir = Pathname.new( __FILE__ ).dirname.parent

	libdir = basedir + "lib"

	$LOAD_PATH.unshift( libdir.to_s ) unless $LOAD_PATH.include?( libdir.to_s )
}

begin
	require 'yaml'
	require 'treequel'
	
	require 'spec/lib/constants'
rescue LoadError
	unless Object.const_defined?( :Gem )
		require 'rubygems'
		retry
	end
	raise
end


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

	### Reset the logging subsystem to its default state.
	def reset_logging
		Treequel.reset_logger
	end
	
	
	### Alter the output of the default log formatter to be pretty in SpecMate output
	def setup_logging( level=Logger::FATAL )

		# Turn symbol-style level config into Logger's expected Fixnum level
		if Treequel::Loggable::LEVEL.key?( level )
			level = Treequel::Loggable::LEVEL[ level ]
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


	### Load the test config if it exists and return the specified +section+ of the config 
	### as a Hash. If the file doesn't exist, or the specified section doesn't exist, an
	### empty Hash will be returned.
	def get_test_config( section )
		return {} unless TESTING_CONFIG_FILE.exist?

		Treequel.logger.debug "Trying to load test config: %s" % [ TESTING_CONFIG_FILE ]
	
		begin
			config = YAML.load_file( TESTING_CONFIG_FILE )
			if config[ section ]
				Treequel.logger.debug "Loaded the config, returning the %p section: %p." %
					[ section, config[section] ]
				return config[ section ]
			else
				Treequel.logger.debug "No %p section in the config (%p)." % [ section, config ]
				return {}
			end
		rescue => err
			Treequel.logger.error "Test config failed to load: %s: %s: %s" %
				[ err.class.name, err.message, err.backtrace.first ]
			return {}
		end
	end
	
	
end


# vim: set nosta noet ts=4 sw=4:

