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
describe "A Treequel::Control", :shared => true do
	include Treequel::SpecHelpers

	before( :each ) do
		raise "Spec doesn't set @control before the Control shared behavior" unless @control

		@object = Object.new
		@object.extend( @control )
	end

	it "implements one of either #get_client_controls or #get_server_controls" do
		methods = [
			'get_client_controls',		# 1.8.x
			'get_server_controls',
			:get_client_controls,		# 1.9.x
			:get_server_controls
		]
		(@control.instance_methods( false ) | methods).should_not be_empty()
	end

end


