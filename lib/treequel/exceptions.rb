#!/usr/bin/env ruby

require 'treequel'


# A collection of exceptions for Treequel.
# 
# == Authors
# 
# * Michael Granger <ged@FaerieMUD.org>
# 
# :include: LICENSE
#
#--
#
# Please see the file LICENSE in the base directory for licensing details.
#
module Treequel

	### The base Treequel exception type
	class Error < ::RuntimeError; end

	### Schema parsing errors
	class ParseError < Treequel::Error; end

	### Exception type raised when an expression cannot be parsed from the
	### arguments given to Treequel::Filter.new
	class ExpressionError < Treequel::Error; end

	### Exception type for a requested Control type that is nonexistent or
	### unsupoorted on the current server.
	class UnsupportedControl < Treequel::Error; end

end # module Treequel


