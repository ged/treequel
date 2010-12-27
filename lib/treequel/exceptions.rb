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

	### Exception class raised when +raise_on_save_failure+ is set and validation fails
	class ValidationFailed < Treequel::ModelError

		### Create a new Treequel::ValidationFailed exception with the given +errors+.
		### @param [Treequel::Model::Errors, String] errors  the validaton errors
		def initialize( errors )
			if errors.respond_to?( :full_messages )
				@errors = errors
				super( errors.full_messages.join(', ') )
			else
				super
			end
		end

		# @return [Treequel::Model::Errors] the validation errors
		attr_reader :errors
	end

end # module Treequel


