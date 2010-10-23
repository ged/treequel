#!/usr/bin/ruby
# coding: utf-8

BEGIN {
	require 'pathname'
	basedir = Pathname.new( __FILE__ ).dirname.parent

	libdir = basedir + "lib"

	$LOAD_PATH.unshift( libdir.to_s ) unless $LOAD_PATH.include?( libdir.to_s )
}

require 'rspec'

require 'yaml'
require 'treequel'

require 'spec/lib/constants'

### RSpec matchers
module Treequel::Matchers

	class ArrayIncludingMatcher
		def initialize( expected )
			@expected = expected
		end

		def ==( actual )
			@expected.each do |value|
				return false unless actual.include?( value )
			end
			true
		rescue NoMethodError => ex
			return false
		end

		def description
			"array_including(#{ @expected.inspect.sub(/^\[|\]$/,"") })"
		end
	end


	###############
	module_function
	###############

	### Return true if the actual value includes the specified +objects+.
	def array_including( *objects )
		ArrayIncludingMatcher.new( objects )
	end


end # module Treequel::Matchers

