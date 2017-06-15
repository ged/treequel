#!/usr/bin/env ruby

require 'rack'
require 'treequel'

### A collection of Rack middleware for adding LDAP authentication/authorization
### to Rack applications.
module LdapAuthentification

	### The simplest kind of authentication -- if the user provides credentials that allow
	### her to bind to the directory, access is granted.
	class BindAuth

		### Create a new LdapAuthentication::Bind middleware that will wrap +app+. Supported options
		### are:
		###
		### url::
		###   The LDAP URL (RFC4516) used to specify how to bind to the directory.
		def initialize( app, options )
			@app = app
			@url = options[:url]
			@dir, @attributes, @scope, @filter = self.split_url( @url )
		end


		######
		public
		######

		### Rack Interface: handle a request.
		def call( env )
			request = Rack::Request.new( env )
			if self.can_bind?( request.params.values_at('uid','password') )
				return @app.call( env )
			else
				return [
					401,
					{
						'Content-Type' => 'text/plain',
						'Content-Length' => '0',
						'WWW-Authenticate' => www_authenticate.to_s
					},
					[]
				]
			end
		end


		#########
		protected
		#########

		### Parse the given +url+ into a Treequel::Directory, an Array of selection attributes,
		### a scope, and a filter for selecting users.
		def split_url( url )
			url = URI.parse( url )
			directory = Treequel.directory( url )

			parts = url.query.split( '?' )
			attributes = self.normalize_attributes( parts.shift )
			scope = self.normalize_scope( parts.shift )
			filter = self.normalize_filter( parts.shift )

			return directory, attributes, scope, filter
		end


		### Parse the attributes in the given +attrlist+ and return an Array of Symbols suitable
		### for passing to Treequel::Branch#select.
		def normalize_attributes( attrlist=nil )
			return [] unless attrlist
			return attrlist.split( /,/ ).
				reject  {|attrname| attrname !~ /^[a-z][^\w\-]$/i }.
				collect {|attrname| attrname.untaint.to_sym }
		end


		### Parse the scope from the given +scopename+ and return it as one of the Symbols:
		### [ :sub, :one, :base ]
		def normalize_scope( scopename )
			if scopename =~ /^(one|sub|base)/i
				return $1.untaint.to_sym
			else
				raise ArgumentError, "Invalid scope %p" % [ scopename ]
			end
		end


		### Returns +true+ if the specified +user+ can bind to the directory
		### with the specified +password+.
		def can_bind?( username, password )
			filter = @filter.gsub( /:username/, username )
			@user = @dir.scope( @scope.to_sym ).filter( filter )
			@dir.bind( @user, password )
			return true
		rescue LDAP::ResultError => err
			# How the hell do you log from Rack middleware?
			return false
		end

	end # class BindAuth
end

