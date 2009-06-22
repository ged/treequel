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

	require 'treequel/connection'
rescue LoadError
	unless Object.const_defined?( :Gem )
		require 'rubygems'
		retry
	end
	raise
end


include Treequel::TestConstants

#####################################################################
###	C O N T E X T S
#####################################################################

describe Treequel::Connection do
	include Treequel::SpecHelpers

	before( :all ) do
		setup_logging( :fatal )
	end

	after( :all ) do
		reset_logging()
	end


	before( :each ) do
		@options = {
			:host         => TEST_HOST,
			:port         => TEST_PORT,
			:base         => TEST_BASE_DN,
			:connect_type => :plain,
		}
	end


	it "delegates methods to an underlying connection object"
	it "re-raises plain RuntimeErrors raised during delegated calls as more-interesting " +
	   "exception types"
	it "attempts to re-establish its connection if the current one indicates it's no longer valid"
	it "stops trying to re-establish a connection if it's tried too many times within a certain " +
	   "time period"

	it "connects to the referred server and-reruns any method that raises a Referral"
	it ""

end


# vim: set nosta noet ts=4 sw=4:
