#!/usr/bin/env ruby

require 'treequel'


module Treequel

	### The base Treequel exception type
	class Error < ::RuntimeError; end

	### Schema parsing errors
	class ParseError < Treequel::Error; end

	### Exception type raised when an expression cannot be parsed from the
	### arguments given to Treequel::Filter.new
	class ExpressionError < Treequel::Error; end

	### Generic exception type for Controls.
	class ControlError < Treequel::Error; end

	### Exception type for a requested Control type that is nonexistent or
	### unsupported on the current server.
	class UnsupportedControl < Treequel::ControlError; end

	### Exception raised from Treequel::Model due to misconfiguration or
	### other problem.
	class ModelError < Treequel::Error; end

end # module Treequel


