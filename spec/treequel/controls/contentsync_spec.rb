#!/usr/bin/env ruby

require_relative '../../spec_helpers'

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
