#!/usr/bin/env ruby

BEGIN {
	require 'pathname'
	basedir = Pathname.new( __FILE__ ).dirname.parent.parent

	libdir = basedir + "lib"

	$LOAD_PATH.unshift( libdir ) unless $LOAD_PATH.include?( libdir )
}

require 'spec'
require 'spec/lib/constants'
require 'spec/lib/helpers'

require 'treequel'
require 'treequel/control'

include Treequel::TestConstants
include Treequel::Constants

#####################################################################
###	C O N T E X T S
#####################################################################
module TestControl
	OID = 'an OID'
	include Treequel::Control
end

describe Treequel, "control" do
	include Treequel::SpecHelpers

	before( :each ) do
		@testclass = Class.new
		@obj = @testclass.new
		@obj.extend( TestControl )
	end

	it "provides a empty client control list by default" do
		@obj.get_client_controls.should == []
	end

	it "provides a empty server control list by default" do
		@obj.get_server_controls.should == []
	end
end

# vim: set nosta noet ts=4 sw=4:
