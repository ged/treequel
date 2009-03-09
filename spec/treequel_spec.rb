#!/usr/bin/env ruby

BEGIN {
	require 'pathname'
	basedir = Pathname.new( __FILE__ ).dirname.parent
	
	libdir = basedir + "lib"
	
	$LOAD_PATH.unshift( libdir ) unless $LOAD_PATH.include?( libdir )
}

begin
	require 'spec'
	require 'spec/lib/constants'
	require 'spec/lib/helpers'

	require 'treequel'
rescue LoadError
	unless Object.const_defined?( :Gem )
		require 'rubygems'
		retry
	end
	raise
end


include Treequel::TestConstants
# include Treequel::Constants

#####################################################################
###	C O N T E X T S
#####################################################################

describe Treequel do
	include Treequel::SpecHelpers

	before( :all ) do
		reset_logging()
	end

	it "should know if its default logger is replaced" do
		Treequel.reset_logger
		Treequel.should be_using_default_logger
		Treequel.logger = Logger.new( $stderr )
		Treequel.should_not be_using_default_logger
	end


	it "returns a version string if asked" do
		Treequel.version_string.should =~ /\w+ [\d.]+/
	end


	it "returns a version string with a build number if asked" do
		Treequel.version_string(true).should =~ /\w+ [\d.]+ \(build \d+\)/
	end
	

	describe " logging subsystem" do
		before(:each) do
			Treequel.reset_logger
		end

		after(:each) do
			Treequel.reset_logger
		end
	
	
		it "has the default logger instance after being reset" do
			Treequel.logger.should equal( Treequel.default_logger )
		end

		it "has the default log formatter instance after being reset" do
			Treequel.logger.formatter.should equal( Treequel.default_log_formatter )
		end
	
	end


	describe " logging subsystem with new defaults" do
		before( :all ) do
			@original_logger = Treequel.default_logger
			@original_log_formatter = Treequel.default_log_formatter
		end

		after( :all ) do
			Treequel.default_logger = @original_logger
			Treequel.default_log_formatter = @original_log_formatter
		end


		it "uses the new defaults when the logging subsystem is reset" do
			logger = mock( "dummy logger", :null_object => true )
			formatter = mock( "dummy logger" )
			
			Treequel.default_logger = logger
			Treequel.default_log_formatter = formatter

			logger.should_receive( :formatter= ).with( formatter )

			Treequel.reset_logger
			Treequel.logger.should equal( logger )
		end
		
	end

end

# vim: set nosta noet ts=4 sw=4:
