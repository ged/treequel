#!/usr/bin/ruby -*- ruby -*-

require 'irb/ext/save-history'

BEGIN {
	require 'pathname'
	basedir = Pathname.new( __FILE__ ).dirname.expand_path
	libdir = basedir + "lib"

	puts ">>> Adding #{libdir} to load path..."
	$LOAD_PATH.unshift( libdir.to_s )
}


# Try to require the 'thingfish' library
begin
	$stderr.puts "Loading Treequel..."
	require 'treequel'
rescue => e
	$stderr.puts "Ack! Treequel library failed to load: #{e.message}\n\t" +
		e.backtrace.join( "\n\t" )
end

$deferr.puts "Turning on history..."
IRB.conf[:SAVE_HISTORY] = 100_000
IRB.conf[:HISTORY_FILE] = "~/.irb.hist"

