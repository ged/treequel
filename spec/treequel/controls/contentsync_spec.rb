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
require 'spec/lib/control_behavior'

require 'treequel'
require 'treequel/controls/contentsync'

include Treequel::TestConstants
include Treequel::Constants

#####################################################################
###	C O N T E X T S
#####################################################################
describe Treequel::ContentSyncControl do
	include Treequel::SpecHelpers

	before( :each ) do
		# Used by the shared behavior
		@control = Treequel::ContentSyncControl
	end

	it_should_behave_like "A Treequel::Control"

end

# vim: set nosta noet ts=4 sw=4:
