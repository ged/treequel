#!/usr/bin/env ruby

# This is a test of the schema-parsing and regeneration code. It
# connects to an LDAP server, loads its schema, then for each artifact
# it compares the generated output with the original source.
#
# It's not really expected that every schema entry will be identical,
# but they should be pretty close.

require 'rubygems'
require 'treequel'

ARTIFACT_TYPES = %w[
	attributeTypes
	ldapSyntaxes
	matchingRuleUse
	matchingRules
	objectClasses
]

$dir = if ARGV.empty?
	Treequel.directory_from_config
else
	Treequel.directory( ARGV.shift )
end


def print_report( count, mismatches )
	$stderr.puts "%d/%d matched." % [ count - mismatches.length, count ]
	mismatches.each do |mm|
		$stderr.puts '', "*** %s: Mismatch: \n  %s\n  %s" % mm
	end
end

def check_artifact( artifact_type )
	counter       = 0
	mismatches    = []
	treequel_type = artifact_type.gsub( /([a-z])([A-Z])/ ) { $1 + '_' + $2.downcase }
	artifacts     = $dir.schema.send( treequel_type ) or
		raise "no such artifact type %p" % [ treequel_type ]

	$stderr.print "Checking %s..." % [artifact_type]
	$dir.conn.schema[ artifact_type ].sort.each do |desc|
		counter += 1
		oid = desc[ /\(\s*(\S+)/, 1 ]
		artifact = artifacts[ oid ]

		if artifact.to_s != desc
			mismatches << [ oid, desc, artifact.to_s ]
			$stderr.print 'x'
		else
			$stderr.print '.'
		end
	end

	return counter, mismatches
end

$stderr.puts "Testing schema roundtrip against %s" % [ $dir.uri ]

ARTIFACT_TYPES.each do |artifact_type|
	count, mismatches = check_artifact( artifact_type )
	print_report( count, mismatches )
end

