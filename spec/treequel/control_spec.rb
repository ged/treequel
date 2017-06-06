#!/usr/bin/env ruby

require_relative '../spec_helpers'


require 'treequel'
require 'treequel/control'

include Treequel::SpecConstants
include Treequel::Constants

#####################################################################
###	C O N T E X T S
#####################################################################
module TestControl
	OID = 'an OID'
	include Treequel::Control
end

describe Treequel::Control do
	include Treequel::SpecHelpers

	before( :each ) do
		@testclass = Class.new
		@obj = @testclass.new
		@obj.extend( TestControl )
	end

	it "provides a empty client control list by default" do
		expect( @obj.get_client_controls ).to eq( [] )
	end

	it "provides a empty server control list by default" do
		expect( @obj.get_server_controls ).to eq( [] )
	end
end

# vim: set nosta noet ts=4 sw=4:
