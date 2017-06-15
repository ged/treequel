#!/usr/bin/env ruby

#
# Experimenting with the 'Content Sync' control
#

require 'rubygems'

require 'logger'
require 'treequel'
require 'treequel/controls/contentsync'

Treequel.logger.level = Logger::DEBUG

dir = Treequel.directory
dir.register_controls( Treequel::ContentSyncControl )

sync_branchset = dir.filter( :objectClass ).on_sync do |*args|
	pp args
end

sync_branchset.all


