#!/usr/bin/env ruby

require 'treequel' 
require 'treequel/filter'

begin
	require 'sequel'
rescue LoadError => err
	Treequel.logger.info "Sequel library didn't load: %s: %s" % [ err.class.name, err.message ]
	Treequel.logger.debug "  " + err.backtrace.join( "\n  " )
end
	

# Provide a dummy Sequel::SQL::Expression class for when the Sequel library
# isn't installed.
unless defined?( Sequel ) && 
	Sequel.const_defined?( :SQL ) && 
	Sequel::SQL.const_defined?( :Expression )

	module Sequel # :nodoc: all
		module SQL
			class Expression; end
		end
	end
end

