#!/usr/bin/env ruby

BEGIN {
	require 'pathname'
	basedir = Pathname.new( __FILE__ ).dirname.parent.parent
	
	libdir = basedir + "lib"
	
	$LOAD_PATH.unshift( libdir ) unless $LOAD_PATH.include?( libdir )
}

begin
	require 'spec'
	require 'spec/lib/constants'
	require 'spec/lib/helpers'

	require 'treequel/branch'
rescue LoadError
	unless Object.const_defined?( :Gem )
		require 'rubygems'
		retry
	end
	raise
end


include Treequel::TestConstants
include Treequel::Constants

#####################################################################
###	C O N T E X T S
#####################################################################

describe Treequel::Branch do
	include Treequel::SpecHelpers
	
	before( :all ) do
		setup_logging( :fatal )
	end
	
	after( :all ) do
		reset_logging()
	end

	before( :each ) do
		@directory = mock( "treequel directory" )
	end
	

	it "can be constructed from a DN" # do
	# 		branch = Treequel::Branch.new_from_dn( TEST_PEOPLE_DN, @directory )
	# 		branch.dn.should == TEST_PEOPLE_DN
	# 	end
	
end


# vim: set nosta noet ts=4 sw=4:
