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

	require 'treequel/filter'
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

describe Treequel::Filter do
	include Treequel::SpecHelpers
	
	before( :all ) do
		setup_logging( :fatal )
	end

	after( :all ) do
		reset_logging()
	end


	it "can be created from a string literal" do
		pending do
			Treequel::Filter.new( '(uid=bargrab)' ).to_s.should == '(uid=bargrab)'
		end
	end

	it "wraps string literal instances in parens if it requires them" do
		pending do
			Treequel::Filter.new( 'uid=bargrab' ).to_s.should == '(uid=bargrab)'
		end
	end

	it "defaults to selecting everything" do
		pending do
			Treequel::Filter.new.to_s.should == '(objectClass=*)'
		end
	end

	it "parses a single Symbol argument as a presence filter" do
		Treequel::Filter.new( :uid ).to_s.should == '(uid=*)'
	end

	it "parses a single-element Array with a Symbol as a presence filter" do
		Treequel::Filter.new( [:uid] ).to_s.should == '(uid=*)'
	end

	it "parses a Symbol+value pair as a simple item equal filter" do
		Treequel::Filter.new( :uid, 'bigthung' ).to_s.should == '(uid=bigthung)'
	end
	
	it "parses a Symbol+value pair in an Array as a simple item equal filter" do
		Treequel::Filter.new( [:uid, 'bigthung'] ).to_s.should == '(uid=bigthung)'
	end
	
end


# vim: set nosta noet ts=4 sw=4:
