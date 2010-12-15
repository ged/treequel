#!/usr/bin/env ruby

BEGIN {
	require 'pathname'
	basedir = Pathname.new( __FILE__ ).dirname.parent.parent.parent

	libdir = basedir + "lib"

	$LOAD_PATH.unshift( basedir ) unless $LOAD_PATH.include?( basedir )
	$LOAD_PATH.unshift( libdir ) unless $LOAD_PATH.include?( libdir )
}

require 'rspec'

require 'spec/lib/helpers'

require 'treequel'
require 'treequel/behavior/control'
require 'treequel/controls/contentsync'


#####################################################################
###	C O N T E X T S
#####################################################################
describe Treequel::ContentSyncControl do

	it_should_behave_like "A Treequel::Control"

end

# vim: set nosta noet ts=4 sw=4:
