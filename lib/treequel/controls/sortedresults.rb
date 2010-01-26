#!/usr/bin/env ruby
# coding: utf-8

require 'ldap'

require 'treequel'
require 'treequel/control'
require 'treequel/sequel_integration'


# A Treequel::Control module that implements the "LDAP Control Extension for Server 
# Side Sorting of Search Results" (RFC 2891).
# 
# == Usage
# 
# As with all Controls, you must first register the control with the
# Treequel::Directory object you're intending to search:
#   
#   dir = Treequel.directory( 'ldap://ldap.acme.com/dc=acme,dc=com' )
#   dir.register_controls( Treequel::SortedResultsControl )
# 
# Once that's done, any Treequel::Branchset you create will have the
# #order method that will allow you to specify one or more attributes by which the server
# should sort results before returning them:
# 
#   # Fetch people sorted by their last name, then first name, then
#   # by employeeNumber
#   people = dir.ou( :People )
#   sorted_people = people.filter( :objectClass => :person ).
#       order( :sn, :givenName, :employeeNumber )
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
module Treequel::SortedResultsControl
	include Treequel::Control,
	        Treequel::Constants

	# The control's request OID
	OID  = CONTROL_OIDS[:sortrequest]

	# The control's response OID
	RESPONSE_OID = CONTROL_OIDS[:sortresult]

	# Result codes
	RESPONSE_RESULT_CODES = {
		# success                   (0), -- results are sorted
		0 => 'Success',

		# operationsError           (1), -- server internal failure
		1 => 'Operations error; server internal failure',

		# timeLimitExceeded         (3), -- timelimit reached before
		#                                -- sorting was completed
		3 => 'Time limit reached before sorting was completed',

		# strongAuthRequired        (8), -- refused to return sorted
		#                                -- results via insecure
		#                                -- protocol
		8 => 'Stronger auth required: refusing to return sorted results via insecure protocol',

		# adminLimitExceeded       (11), -- too many matching entries
		#                                -- for the server to sort
		11 => 'Admin limit exceeded: too many matching entries for the server to sort',

		# noSuchAttribute          (16), -- unrecognized attribute
		#                                -- type in sort key
		16 => 'No such attribute',

		# inappropriateMatching    (18), -- unrecognized or
		#                                -- inappropriate matching
		#                                -- rule in sort key
		18 => 'Inappropriate matching: unrecognized or inappropriate matching rule in sort key',

		# insufficientAccessRights (50), -- refused to return sorted
		#                                -- results to this client
		50 => 'Insufficient access rights: refusing to return sorted results to this client',

		# busy                     (51), -- too busy to process
		51 => 'Busy: too busy to process',

		# unwillingToPerform       (53), -- unable to sort
		52 => 'Unwilling to perform: unable to sort',

		# other                    (80)
		80 => 'Other: non-specific result code (80)',
	}


	### Extension callback -- add the requisite instance variables to including Branchsets.
	def self::extend_object( branchset )
		super
		branchset.instance_variable_set( :@sort_order_criteria, [] )
	end


	######
	public
	######

	# The ordering criteria, if any
	attr_accessor :sort_order_criteria


	### Clone the Branchset with a server-side sorted results control added and return it.
	def order( *attributes )
		self.log.warn "This control will likely not work in ruby-ldap versions " +
			" <= 0.9.9. See http://code.google.com/p/ruby-activeldap/issues/" +
			"detail?id=38 for details." if LDAP::PATCH_VERSION < 10

		if attributes.flatten.empty?
			self.log.debug "cloning %p with no order" % [ self ]
			return self.unordered
		else
			criteria = attributes.collect do |attrspec|
				case attrspec
				when Symbol
					[ attrspec.to_s ]

				when Sequel::SQL::Expression
					[ attrspec.expression.to_s, nil, attrspec.descending ]

				else
					raise ArgumentError,
						"unsupported order specification type %s" % [ attrspec.class.name ]
				end
			end

			self.log.debug "cloning %p with order criteria: %p" % [ criteria ]
			copy = self.clone
			copy.sort_order_criteria += criteria

			return copy
		end
	end


	### Clone the Branchset without a server-side sorted results control and return it.
	def unordered
		copy = self.clone
		copy.unordered!
		return copy
	end


	### Remove any server-side sorted results control associated with the receiving 
	### Branchset, returning any removed criteria as an Array.
	def unordered!
		return self.sort_order_criteria.slice!( 0..-1 )
	end


	### Override the Enumerable method to update the cookie value each time a page 
	### is fetched.
	def each( &block )
		super do |branch|
			if sorted_control = branch.controls.find {|control| control.oid == RESPONSE_OID }
				sortResult, attributeType = sorted_control.decode
				if sortResult.nonzero?
					self.log.error "got non-zero response code for sort: %d (%s)" %
						[ sortResult, RESPONSE_RESULT_CODES[sortResult] ]
					raise Treequel::ControlError, RESPONSE_RESULT_CODES[sortResult]
				else
					self.log.debug "got 'success' sort response code."
				end
			end

			block.call( branch )
		end
	end


	#########
	protected
	#########

	### Make the ASN.1 string for the control value out of the given +mode+, 
	### +cookie+, +reload_hint+.
	def make_sorted_control_value( sort_criteria )

		### (http://tools.ietf.org/html/rfc2891#section-1.1):
	    # SortKeyList ::= SEQUENCE OF SEQUENCE {
	    #              attributeType   AttributeDescription,
	    #              orderingRule    [0] MatchingRuleId OPTIONAL,
	    #              reverseOrder    [1] BOOLEAN DEFAULT FALSE }
		encoded_vals = sort_criteria.collect do |criterion|
			OpenSSL::ASN1::Sequence.new( criterion )
		end

		return OpenSSL::ASN1::Sequence.new( encoded_vals ).to_der
	end


	### Treequel::Control API -- Get a configured LDAP::Control object for this
	### Branchset.
	def get_server_controls
		controls = super
		value = self.make_sorted_control_value( self.sort_order_criteria )
		return controls << LDAP::Control.new( OID, value, true )
	end

end
