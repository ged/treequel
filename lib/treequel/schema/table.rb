#!/usr/bin/env ruby

require 'forwardable'
require 'ldap'
require 'ldap/schema'

require 'treequel'
require 'treequel/constants'
require 'treequel/mixins'


# This is an object that is used to store LDAP schema information in a 
# case-insensitive table.
# 
# == Authors
# 
# * Michael Granger <ged@FaerieMUD.org>
# * Mahlon E. Smith <mahlon@martini.nu>
# 
# :include: LICENSE
#
#--
#
# Please see the file LICENSE in the base directory for licensing details.
#
class Treequel::Schema::Table
	extend Forwardable
	include Treequel::Loggable,
	        Treequel::Constants::Patterns

	# The list of methods that should be delegated through the key-normalization
	# method.
	KEYED_METHODS = [ :"[]", :"[]=", :delete, :fetch, :has_key?, :include?, :member?, :store ]


	### Auto-generate methods which call the given +delegate+ after normalizing
	### their first argument via +normalize_key+
	def self::def_normalized_delegators( delegate, *syms )
		syms.each do |methodname|
			define_method( methodname ) do |key, *args|
				nkey = normalize_key( key )
				instance_variable_get( delegate ).
					__send__( methodname, nkey, *args )
			end
		end
	end


	### Create a new Treequel::Table using the given +hash+ for initial
	### values.
	def initialize( initial_values={} )
		@hash = {}
		initial_values.each {|k,v| self.append(k => v) }
	end


	### Make sure +@hash+ is unique on Table duplications.
	def initialize_copy( orig_table ) # :nodoc:
		@hash = orig_table.to_hash
	end


	######
	public
	######

	# Delegate a handful of methods to the underlying Hash after normalizing
	# the key.
	def_normalized_delegators :@hash, *KEYED_METHODS


	# Delegate some methods to the underlying Hash
	begin
		unoverridden_methods = Hash.instance_methods(false).collect {|mname| mname.to_sym }
		def_delegators :@hash, *( unoverridden_methods - KEYED_METHODS )
	end


	### Return the Table in LDIF format
	def to_s
		@hash.collect do |oid,value|
			"%s: %s" % [ oid, value ]
		end.flatten.sort.join( "\r\n" ) + "\r\n"
	end


	### Return the Table as a hash.
	def to_h
		@hash.dup
	end
	alias_method :to_hash, :to_h


	### Merge +other_table+ into the receiver.
	def merge!( other_table, &merge_callback )
		nhash = normalize_hash( other_table.to_hash )
		@hash.merge!( nhash, &merge_callback )
	end
	alias_method :update!, :merge!


	### Return a new table which is the result of merging the receiver
	### with +other_table+ in the same fashion as Hash#merge. If the optional
	### +merge_callback+ block is provided, it is called whenever there is a
	### key collision between the two.
	def merge( other_table, &merge_callback ) # :yields: key, original_value, new_value
		other = self.dup
		other.merge!( other_table, &merge_callback )
		return other
	end
	alias_method :update, :merge


	### Return an array containing the values associated with the given
	### keys.
	def values_at( *keys )
		@hash.values_at( *(keys.collect {|k| normalize_key(k)}) )
	end


	#########
	protected
	#########

	### Proxy method: handle getting/setting headers via methods instead of the
	### index operator.
	def method_missing( sym, *args )
		# work magic
		return super unless sym.to_s =~ /^([a-z]\w+)(=)?$/

		# If it's an assignment, the (=)? will have matched
		key, assignment = $1, $2

		method_body = nil
		if assignment
			method_body = self.make_setter( key )
		else
			method_body = self.make_getter( key )
		end

		self.class.send( :define_method, sym, &method_body )
		return self.method( sym ).call( *args )
	end


	### Create a Proc that will act as a setter for the given key
	def make_setter( key )
		return Proc.new {|new_value| self[ key ] = new_value }
	end


	### Create a Proc that will act as a getter for the given key
	def make_getter( key )
		return Proc.new { self[key] }
	end


	#######
	private
	#######

	### Return a copy of +hash+ with all of its keys normalized by #normalize_key.
	def normalize_hash( hash )
		hash = hash.dup
		hash.keys.each do |key|
			nkey = normalize_key( key )
			hash[ nkey ] = hash.delete( key ) if key != nkey
		end

		return hash
	end


	### Normalize the given key to equivalence
	def normalize_key( key )
		return key if key =~ NUMERICOID
		return key.to_s.downcase.
			gsub( /[^[:alnum:]\-_]/, '' ).
			gsub( '-', '_' ).
			to_sym
	end

end # class Treequel::Schema::Table
