#!/usr/bin/ruby

require 'rubygems'
require 'treequel'

require 'arrow/service'


# 
# An experimental user service.
# 
# == Subversion Id
# 
# $Id$
# 
# == Authors
# 
# * Michael Granger <ged@FaerieMUD.org>
# 
class UserService < Arrow::Service

	# SVN Revision
	SVNRev = %q$Rev$

	# SVN Id
	SVNId = %q$Id$

	# Applet signature
    applet_name "DevEiate Blog Service"
    applet_description "Offers a REST view of ou=People resources (currently read-only)."
    applet_maintainer "Michael Granger <ged@FaerieMUD.org>"


	### Connect to the directory when instantiated.
	def initialize( *args )
		@dir = Treequel.directory
		@people = @dir.ou( :people )

		super
	end


	#################################################################
	###	A C T I O N S
	#################################################################

	### GET /service/users/{uid}
	def fetch( txn, userid )
		return @people.uid( userid )
	end


	### GET /service/users
	def fetch_all( txn )
		if count = txn.vargs[:count]
			return @people.limit( count ).all
		else
			return @people.children
		end
	end


	#########
	protected
	#########

	### Validate the +userid+ argument as a UID.
	def validate_id( uid )
		self.log.debug "validating userid (UID) %p" % [ uid ]
		finish_with Apache::BAD_REQUEST, "missing ID" if uid.nil?
		finish_with Apache::BAD_REQUEST, "malformed or invalid ID: #{uid}" unless
			uid =~ /^\w{3,16}$/

		uid.untaint
		return uid
	end

end # class UserService

