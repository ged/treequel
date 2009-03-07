#!/usr/bin/env ruby

require 'ldap'
require 'uri'
require 'forwardable'


# An experiment to see what kind of DSL would be useful for building
# LDAP "datasets" like Sequel's SQL datasets.

module Treequel
	
	class Branch
		extend Forwardable
		
		def initialize( dir, attribute, value, parent=nil )
			@dir       = dir
			@attribute = attribute
			@value     = value
			@parent    = parent
		end

		def_delegators :@dir, :bind, :bound?
		
		attr_reader :dir, :attribute, :value, :parent
		
		def method_missing( sym, *args )
			return self.class.new( @dir.dup, sym, args.first, self )
		end

		def dn
			rval = "#{self.attribute}=#{self.value}"
			rval << ',' << self.parent.dn if self.parent
			
			return rval
		end
		alias_method :to_s, :dn

		def inspect
			return "#<%s:0x%0x %s>" % [ self.class.name, self.object_id * 2, self.dn ]
		end

		def filter( filterstring )
			return self.dir.search( self.dn, LDAP::LDAP_SCOPE_SUBTREE, filterstring )
		end
		
		def +( other )
			return Treequel::BranchCollection.new( self, other )
		end
	end


	class BranchCollection
		def self::def_multi_methods( *names )
			names.each do |name|
				define_method( name ) do |*args|
					self.multi_exec( name, *args )
				end
			end
		end
		

		def initialize( left_branches, right_branches )
			@branches = ( left_branches + right_branches ).flatten
		end

		attr_reader :branches

		def multi_exec( op, *args )
			res = @branches.collect {|br| br.send(op, *args) }.flatten
		end

		def +( other )
			if other.respond_to?( :branches )
				return self.class.new( self.branches, other.branches )
			else
				return self.class.new( self.branches, [other] )
			end
		end

		def_multi_methods :filter
	end
	
	
	class Directory

		DEFAULT_OPTIONS = {
			:host    => 'localhost',
			:port    => LDAP::LDAP_PORT,
			:connect => :plain
		}
		
		def initialize( options )
			@options = DEFAULT_OPTIONS.merge( options )
			@conn = nil
			@bound_as = nil
		end


		def conn
			return @conn ||= self.connect
		end

		def connect
			host = @options[:host]
			port = @options[:port]
			
			case @options[:connect]
			when :tls
				return LDAP::SSLConn.new( host, port, true )
			when :ssl
				return LDAP::SSLConn.new( host, port )
			else
				return LDAP::Conn.new( host, port )
			end
		end
		
		
		def bind( as=nil, password=nil, &block )
			if as.nil?
				self.conn.bind( nil, nil, LDAP::LDAP_AUTH_SIMPLE, &block )
			else
				self.conn.bind( as.to_s, password, &block )
			end
		end

		def bound?
			return @conn.bound?
		end

		def search( base_dn, scope, filter )
			return self.conn.search2( base_dn, scope, filter )
		end

		def method_missing( sym, *args )
			return Treequel::Branch.new( self.dup, sym, args.first )
		end
		
	end # class Directory
	
	
	###############
	module_function
	###############

	def directory( options )
		return Treequel::Directory.new( options )
	end
	
	
end # module Treequel

directory_params = {
	:connect => :tls
}

$dir = Treequel.directory( directory_params ).dc( :com ).dc( :laika )

# # By default, anonymous binding...
# 
# # ...but you can set a default binding
# dir.bind( dir.ou(:people).uid(:mgranger), "password" )
# 
# # ...or bind as someone else for the duration of the block
# dir.bind( 'cn=auth,dc=laika,dc=com', password ) do
# 	# do something as the 'auth' user
# end
# 
# # Make a "dataset" out of the 'ou=departments,dc=laika,dc=com' branch
# departments = dir.ou( :departments )
# 
# # Same thing, but for disparate branches
# hosts = dir.ou( :hosts ) +
#         dir.dc( :pettygrove ).ou( :hosts ) +
#         dir.dc( :bennett ).ou( :hosts ) +
#         dir.dc( :ljc ).ou( :hosts )
# 
# hosts.filter( :ipHostNumber => "10.111.222.66" ).first
# # {
# #   :cn           => ["leroy"],
# #   :macAddress   => ["00:e0:18:90:9f:16"],
# #   :ipHostNumber => ["10.111.222.66"],
# #   :description  => ["Provides vinton.com e-mail forwarding"],
# #   :objectClass  => ["top", "device", "ipHost", "laikaHost", "ieee802Device"],
# #   :owner        => ["cn=isg,ou=Lists,dc=laika,dc=com"]
# # }
# # 
# 
