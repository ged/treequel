#!/usr/bin/env ruby

require_relative '../spec_helpers'

require 'treequel/branch'
require 'treequel/branchset'
require 'treequel/branchcollection'

include Treequel::SpecConstants
include Treequel::Constants

#####################################################################
### C O N T E X T S
#####################################################################

describe Treequel::Branch do

	before( :each ) do
		@conn = double( "ldap connection object", :bound? => false )
		@directory = get_fixtured_directory( @conn )
	end

	after( :each ) do
		Treequel::Branch.include_operational_attrs = false
	end


	it "can be constructed from a DN" do
		branch = Treequel::Branch.new( @directory, TEST_PEOPLE_DN )
		expect( branch.dn ).to eq( TEST_PEOPLE_DN )
	end

	it "raises an exception if created with an invalid DN" do
		expect {
			Treequel::Branch.new(@directory, 'soapyfinger')
		}.to raise_error( ArgumentError, /invalid dn/i )
	end

	it "can be constructed from an entry returned from LDAP::Conn.search_ext2"	do
		entry = {
			'dn'				=> [TEST_PERSON_DN],
			TEST_PERSON_DN_ATTR => TEST_PERSON_DN_VALUE,
		}
		branch = Treequel::Branch.new_from_entry( entry, @directory )

		expect( branch.rdn_attributes ).to eq( { TEST_PERSON_DN_ATTR => [TEST_PERSON_DN_VALUE] } )
		expect( branch.entry ).to eq( { TEST_PERSON_DN_ATTR => TEST_PERSON_DN_VALUE } )
		expect( branch.dn ).to eq( entry['dn'].first )
	end

	it "can be constructed from an entry with Symbol keys"	do
		entry = {
			:dn					=> [TEST_PERSON_DN],
			TEST_PERSON_DN_ATTR => TEST_PERSON_DN_VALUE,
		}
		branch = Treequel::Branch.new_from_entry( entry, @directory )

		expect( branch.rdn_attributes ).to eq( { TEST_PERSON_DN_ATTR => [TEST_PERSON_DN_VALUE] } )
		expect( branch.entry ).to eq({ TEST_PERSON_DN_ATTR => TEST_PERSON_DN_VALUE })
		expect( branch.dn ).to eq( entry[:dn].first )
	end

	it "can be instantiated with a Hash with Symbol keys"  do
		branch = Treequel::Branch.new( @directory, TEST_PERSON_DN,
			TEST_PERSON_DN_ATTR.to_sym => TEST_PERSON_DN_VALUE )
		expect( branch.entry ).to eq({ TEST_PERSON_DN_ATTR => TEST_PERSON_DN_VALUE })
	end

	it "raises an exception if constructed with something other than a Hash entry" do
		expect {
			Treequel::Branch.new( @directory, TEST_PEOPLE_DN, 18 )
		}.to raise_exception( ArgumentError, /can't cast/i )
	end

	it "can be configured to include operational attributes for all future instances" do
		Treequel::Branch.include_operational_attrs = false
		branch = Treequel::Branch.new( @directory, TEST_PEOPLE_DN )
		expect( branch.include_operational_attrs? ).to be_falsey

		Treequel::Branch.include_operational_attrs = true
		branch = Treequel::Branch.new( @directory, TEST_PEOPLE_DN )
		expect( branch.include_operational_attrs? ).to be_truthy
	end


	describe "instances" do

		before( :each ) do
			@entry = {
				'description' => ["A string", "another string"],
				'l' => [ 'Antartica', 'Galapagos' ],
				'objectClass' => ['organizationalUnit'],
				'rev' => ['03eca02ba232'],
				'ou' => ['Hosts'],
			}
			allow( @conn ).to receive( :bound? ).and_return( false )
			allow( @conn ).to receive( :search_ext2 ).
				with( TEST_HOSTS_DN, LDAP::LDAP_SCOPE_BASE, "(objectClass=*)" ).
				and_return([ @entry ])
			@branch = Treequel::Branch.new( @directory, TEST_HOSTS_DN )
		end


		it "knows what its RDN is" do
			expect( @branch.rdn ).to eq( TEST_HOSTS_RDN )
		end

		it "knows what its DN is" do
			expect( @branch.dn ).to eq( TEST_HOSTS_DN )
		end

		it "can return its DN as an array of attribute=value pairs" do
			expect( @branch.split_dn ).to eq( TEST_HOSTS_DN.split(/\s*,\s*/) )
		end

		it "can return its DN as a limited array of attribute=value pairs" do
			expect( @branch.split_dn( 2 ).length ).to eq( 2 )
			expect( @branch.split_dn( 2 ) ).to include( TEST_HOSTS_RDN, TEST_BASE_DN )
		end

		it "can return itself as an ldap:// URI" do
			expect( @branch.uri.to_s ).to eq( "ldap://#{TEST_HOST}/#{TEST_HOSTS_DN}?" )
		end

		it "are Comparable if they are siblings" do
			sibling = Treequel::Branch.new( @directory, TEST_PEOPLE_DN )

			expect( ( @branch <=> sibling ) ).to eq( -1 )
			expect( ( sibling <=> @branch ) ).to eq( 1 )
			expect( ( @branch <=> @branch ) ).to eq( 0 )
		end

		it "are Comparable if they are parent and child" do
			child = Treequel::Branch.new( @directory, TEST_HOST_DN )

			expect( ( @branch <=> child ) ).to eq( 1 )
			expect( ( child <=> @branch ) ).to eq( -1 )
		end

		it "compares as equal-by-value with another instance with the same DN" do
			clone = Treequel::Branch.new( @directory, TEST_HOSTS_DN )

			expect( @branch ).to be_eql( clone )
			expect( clone ).to be_eql( @branch )
		end

		it "compares as not equal-by-value with another instance with a different DN" do
			other = Treequel::Branch.new( @directory, TEST_HOST_DN )

			expect( @branch ).to_not be_eql( other )
			expect( other ).to_not be_eql( @branch )
		end

		it "hash-compares as equal with another instances with the same DN" do
			clone = Treequel::Branch.new( @directory, TEST_HOSTS_DN )
			expect( @branch.hash ).to eq( clone.hash )
		end

		it "has a hash value different than its DN string" do
			expect( @branch.hash ).to_not be == @branch.dn.hash
		end

		it "compares as not equal-by-value with another instance with a different DN" do
			other = Treequel::Branch.new( @directory, TEST_HOST_DN )
			expect( @branch.hash ).to_not be == other.hash
		end

		it "knows that it hasn't loaded its entry yet if it's nil" do
			expect( @branch.loaded? ).to be_falsey
		end

		it "knows that it has loaded its entry if it's non-nil" do
			@branch.instance_variable_set( :@entry, {} )
			expect( @branch.loaded? ).to be_truthy
		end

		it "knows that it exists in the directory if it can fetch its entry" do
			expect( @branch.exists? ).to be_truthy
		end

		it "knows that it doesn't exist in the directory if it can't fetch its entry" do
			expect( @conn ).to receive( :search_ext2 ).
				with( TEST_HOSTS_DN, LDAP::LDAP_SCOPE_BASE, "(objectClass=*)" ).
				and_return([])
			expect( @branch.exists? ).to be_falsey
		end

		it "fetch their LDAP::Entry from the directory if they don't already have one" do
			expect( @conn ).to receive( :search_ext2 ).
				with( TEST_HOSTS_DN, LDAP::LDAP_SCOPE_BASE, "(objectClass=*)" ).
				exactly( :once ).
				and_return([ @entry ])

			expect( @branch.entry ).to eq( @entry )
			expect( @branch.entry ).to eq( @entry ) # this should fetch the cached one
		end

		it "fetch their LDAP::Entry with operational attributes if include_operational_attrs is set" do
			expect( @conn ).to receive( :search_ext2 ).
				with( TEST_HOSTS_DN, LDAP::LDAP_SCOPE_BASE, "(objectClass=*)", ["*", "+"] ).once.
				and_return([ @entry ])

			@branch.include_operational_attrs = true
			expect( @branch.entry ).to eq( @entry )
		end

		it "can search its directory for values using itself as a base" do
			subentry = {'objectClass' => ['ipHost'], 'dn' => [TEST_HOST_DN] }
			expect( @conn ).to receive( :search_ext2 ).
				with( TEST_HOSTS_DN, LDAP::LDAP_SCOPE_ONELEVEL, "(objectClass=*)",
					  ["*"], false, nil, nil, 0, 0, 0, "", nil ).
				and_return([ subentry ])

			branches = @branch.search( :one, '(objectClass=*)' )

			expect( branches.length ).to eq( 1 )
			expect( branches.first ).to be_a( Treequel::Branch )
			expect( branches.first.dn ).to eq( TEST_HOST_DN )
		end

		it "can search its directory for values with a block" do
			subentry = {
				'objectClass' => ['ipHost'],
				TEST_HOST_DN_ATTR => [TEST_HOST_DN_VALUE],
				'dn' => [TEST_HOST_DN],
			}
			expect( @conn ).to receive( :search_ext2 ).
				with( TEST_HOSTS_DN, LDAP::LDAP_SCOPE_ONELEVEL, "(objectClass=*)",
					  ["*"], false, nil, nil, 0, 0, 0, "", nil ).
				and_return([ subentry ])

			yielded_val = nil
			@branch.search( :one, '(objectClass=*)' ) do |val|
				yielded_val = val
			end
			expect( yielded_val ).to be_a( Treequel::Branch )
			expect( yielded_val.entry ).to eq({
				'objectClass' => ['ipHost'],
				TEST_HOST_DN_ATTR => [TEST_HOST_DN_VALUE],
			})
		end

		it "clears any cached values if its include_operational_attrs attribute is changed" do
			expect( @directory ).to receive( :get_entry ).with( @branch ).exactly( :once ).
				and_return( TEST_PEOPLE_ENTRY.dup )
			expect( @directory ).to receive( :get_extended_entry ).with( @branch ).exactly( :once ).
				and_return( TEST_OPERATIONAL_PEOPLE_ENTRY.dup )

			expect( @branch.entry ).to eq( TEST_PEOPLE_ENTRY.dup.tap {|entry| entry.delete('dn') } )
			@branch.include_operational_attrs = true
			expect( @branch.entry ).to eq( TEST_OPERATIONAL_PEOPLE_ENTRY.dup.tap {|entry| entry.delete('dn') } )
		end

		it "returns a human-readable representation of itself for #inspect" do
			expect( @directory ).to_not receive( :get_entry ) # shouldn't try to load the entry for #inspect

			rval = @branch.inspect

			expect( rval ).to match( /#{TEST_HOSTS_DN_ATTR}/i )
			expect( rval ).to match( /#{TEST_HOSTS_DN_VALUE}/ )
			expect( rval ).to match( /#{TEST_BASE_DN}/ )
			expect( rval ).to match( /\bnil\b/ )
		end


		it "can fetch a child entry by RDN" do
			res = @branch.get_child( 'cn=surprise' )
			expect( res ).to be_a( Treequel::Branch )
			expect( res.dn ).to eq( [ 'cn=surprise', @branch.dn ].join( ',' ) )
		end

		it "can fetch a child entry by RDN if its DN is the empty String" do
			@branch.dn = ''
			res = @branch.get_child( 'cn=surprise' )
			expect( res ).to be_a( Treequel::Branch )
			expect( res.dn ).to eq( 'cn=surprise' )
		end

		it "create sub-branches for messages that match valid attributeType OIDs" do
			rval = @branch.cn( 'rondori' )
			expect( rval.dn ).to eq( "cn=rondori,#{TEST_HOSTS_DN}" )

			rval2 = rval.ou( 'Config' )
			expect( rval2.dn ).to eq( "ou=Config,cn=rondori,#{TEST_HOSTS_DN}" )
		end

		it "create sub-branches for messages with additional attribute pairs" do
			rval = @branch.cn( 'rondori', :l => 'Portland' )
			expect( rval.dn ).to eq( "cn=rondori+l=Portland,#{TEST_HOSTS_DN}" )

			rval2 = rval.ou( 'Config' )
			expect( rval2.dn ).to eq( "ou=Config,cn=rondori+l=Portland,#{TEST_HOSTS_DN}" )
		end

		it "don't create sub-branches for messages that don't match valid attributeType OIDs" do
			expect( @conn ).to receive( :bound? ).and_return( false )
			expect {
				@branch.facelart( 'sbc' )
			}.to raise_exception( NoMethodError, /undefined method.*facelart/i )
		end

		it "don't create sub-branches for multi-value RDNs with an invalid attribute" do
			expect( @conn ).to receive( :bound? ).and_return( false )
			expect {
				@branch.cn( 'benchlicker', :facelart => 'sbc' )
			}.to raise_exception( NoMethodError, /invalid secondary attribute.*facelart/i )
		end

		it "can return all of its immediate children as Branches" do
			expect( @directory ).to receive( :search ).with( @branch, :one, '(objectClass=*)', {} ).
				and_return([ :the_children ])
			expect( @branch.children ).to eq( [ :the_children ] )
		end

		it "can return its parent as a Branch" do
			expect( @branch.parent ).to be_a( Treequel::Branch )
			expect( @branch.parent.dn ).to eq( TEST_BASE_DN )
		end


		it "returns nil if a Branch for the base DN is asked for its parent" do
			expect( @branch.parent.parent ).to be_nil()
		end


		it "can construct a Treequel::Branchset that uses it as its base" do
			expect( @branch.branchset ).to be_a( Treequel::Branchset )
			expect( @branch.branchset.base_dn ).to eq( @branch.dn )
		end

		it "can create a filtered Treequel::Branchset for itself" do
			branchset = @branch.filter( :cn => 'acme' )

			expect( branchset ).to be_a( Treequel::Branchset )
			expect( branchset.filter_string ).to match( /\(cn=acme\)/ )
		end

		it "can create a Treequel::Branchset from itself that returns instances of another class" do
			otherclass = Class.new( Treequel::Branch )
			branchset = @branch.as( otherclass )

			expect( branchset ).to be_a( Treequel::Branchset )
			expect( branchset.branch ).to be_a( otherclass )
		end

		it "doesn't restrict the number of arguments passed to #filter (bugfix)" do
			branchset = @branch.filter( :uid => [:rev, :grumpy, :glee] )

			expect( branchset ).to be_a( Treequel::Branchset )
			expect( branchset.filter_string ).to match( /\(\|\(uid=rev\)\(uid=grumpy\)\(uid=glee\)\)/i )
		end

		it "can create a scoped Treequel::Branchset for itself" do
			branchset = @branch.scope( :onelevel )

			expect( branchset ).to be_a( Treequel::Branchset )
			expect( branchset.scope ).to eq( :onelevel )
		end

		it "can create a selective Treequel::Branchset for itself" do
			branchset = @branch.select( :uid, :l, :familyName, :givenName )

			expect( branchset ).to be_a( Treequel::Branchset )
			expect( branchset.select ).to eq( %w[uid l familyName givenName] )
		end

		it "knows which objectClasses it has" do
			expect( @branch.object_classes ).
				to include( @directory.schema.object_classes[:organizationalUnit] )
		end

		it "knows what operational attributes it has" do
			op_attrs = @directory.schema.attribute_types.values.select do |attrtype|
				attrtype.operational?
			end.uniq

			expect( @branch.operational_attribute_types.length ).to eq( op_attrs.length )
			expect( @branch.operational_attribute_types ).to include( *op_attrs )
		end

		it "knows what the OIDs of its operational attributes are" do
			op_numeric_oids = @directory.schema.attribute_types.values.select do |attrtype|
				attrtype.operational?
			end.uniq.map( &:oid )
			op_names = @directory.schema.attribute_types.values.select do |attrtype|
				attrtype.operational?
			end.uniq.map( &:names ).flatten

			op_oids = op_numeric_oids + op_names

			expect( @branch.operational_attribute_oids.length ).to eq( op_oids.length )
			expect( @branch.operational_attribute_oids ).to include( *op_oids )
		end

		it "can return the set of all its MUST attributes' OIDs based on which objectClasses " +
		   "it has" do
			expect( @conn ).to receive( :search_ext2 ).
				with( TEST_HOSTS_DN, LDAP::LDAP_SCOPE_BASE, "(objectClass=*)" ).
				and_return([ {'objectClass' => %w[ipHost device ieee802device]} ])

			must_oids = @branch.must_oids
			expect( must_oids.length ).to eq( 3 )
			expect( must_oids ).to include( :objectClass, :cn, :ipHostNumber )
		end

		it "can return the set of all its MUST attributeTypes based on which objectClasses it has" do
			expect( @conn ).to receive( :search_ext2 ).
				with( TEST_HOSTS_DN, LDAP::LDAP_SCOPE_BASE, "(objectClass=*)" ).
				and_return([ {'objectClass' => %w[ipHost device ieee802device]} ])

			expected_attrtypes = @directory.schema.attribute_types.
				values_at( :objectClass, :cn, :ipHostNumber )

			must_attrs = @branch.must_attribute_types
			expect( must_attrs.length ).to eq( 3 )
			expect( must_attrs ).to include( *expected_attrtypes )
		end

		it "can return a Hash pre-populated with pairs that correspond to its MUST attributes" do
			expect( @conn ).to receive( :search_ext2 ).
				with( TEST_HOSTS_DN, LDAP::LDAP_SCOPE_BASE, "(objectClass=*)" ).
				and_return([ {'objectClass' => %w[ipHost device ieee802device]} ])

			expect( @branch.must_attributes_hash ).to include(
				:cn => [''],
				:ipHostNumber => [''],
				:objectClass => ['top']
			)
		end


		it "can return the set of all its MAY attributes' OIDs based on which objectClasses " +
		   "it has" do
			expect( @conn ).to receive( :search_ext2 ).
				with( TEST_HOSTS_DN, LDAP::LDAP_SCOPE_BASE, "(objectClass=*)" ).
				and_return([ {'objectClass' => %w[ipHost device ieee802device]} ])

			must_oids = @branch.may_oids
			expect( must_oids.length ).to eq( 9 )
			expect( must_oids ).to include( :l, :description, :manager, :serialNumber, :seeAlso,
				:owner, :ou, :o, :macAddress )
		end

		it "can return the set of all its MAY attributeTypes based on which objectClasses it has" do
			expect( @conn ).to receive( :search_ext2 ).
				with( TEST_HOSTS_DN, LDAP::LDAP_SCOPE_BASE, "(objectClass=*)" ).
				and_return([ {'objectClass' => %w[ipHost device ieee802device]} ])

			expected_attrtypes = @directory.schema.attribute_types.values_at( :l, :description,
				:manager, :serialNumber, :seeAlso, :owner, :ou, :o, :macAddress )

			expect( @branch.may_attribute_types ).to include( *expected_attrtypes )
		end

		it "can return a Hash pre-populated with pairs that correspond to its MAY attributes" do
			expect( @conn ).to receive( :search_ext2 ).
				with( TEST_HOSTS_DN, LDAP::LDAP_SCOPE_BASE, "(objectClass=*)" ).
				and_return([ {'objectClass' => %w[ipHost device ieee802device]} ])

			expect( @branch.may_attributes_hash ).to include({
				:l			  => [],
				:description  => [],
				:manager	  => [],
				:serialNumber => [],
				:seeAlso	  => [],
				:owner		  => [],
				:ou			  => [],
				:o			  => [],
				:macAddress	  => []
			})
		end

		it "can return the set of all of its valid attributeTypes, which is a union of its " +
		   "MUST and MAY attributes plus the directory's operational attributes" do
			all_attrs = @branch.valid_attribute_types

			expect( all_attrs.length ).to eq( 57 )
			expect( all_attrs ).to include( @directory.schema.attribute_types[:ou] )
			expect( all_attrs ).to include( @directory.schema.attribute_types[:l] )
		end


		it "can return a Hash pre-populated with pairs that correspond to all of its valid " +
		   "attributes" do
			expect( @branch.valid_attributes_hash ).to eq({
				:objectClass				=> ['top'],
				:ou							=> [''],
				:userPassword				=> [],
				:searchGuide				=> [],
				:seeAlso					=> [],
				:businessCategory			=> [],
				:x121Address				=> [],
				:registeredAddress			=> [],
				:destinationIndicator		=> [],
				:telexNumber				=> [],
				:teletexTerminalIdentifier	=> [],
				:telephoneNumber			=> [],
				:internationaliSDNNumber	=> [],
				:facsimileTelephoneNumber	=> [],
				:street						=> [],
				:postOfficeBox				=> [],
				:postalCode					=> [],
				:postalAddress				=> [],
				:physicalDeliveryOfficeName => [],
				:st							=> [],
				:l							=> [],
				:description				=> [],
				:preferredDeliveryMethod	=> nil,
			})
		end


		it "can return the set of all of its valid attribute OIDs, which is a union of its " +
		   "MUST and MAY attribute OIDs" do
			all_attr_oids = @branch.valid_attribute_oids

			expect( all_attr_oids ).to contain_exactly(
				:objectClass, :ou,
				:userPassword, :searchGuide, :seeAlso, :businessCategory, :x121Address,
				:registeredAddress, :destinationIndicator, :telexNumber, :teletexTerminalIdentifier,
				:telephoneNumber, :internationaliSDNNumber, :facsimileTelephoneNumber, :street,
				:postOfficeBox, :postalCode, :postalAddress, :physicalDeliveryOfficeName, :st, :l,
				:description, :preferredDeliveryMethod
			 )
		end

		it "knows if an attribute is valid given its objectClasses" do
			expect( @branch.valid_attribute?( :ou ) ).to be_truthy
			expect( @branch.valid_attribute?( :rubberChicken ) ).to be_falsey
		end

		it "can be moved to a new location within the directory" do
			newdn = "ou=oldhosts,#{TEST_BASE_DN}"
			expect( @conn ).to receive( :modrdn ).
				with( TEST_HOSTS_DN, "ou=oldhosts", true )
			@branch.move( newdn )
		end


		it "resets any cached data when its DN changes" do
			expect( @conn ).to receive( :search_ext2 ).
				with( TEST_HOSTS_DN, LDAP::LDAP_SCOPE_BASE, "(objectClass=*)" ).
				and_return([ @entry ])
			@branch.entry

			@branch.dn = TEST_SUBHOSTS_DN

			expect( @conn ).to receive( :search_ext2 ).
				with( TEST_SUBHOSTS_DN, LDAP::LDAP_SCOPE_BASE, "(objectClass=*)" ).
				and_return([ @entry ])
			@branch.entry
		end


		it "can create children under itself" do
			newattrs = {
				:ipHostNumber => '127.0.0.1',
				:objectClass  => [:ipHost, :device],
			}

			expect( @conn ).to receive( :add ).
				with( "cn=chillyt,#{TEST_HOSTS_DN}",
				      "ipHostNumber"=>["127.0.0.1"],
				      "objectClass"=>["ipHost", "device"] )

			res = @branch.cn( :chillyt ).create( newattrs )
			expect( res ).to be_a( Treequel::Branch )
			expect( res.dn ).to eq( "cn=chillyt,#{TEST_HOSTS_DN}" )
		end


		it "can copy itself to a sibling entry" do
			expect( @conn ).to receive( :add ).with( TEST_SUBHOSTS_DN, @entry )

			newbranch = @branch.copy( TEST_SUBHOSTS_DN )
			expect( newbranch.dn ).to eq( TEST_SUBHOSTS_DN )
		end


		it "can copy itself to a sibling entry with attribute changes" do
			expect( @conn ).to receive( :add ).
				with( TEST_SUBHOSTS_DN, @entry.merge('description' => ['Hosts in a subdomain.']) )

			newbranch = @branch.copy( TEST_SUBHOSTS_DN, :description => ['Hosts in a subdomain.'] )
			expect( newbranch.dn ).to eq( TEST_SUBHOSTS_DN )
		end


		it "can modify its entry's attributes en masse by merging a Hash" do
			attributes = {
				:displayName => 'Chilly T. Penguin',
				:description => "A chilly little penguin.",
			}
			expect( @conn ).to receive( :modify ).
				with( TEST_HOSTS_DN,
				      'displayName' => ['Chilly T. Penguin'],
				      'description' => ["A chilly little penguin."] )

			@branch.merge( attributes )
		end


		it "can delete all values of one of its entry's individual attributes" do
			mod = LDAP::Mod.new( LDAP::LDAP_MOD_DELETE, 'displayName', [] )
			expect( @conn ).to receive( :modify ).with( TEST_HOSTS_DN, [mod] )
			@branch.delete( :displayName )
		end

		it "can delete all values of more than one of its entry's individual attributes" do
			mod1 = LDAP::Mod.new( LDAP::LDAP_MOD_DELETE, 'displayName', [] )
			mod2 = LDAP::Mod.new( LDAP::LDAP_MOD_DELETE, 'gecos', [] )
			expect( @conn ).to receive( :modify ).with( TEST_HOSTS_DN, [mod1, mod2] )

			@branch.delete( :displayName, :gecos )
		end

		it "can delete one particular value of its entry's individual attributes" do
			mod = LDAP::Mod.new( LDAP::LDAP_MOD_DELETE, 'objectClass', ['apple-user'] )
			expect( @conn ).to receive( :modify ).with( TEST_HOSTS_DN, [mod] )

			@branch.delete( :objectClass => 'apple-user' )
		end

		it "can delete one particular non-String value of its entry's individual attributes" do
			mod = LDAP::Mod.new( LDAP::LDAP_MOD_DELETE, 'pwdChangedTime', ['20000101201501Z'] )
			expect( @conn ).to receive( :modify ).with( TEST_HOSTS_DN, [mod] )

			@branch.delete( :pwdChangedTime => Time.gm(2000,"jan",1,20,15,1) )
		end

		it "can delete particular values of more than one of its entry's individual attributes" do
			mod1 = LDAP::Mod.new( LDAP::LDAP_MOD_DELETE, 'objectClass',
			                      ['apple-user', 'inetOrgPerson'] )
			mod2 = LDAP::Mod.new( LDAP::LDAP_MOD_DELETE, 'cn', [] )
			expect( @conn ).to receive( :modify ).with( TEST_HOSTS_DN, array_including(mod1, mod2) )

			@branch.delete( :objectClass => ['apple-user',:inetOrgPerson], :cn => [] )
		end

		it "deletes its entry entirely if no attributes are specified" do
			expect( @conn ).to receive( :delete ).with( TEST_HOSTS_DN )
			@branch.delete
		end


		it "knows how to represent its DN as an RFC1781-style UFN", :if => LDAP.respond_to?(:dn2ufn) do
			expect( @branch.to_ufn ).to match( /Hosts, acme\.com/i )
		end


		it "knows how to represent its DN as a UFN even if the LDAP library doesn't " +
		   "define #dn2ufn" do
			expect( LDAP ).to receive( :respond_to? ).with( :dn2ufn ).and_return( false )
			expect( @branch.to_ufn ).to match( /Hosts, acme\.com/i )
		end


		it "knows how to represent itself as LDIF" do
			ldif = @branch.to_ldif
			expect( ldif ).to match( /dn: #{TEST_HOSTS_DN_ATTR}=#{TEST_HOSTS_DN_VALUE},#{TEST_BASE_DN}/i )
			expect( ldif ).to match( /description: A string/ )
			expect( ldif ).to match( /description: another string/ )
			expect( ldif ).to match( /l: Antartica/ )
			expect( ldif ).to match( /l: Galapagos/ )
			expect( ldif ).to match( /ou: Hosts/ )
		end


		LONG_TEST_VALUE = 'A poet once said, "The whole universe is in ' +
			'a glass of wine." We will probably never know in what sense ' +
			'he meant that, for poets do not write to be understood. But ' +
			'it is true that if we look at a glass of wine closely enough ' +
			'we see the entire universe.'

		it "knows how to split long lines in LDIF output" do
			entry = {
				'description' => [LONG_TEST_VALUE],
				'l' => [ 'Antartica', 'Galapagos' ]
			}
			expect( @conn ).to receive( :search_ext2 ).
				with( TEST_HOSTS_DN, LDAP::LDAP_SCOPE_BASE, "(objectClass=*)" ).
				and_return([ entry ])

			ldif = @branch.to_ldif( 20 )
			val = ldif[ /(description: (?:[^\n]|\n )+)/, 1 ]
			lines = val.split( /\n/ )

			expect( lines.first ).to match( /.{20}/ )
			lines[1..-2].each do |line|
				expect( line ).to match( / .{19}/ )
			end
			expect( lines.last ).to match( / .{1,19}/ )
		end


		LONG_BINARY_TEST_VALUE = ( <<-END_VALUE ).gsub( /^\t{2}/, '' )
		Once there came a man
		Who said,
		"Range me all men of the world in rows."
		And instantly
		There was terrific clamour among the people
		Against being ranged in rows.
		There was a loud quarrel, world-wide.
		It endured for ages;
		And blood was shed
		By those who would not stand in rows,
		And by those who pined to stand in rows.
		Eventually, the man went to death, weeping.
		And those who staid in bloody scuffle
		Knew not the great simplicity.
		END_VALUE

		it "knows how to split long binary lines in LDIF output" do
			entry = {
				'description' => [LONG_BINARY_TEST_VALUE],
				'l' => [ 'Antartica', 'Galapagos' ]
			}
			expect( @conn ).to receive( :search_ext2 ).
				with( TEST_HOSTS_DN, LDAP::LDAP_SCOPE_BASE, "(objectClass=*)" ).
				and_return([ entry ])

			ldif = @branch.to_ldif( 20 )
			expect( ldif.scan( /^description/ ).length ).to eq( 1 )

			val = ldif[ /^(description:: (?:[^\n]|\n )+)/, 1 ]
			lines = val.split( /\n/ )
			expect( lines.first ).to match( /.{20}/ )
			lines[1..-2].each do |line|
				expect( line ).to match( / .{19}/ )
			end
			expect( lines.last ).to match( / .{1,19}/ )
		end


		it "knows how to represent itself as a Hash" do
			expect( @branch.to_hash ).to eq({
				'description' => ['A string', 'another string'],
				'l' => [ 'Antartica', 'Galapagos' ],
				'objectClass' => ['organizationalUnit'],
				'ou' => ['Hosts'],
				'rev' => ['03eca02ba232']
			})
		end

		it "returns a Treequel::BranchCollection with equivalent Branchsets if added to another " +
		   "Branch" do
			other_branch = Treequel::Branch.new( @directory, TEST_SUBHOSTS_DN )

			coll = (@branch + other_branch)

			expect( coll ).to be_a( Treequel::BranchCollection )
			expect( coll.branchsets.length ).to eq( 2 )
			expect( coll.branchsets.map( &:base_dn ) ).to include( TEST_HOSTS_DN, TEST_SUBHOSTS_DN )
		end


		### Attribute reader
		describe "index fetch operator" do

			it "fetches a multi-value attribute as an Array of Strings" do
				entry = {
					'description' => ["A string", "another string"],
					'l' => [ 'Antartica', 'Galapagos' ],
					'objectClass' => ['organizationalUnit'],
				}
				expect( @conn ).to receive( :search_ext2 ).
					with( TEST_HOSTS_DN, LDAP::LDAP_SCOPE_BASE, "(objectClass=*)" ).
					and_return([ entry ])

				expect( @branch[ :description ] ).to include( 'A string', 'another string' )
				expect( @branch[ :l ] ).to include( 'Galapagos', 'Antartica' )
			end

			it "fetches an empty Array if a record doesn't have an attribute set" do
				expect( @branch[ :cn ] ).to eq( [] )
			end

			it "fetches an empty Array for an attribute if the entry doesn't exist" do
				expect( @conn ).to receive( :search_ext2 ).
					with( TEST_HOSTS_DN, LDAP::LDAP_SCOPE_BASE, "(objectClass=*)" ).
					and_return( [] )
				expect( @branch[ :cn ] ).to eq( [] )
			end

			it "fetches a single-value attribute as a scalar String" do
				test_dn = "cn=ssh,cn=www,#{TEST_HOSTS_DN}"
				entry = {
					'ipServicePort' => ['22'],
					'ipServiceProtocol' => ['tcp'],
					'objectClass' => ['ipService'],
					'cn' => ['www'],
				}
				expect( @conn ).to receive( :search_ext2 ).
					with( test_dn, LDAP::LDAP_SCOPE_BASE, "(objectClass=*)" ).
					and_return([ entry ])

				branch = Treequel::Branch.new( @directory, test_dn )

				expect( branch[ :ipServicePort ] ).to eq( 22 )
				expect( branch[ :ipServiceProtocol ] ).to eq( ['tcp'] )
			end

			it "returns the entry without conversion if there is no such attribute in the schema" do
				expect( @branch[ :rev ] ).to eq( [ '03eca02ba232' ] )
			end

			it "returns nil if a record doesn't have a SINGLE-type attribute set" do
				expect( @branch[ :displayName ] ).to eq( nil )
			end

			it "caches the value fetched from its entry" do
				expect( @conn ).to receive( :search_ext2 ).
					with( TEST_HOSTS_DN, LDAP::LDAP_SCOPE_BASE, "(objectClass=*)" ).
					exactly( :once ).
					and_return([ @entry ])

				2.times { @branch[ :description ] }
			end

			it "doesn't cache nil values that don't correspond to an attribute type in the schema" do
				expect( @conn ).to receive( :search_ext2 ).
					with( TEST_HOSTS_DN, LDAP::LDAP_SCOPE_BASE, "(objectClass=*)" ).
					and_return([ @entry ])

				@branch[ :string_beans ]
				expect( @branch.instance_variable_get( :@values ) ).to_not have_key( :string_beans )
			end

			it "freezes the values fetched from its entry by default to prevent accidental " +
			   "in-place modification" do
				expect( @conn ).to receive( :search_ext2 ).
					with( TEST_HOSTS_DN, LDAP::LDAP_SCOPE_BASE, "(objectClass=*)" ).
					exactly( :once ).
					and_return([ @entry ])

				expect {
					@branch[ :description ] << "Another description"
				}.to raise_error( /can't modify frozen/i )
			end

			it "doesn't freeze the values fetched from its entry if it's told not to" do
				expect( @conn ).to receive( :search_ext2 ).
					with( TEST_HOSTS_DN, LDAP::LDAP_SCOPE_BASE, "(objectClass=*)" ).
					exactly( :once ).
					and_return([ @entry ])

				begin
					Treequel::Branch.freeze_converted_values = false

					expect {
						@branch[ :description ] << "Another description"
					}.to_not raise_error()
				ensure
					Treequel::Branch.freeze_converted_values = true
				end
			end

			it "converts objects via the conversions set in its directory" do
				test_dn = "cn=ssh,cn=www,#{TEST_HOSTS_DN}"
				entry = {
					'ipServicePort' => ['22'],
					'ipServiceProtocol' => ['tcp'],
					'objectClass' => ['ipService'],
					'cn' => ['www'],
				}
				expect( @conn ).to receive( :search_ext2 ).
					with( test_dn, LDAP::LDAP_SCOPE_BASE, "(objectClass=*)" ).
					and_return([ entry ])

				branch = Treequel::Branch.new( @directory, test_dn )

				expect( branch[ :ipServicePort ] ).to be_a( Fixnum )
			end

			it "respects syntax inherited from supertype in object conversion" do
				test_dn = "cn=authorized_users,#{TEST_HOSTS_DN}"
				entry = {
					'cn' => ['authorized_users'],
					'member' => [TEST_PERSON_DN]
				}
				expect( @conn ).to receive( :search_ext2 ).
					with( test_dn, LDAP::LDAP_SCOPE_BASE, "(objectClass=*)" ).
					and_return([ entry ])

				branch = Treequel::Branch.new( @directory, test_dn )

				expect( branch[ :member ].first ).to be_a( Treequel::Branch )
				expect( branch[ :member ].first.dn ).to eq( TEST_PERSON_DN )
			end

		end

		### Attribute writer
		describe "index set operator" do

			it "writes a single value attribute via its directory" do
				test_dn = "cn=ssh,cn=www,#{TEST_HOSTS_DN}"
				entry = {
					'ipServicePort' => ['22'],
					'ipServiceProtocol' => ['tcp'],
					'objectClass' => ['ipService'],
					'cn' => ['www'],
				}
				expect( @conn ).to receive( :search_ext2 ).
					with( test_dn, LDAP::LDAP_SCOPE_BASE, "(objectClass=*)" ).
					and_return([ entry ])
				branch = Treequel::Branch.new( @directory, test_dn )

				expect( @conn ).to receive( :modify ).
					with( test_dn, {'ipServicePort' => ['22022']} )

				branch[ :ipServicePort ] = 22022
			end

			it "converts values for non-single attribute types to an Array" do
				test_dn = "cn=laptops,ou=computerlists,ou=macosxodconfig,#{TEST_BASE_DN}"
				entry = {
					'dn' => [test_dn],
					'cn' => ['laptops'],
					'objectClass' => ['apple-computer-list'],
					'apple-computers' => %w[chernobyl beetlejuice toronaga],
					'apple-generateduid' => ['3f73981a-07bb-11e0-b21a-fb56fb48ba42'],
				}
				expect( @conn ).to receive( :search_ext2 ).
					with( test_dn, LDAP::LDAP_SCOPE_BASE, "(objectClass=*)" ).
					and_return([ entry ])
				branch = Treequel::Branch.new( @directory, test_dn )

				expect( @conn ).to receive( :modify ).
					with( test_dn, "apple-computers" =>
						  ["chernobyl", "beetlejuice", "toronaga", "glider", "creeper"] )

				branch[ 'apple-computers' ] += %w[glider creeper]
			end

			it "writes multiple attribute values via its directory" do
				test_dn = "cn=ssh,cn=www,#{TEST_HOSTS_DN}"
				branch = Treequel::Branch.new( @directory, test_dn )

				expect( @conn ).to receive( :modify ).
					with( test_dn,
						  'ipServicePort' => ['56'],
						  'ipServiceProtocol' => ['udp']
					  )

				branch.merge( :ipServicePort => 56, :ipServiceProtocol => 'udp' )
			end
		end

		it "can fetch multiple values via #values_at" do
			results = @branch.values_at( TEST_HOSTS_DN_ATTR, :description )

			expect( results ).to eq([ [TEST_HOSTS_DN_VALUE], @entry['description'] ])
		end

	end

end


# vim: set nosta noet ts=4 sw=4:
