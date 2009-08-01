#!/usr/bin/env ruby

# An experiment to see if I can make some minimally-functional domain classes
# using what I have so far.

BEGIN {
	require 'pathname'
	base = Pathname( __FILE__ ).dirname.parent
	
	require base + 'experiments/utils.rb'
	libdir = base + 'lib'

	$LOAD_PATH.unshift( libdir )
}

include UtilityFunctions

require 'treequel'


dir = Treequel::Directory.new( :host => 'localhost', :connect_type => :tls )
dir.bind( 'cn=auth,dc=acme,dc=com', 'foobar' )


class Treequel::Model
	
end


class Employee < Treequel::Model

	def configure_schema
		
		set_schema do |dir|
			base_branch dir.ou( :People )
			scope :subtree

			has_many :departments, :via => Department
			many_to_many :groups, :via => Group
		end
	end
	
end


class Host < Treequel::Model
	
	def configure_schema
		set_schema do |dir|
			base_branches dir.ou( :Hosts ),
				dir.dc( :pettygrove ).ou( :Hosts ),
				dir.dc( :ljc ).ou( :Hosts ),
				dir.dc( :adtech2 ).ou( :Hosts ),
				dir.dc( :bennett ).ou( :Hosts )

			scope :subtree
			
			belongs_to :netblock, :via => Netblock
		end
	end
	
end



