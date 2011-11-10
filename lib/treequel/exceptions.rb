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
		def initialize( errors )
			if errors.respond_to?( :full_messages )
				@errors = errors
				super( errors.full_messages.join(', ') )
			else
				super
			end
		end

		######
		public
		######

		# the validation errors
		attr_reader :errors

	end # class ValidationFailed

	### Exception class raised when a before_* hooks returns a false value when saving
	### or destroying a Treequel::Model object.
	class BeforeHookFailed < Treequel::ModelError

		### Create a new Treequel::BeforeHookFailed exception that indicates that the
		### specified +hook+ returned a false value.
		def initialize( hook )
			@hook = hook.to_sym
			super "The 'before' hook failed when trying to %s" % [ hook ]
		end

		######
		public
		######

		# The hook that failed
		attr_reader :hook

	end # class BeforeHookFailed

end # module Treequel


