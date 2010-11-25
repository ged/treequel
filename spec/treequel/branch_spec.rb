#!/usr/bin/env ruby

BEGIN {
	require 'pathname'
	basedir = Pathname.new( __FILE__ ).dirname.parent.parent

	libdir = basedir + "lib"

	$LOAD_PATH.unshift( basedir ) unless $LOAD_PATH.include?( basedir )
	$LOAD_PATH.unshift( libdir ) unless $LOAD_PATH.include?( libdir )
}

require 'rspec'

require 'spec/lib/constants'
require 'spec/lib/helpers'
require 'spec/lib/matchers'

require 'treequel/branch'
require 'treequel/branchset'
require 'treequel/branchcollection'

include Treequel::TestConstants
include Treequel::Constants

#####################################################################
###	C O N T E X T S
#####################################################################

describe Treequel::Branch do
	include Treequel::SpecHelpers,
	        Treequel::Matchers


	before( :all ) do
		setup_logging( :fatal )
	end

	after( :all ) do
		reset_logging()
	end

	before( :each ) do
		@directory = mock( "treequel directory", :get_entry => :an_entry_hash )
	end

	after( :each ) do
		Treequel::Branch.include_operational_attrs = false
	end


	it "can be constructed from a DN" do
		branch = Treequel::Branch.new( @directory, TEST_PEOPLE_DN )
		branch.dn.should == TEST_PEOPLE_DN
	end

	it "raises an exception if created with an invalid DN" do
		expect {
			Treequel::Branch.new(@directory, 'soapyfinger')
		}.to raise_error( ArgumentError, /invalid dn/i )
	end

	it "can be constructed from an entry returned from LDAP::Conn.search_ext2"  do
		entry = {
			'dn'                => [TEST_PERSON_DN],
			TEST_PERSON_DN_ATTR => TEST_PERSON_DN_VALUE,
		}
		branch = Treequel::Branch.new_from_entry( entry, @directory )

		branch.rdn_attributes.should == { TEST_PERSON_DN_ATTR => [TEST_PERSON_DN_VALUE] }
		branch.entry.should == entry
	end

	it "can be constructed from an entry with Symbol keys"  do
		entry = {
			:dn                 => [TEST_PERSON_DN],
			TEST_PERSON_DN_ATTR => TEST_PERSON_DN_VALUE,
		}
		branch = Treequel::Branch.new_from_entry( entry, @directory )

		branch.rdn_attributes.should == { TEST_PERSON_DN_ATTR => [TEST_PERSON_DN_VALUE] }
		branch.entry.should == {
			'dn'                => [TEST_PERSON_DN],
			TEST_PERSON_DN_ATTR => TEST_PERSON_DN_VALUE,
		}
	end

	it "can be instantiated with a Hash with Symbol keys"  do
		branch = Treequel::Branch.new( @directory, TEST_PERSON_DN,
			TEST_PERSON_DN_ATTR.to_sym => TEST_PERSON_DN_VALUE )
		branch.entry.should == {
			TEST_PERSON_DN_ATTR => TEST_PERSON_DN_VALUE,
		}
	end

	it "raises an exception if constructed with something other than a Hash entry" do
		expect {
			Treequel::Branch.new( @directory, TEST_PEOPLE_DN, 18 )
		}.to raise_exception( ArgumentError, /can't cast/i )
	end

	it "can be configured to include operational attributes for all future instances" do
		Treequel::Branch.include_operational_attrs = false
		Treequel::Branch.new( @directory, TEST_PEOPLE_DN ).include_operational_attrs?.should be_false
		Treequel::Branch.include_operational_attrs = true
		Treequel::Branch.new( @directory, TEST_PEOPLE_DN ).include_operational_attrs?.should be_true
	end


	describe "instances" do

		before( :each ) do
			@branch = Treequel::Branch.new( @directory, TEST_HOSTS_DN )

			@schema = mock( "treequel schema" )
			@entry = mock( "entry object" )
			@directory.stub( :schema ).and_return( @schema )
			@directory.stub( :get_entry ).and_return( @entry )
			@directory.stub( :base_dn ).and_return( TEST_BASE_DN )
			@schema.stub( :attribute_types ).
				and_return({ :cn => :a_value, :ou => :a_value })

			@syntax = stub( "attribute ldapSyntax object", :oid => OIDS::STRING_SYNTAX )
			@attribute_type = mock( "schema attribute type object", :syntax => @syntax )
		end


		it "knows what its RDN is" do
			@branch.rdn.should == TEST_HOSTS_RDN
		end

		it "knows what its DN is" do
			@branch.dn.should == TEST_HOSTS_DN
		end

		it "can return its DN as an array of attribute=value pairs" do
			@branch.split_dn.should == TEST_HOSTS_DN.split(/\s*,\s*/)
		end

		it "can return its DN as a limited array of attribute=value pairs" do
			@branch.split_dn( 2 ).should have( 2 ).members
			@branch.split_dn( 2 ).should include( TEST_HOSTS_RDN, TEST_BASE_DN )
		end

		it "can return itself as an ldap:// URI" do
			@directory.should_receive( :uri ).and_return( URI.parse("ldap://#{TEST_HOST}/#{TEST_BASE_DN}") )
			@branch.uri.to_s.should == "ldap://#{TEST_HOST}/#{TEST_HOSTS_DN}?"
		end

		it "are Comparable if they are siblings" do
			sibling = Treequel::Branch.new( @directory, TEST_PEOPLE_DN )

			( @branch <=> sibling ).should == -1
			( sibling <=> @branch ).should == 1
			( @branch <=> @branch ).should == 0
		end

		it "are Comparable if they are parent and child" do
			child = Treequel::Branch.new( @directory, TEST_HOST_DN )

			( @branch <=> child ).should == 1
			( child <=> @branch ).should == -1
		end


		it "fetch their LDAP::Entry from the directory if they don't already have one" do
			@directory.should_receive( :get_entry ).with( @branch ).exactly( :once ).
				and_return( :the_entry )

			@branch.entry.should == :the_entry
			@branch.entry.should == :the_entry # this should fetch the cached one
		end

		it "fetch their LDAP::Entry with operational attributes if include_operational_attrs is set" do
			@branch.include_operational_attrs = true
			@directory.should_not_receive( :get_entry )
			@directory.should_receive( :get_extended_entry ).with( @branch ).exactly( :once ).
				and_return( :the_extended_entry )

			@branch.entry.should == :the_extended_entry
		end

		it "can search its directory for values using itself as a base" do
			@directory.should_receive( :search ).with( @branch, :one, '(objectClass=*)', {} ).
				and_return( :entries )
			@branch.search( :one, '(objectClass=*)' ).should == :entries
		end

		it "can search its directory for values with a block" do
			@directory.should_receive( :search ).with( @branch, :one, '(objectClass=*)', {} ).
				and_yield( :an_entry )
			yielded_val = nil
			@branch.search( :one, '(objectClass=*)' ) do |val|
				yielded_val = val
			end
			yielded_val.should == :an_entry
		end

		it "clears any cached values if its include_operational_attrs attribute is changed" do
			@directory.should_receive( :get_entry ).with( @branch ).exactly( :once ).
				and_return( :the_entry )
			@directory.should_receive( :get_extended_entry ).with( @branch ).exactly( :once ).
				and_return( :the_extended_entry )

			@branch.entry.should == :the_entry
			@branch.include_operational_attrs = true
			@branch.entry.should == :the_extended_entry
		end

		it "returns a human-readable representation of itself for #inspect" do
			@directory.should_not_receive( :get_entry ) # shouldn't try to load the entry for #inspect

			rval = @branch.inspect

			rval.should =~ /#{TEST_HOSTS_DN_ATTR}/i
			rval.should =~ /#{TEST_HOSTS_DN_VALUE}/
			rval.should =~ /#{TEST_BASE_DN}/
			rval.should =~ /\bnil\b/
		end


		it "can fetch a child entry by RDN" do
			res = @branch.get_child( 'cn=surprise' )
			res.should be_a( Treequel::Branch )
			res.dn.should == [ 'cn=surprise', @branch.dn ].join( ',' )
		end

		it "can fetch a child entry by RDN if its DN is the empty String" do
			@branch.dn = ''
			res = @branch.get_child( 'cn=surprise' )
			res.should be_a( Treequel::Branch )
			res.dn.should == 'cn=surprise'
		end

		it "create sub-branches for messages that match valid attributeType OIDs" do
			@schema.should_receive( :attribute_types ).twice.
				and_return({ :cn => :a_value, :ou => :a_value })

			rval = @branch.cn( 'rondori' )
			rval.dn.should == "cn=rondori,#{TEST_HOSTS_DN}"

			rval2 = rval.ou( 'Config' )
			rval2.dn.should == "ou=Config,cn=rondori,#{TEST_HOSTS_DN}"
		end

		it "create sub-branches for messages with additional attribute pairs" do
			@schema.should_receive( :attribute_types ).
				and_return({ :cn => :a_value, :ou => :a_value, :l => :a_value })

			rval = @branch.cn( 'rondori', :l => 'Portland' )
			rval.dn.should == "cn=rondori+l=Portland,#{TEST_HOSTS_DN}"

			rval2 = rval.ou( 'Config' )
			rval2.dn.should == "ou=Config,cn=rondori+l=Portland,#{TEST_HOSTS_DN}"
		end

		it "don't create sub-branches for messages that don't match valid attributeType OIDs" do
			@schema.should_receive( :attribute_types ).
				and_return({ :cn => :a_value, :ou => :a_value })

			lambda {
				@branch.facelart( 'sbc' )
			}.should raise_exception( NoMethodError, /undefined method.*facelart/i )
		end

		it "don't create sub-branches for multi-value RDNs with an invalid attribute" do
			@schema.should_receive( :attribute_types ).
				and_return({ :cn => :a_value, :ou => :a_value })

			lambda {
				@branch.cn( 'benchlicker', :facelart => 'sbc' )
			}.should raise_exception( NoMethodError, /invalid secondary attribute.*facelart/i )
		end

		it "can return all of its immediate children as Branches" do
			@directory.should_receive( :search ).with( @branch, :one, '(objectClass=*)', {} ).
				and_return([ :the_children ])
			@branch.children.should == [ :the_children ]
		end

		it "can return its parent as a Branch" do
			parent_branch = stub( "parent branch object" )
			@branch.should_receive( :class ).and_return( Treequel::Branch )
			Treequel::Branch.should_receive( :new ).with( @directory, TEST_BASE_DN ).
				and_return( parent_branch )
			@branch.parent.should == parent_branch
		end


		it "can construct a Treequel::Branchset that uses it as its base" do
			branchset = stub( "branchset" )
			Treequel::Branchset.should_receive( :new ).with( @branch ).
				and_return( branchset )

			@branch.branchset.should == branchset
		end

		it "can create a filtered Treequel::Branchset for itself" do
			branchset = mock( "filtered branchset" )
			Treequel::Branchset.should_receive( :new ).with( @branch ).
				and_return( branchset )
			branchset.should_receive( :filter ).with( {:cn => 'acme'} ).
				and_return( :a_filtered_branchset )

			@branch.filter( :cn => 'acme' ).should == :a_filtered_branchset
		end

		it "doesn't restrict the number of arguments passed to #filter (bugfix)" do
			branchset = mock( "filtered branchset" )
			Treequel::Branchset.should_receive( :new ).with( @branch ).
				and_return( branchset )
			branchset.should_receive( :filter ).with( :uid, [:glumpy, :grumpy, :glee] ).
				and_return( :a_filtered_branchset )

			@branch.filter( :uid, [:glumpy, :grumpy, :glee] ).should == :a_filtered_branchset
		end

		it "can create a scoped Treequel::Branchset for itself" do
			branchset = mock( "scoped branchset" )
			Treequel::Branchset.should_receive( :new ).with( @branch ).
				and_return( branchset )
			branchset.should_receive( :scope ).with( :onelevel ).
				and_return( :a_scoped_branchset )

			@branch.scope( :onelevel ).should == :a_scoped_branchset
		end

		it "can create a selective Treequel::Branchset for itself" do
			branchset = mock( "selective branchset" )
			Treequel::Branchset.should_receive( :new ).with( @branch ).
				and_return( branchset )
			branchset.should_receive( :select ).with( :uid, :l, :familyName, :givenName ).
				and_return( :a_selective_branchset )

			@branch.select( :uid, :l, :familyName, :givenName ).should == :a_selective_branchset
		end

		it "knows which objectClasses it has" do
			oc_attr = mock( "objectClass attributeType object" )
			string_syntax = stub( "string ldapSyntax object", :oid => OIDS::STRING_SYNTAX )
			@schema.should_receive( :attribute_types ).and_return({ :objectClass => oc_attr })
			oc_attr.should_receive( :single? ).and_return( false )
			oc_attr.should_receive( :syntax ).at_least( :once ).
				and_return( string_syntax )

			@entry.should_receive( :[] ).with( 'objectClass' ).at_least( :once ).
				and_return([ 'organizationalUnit', 'extensibleObject' ])

			@directory.should_receive( :convert_to_object ).
				with( OIDS::STRING_SYNTAX, 'organizationalUnit' ).
				and_return( 'organizationalUnit' )
			@directory.should_receive( :convert_to_object ).
				with( OIDS::STRING_SYNTAX, 'extensibleObject' ).
				and_return( 'extensibleObject' )

			@schema.should_receive( :object_classes ).twice.and_return({
					:organizationalUnit => :ou_objectclass,
					:extensibleObject => :extobj_objectclass,
				})

			@branch.object_classes.should == [ :ou_objectclass, :extobj_objectclass ]
		end

		it "knows what operational attributes it has" do
			op_attrs = MINIMAL_OPERATIONAL_ATTRIBUTES.inject({}) do |hash, oa|
				hash[ oa ] = mock("#{oa} attributeType object")
				hash
			end
			@schema.should_receive( :operational_attribute_types ).and_return( op_attrs.values )

			@branch.operational_attribute_types.should == op_attrs.values
		end

		it "knows what the OIDs of its operational attributes are" do
			op_attrs = MINIMAL_OPERATIONAL_ATTRIBUTES.inject({}) do |hash, oa|
				hash[ oa ] = stub("#{oa} attributeType object", :oid => :an_oid )
				hash
			end
			@schema.should_receive( :operational_attribute_types ).at_least( :once ).
				and_return( op_attrs.values )

			@branch.operational_attribute_oids.should have( op_attrs.length ).members
			@branch.operational_attribute_oids.should include( :an_oid )
		end

		it "can return the set of all its MUST attributes' OIDs based on which objectClasses " +
		   "it has" do
			oc1 = mock( "first objectclass" )
			oc2 = mock( "second objectclass" )

			@branch.should_receive( :object_classes ).and_return([ oc1, oc2 ])
			oc1.should_receive( :must_oids ).at_least( :once ).and_return([ :oid1, :oid2 ])
			oc2.should_receive( :must_oids ).at_least( :once ).and_return([ :oid1, :oid3 ])

			must_oids = @branch.must_oids
			must_oids.should have( 3 ).members
			must_oids.should include( :oid1, :oid2, :oid3 )
		end

		it "can return the set of all its MUST attributeTypes based on which objectClasses it has" do
			oc1 = mock( "first objectclass", :name => 'first_oc' )
			oc2 = mock( "second objectclass", :name => 'second_oc' )

			@branch.should_receive( :object_classes ).and_return([ oc1, oc2 ])
			oc1.should_receive( :must ).at_least( :once ).and_return([ :cn, :uid ])
			oc2.should_receive( :must ).at_least( :once ).and_return([ :cn, :l ])

			must_attrs = @branch.must_attribute_types
			must_attrs.should have( 3 ).members
			must_attrs.should include( :cn, :uid, :l )
		end

		it "can return a Hash pre-populated with pairs that correspond to its MUST attributes" do
			cn_attrtype = mock( "cn attribute type", :single? => false )
			l_attrtype = mock( "l attribute type", :single? => true )
			objectClass_attrtype = mock( "objectClass attribute type", :single? => false )

			cn_attrtype.should_receive( :name ).at_least( :once ).and_return( :cn )
			l_attrtype.should_receive( :name ).at_least( :once ).and_return( :l )
			objectClass_attrtype.should_receive( :name ).at_least( :once ).and_return( :objectClass )

			@branch.should_receive( :must_attribute_types ).at_least( :once ).
				and_return([ cn_attrtype, l_attrtype, objectClass_attrtype ])

			@branch.must_attributes_hash.
				should == { :cn => [''], :l => '', :objectClass => [:top] }
		end


		it "can return the set of all its MAY attributes' OIDs based on which objectClasses " +
		   "it has" do
			oc1 = mock( "first objectclass" )
			oc2 = mock( "second objectclass" )

			@branch.should_receive( :object_classes ).and_return([ oc1, oc2 ])
			oc1.should_receive( :may_oids ).at_least( :once ).and_return([ :oid1, :oid2 ])
			oc2.should_receive( :may_oids ).at_least( :once ).and_return([ :oid1, :oid3 ])

			must_oids = @branch.may_oids
			must_oids.should have( 3 ).members
			must_oids.should include( :oid1, :oid2, :oid3 )
		end

		it "can return the set of all its MAY attributeTypes based on which objectClasses it has" do
			oc1 = mock( "first objectclass" )
			oc2 = mock( "second objectclass" )

			@branch.should_receive( :object_classes ).and_return([ oc1, oc2 ])
			oc1.should_receive( :may ).and_return([ :description, :mobilePhone ])
			oc2.should_receive( :may ).and_return([ :chunktype ])

			must_attrs = @branch.may_attribute_types
			must_attrs.should have( 3 ).members
			must_attrs.should include( :description, :mobilePhone, :chunktype )
		end

		it "can return a Hash pre-populated with pairs that correspond to its MAY attributes" do
			cn_attrtype = mock( "cn attribute type", :single? => false )
			l_attrtype = mock( "l attribute type", :single? => true )

			cn_attrtype.should_receive( :name ).at_least( :once ).and_return( :cn )
			l_attrtype.should_receive( :name ).at_least( :once ).and_return( :l )

			@branch.should_receive( :may_attribute_types ).at_least( :once ).
				and_return([ cn_attrtype, l_attrtype ])

			@branch.may_attributes_hash.
				should == { :cn => [], :l => nil }
		end

		it "can return the set of all of its valid attributeTypes, which is a union of its " +
		   "MUST and MAY attributes plus the directory's operational attributes" do
			@branch.should_receive( :must_attribute_types ).
				and_return([ :cn, :l, :uid ])
			@branch.should_receive( :may_attribute_types ).
				and_return([ :description, :mobilePhone, :chunktype ])
			@branch.should_receive( :operational_attribute_types ).
				and_return([ :createTimestamp, :creatorsName ])

			all_attrs = @branch.valid_attribute_types

			all_attrs.should have( 8 ).members
			all_attrs.should include( :cn, :uid, :l, :description, :mobilePhone,
				:chunktype, :createTimestamp, :creatorsName )
		end

		it "can return a Hash pre-populated with pairs that correspond to all of its valid " +
		   "attributes" do
			@branch.should_receive( :must_attributes_hash ).at_least( :once ).
				and_return({ :cn => [''], :l => '', :objectClass => [:top] })
			@branch.should_receive( :may_attributes_hash ).at_least( :once ).
				and_return({ :description => nil, :givenName => [], :cn => nil })

			@branch.valid_attributes_hash.should == {
				:cn => [''],
				:l => '',
				:objectClass => [:top],
				:description => nil,
				:givenName => [],
			}
		end


		it "can return the set of all of its valid attribute OIDs, which is a union of its " +
		   "MUST and MAY attribute OIDs" do
			@branch.should_receive( :must_oids ).
				and_return([ :must_oid1, :must_oid2 ])
			@branch.should_receive( :may_oids ).
				and_return([ :may_oid1, :may_oid2, :must_oid1 ])

			all_attr_oids = @branch.valid_attribute_oids

			all_attr_oids.should have( 4 ).members
			all_attr_oids.should include( :must_oid1, :must_oid2, :may_oid1, :may_oid2 )
		end

		it "knows if an attribute is valid given its objectClasses" do
			attrtype = mock( "attribute type object" )

			@branch.should_receive( :valid_attribute_types ).
				twice.
				and_return([ attrtype ])

			attrtype.should_receive( :valid_name? ).with( :uid ).and_return( true )
			attrtype.should_receive( :valid_name? ).with( :rubberChicken ).and_return( false )

			@branch.valid_attribute?( :uid ).should be_true()
			@branch.valid_attribute?( :rubberChicken ).should be_false()
		end

		it "can be moved to a new location within the directory" do
			newdn = "ou=hosts,dc=admin,#{TEST_BASE_DN}"
			@directory.should_receive( :move ).with( @branch, newdn )
			@branch.move( newdn )
		end


		it "resets any cached data when its DN changes" do
			@directory.should_receive( :get_entry ).with( @branch ).
				and_return( :first_entry, :second_entry )

			@branch.entry
			@branch.dn = TEST_HOSTS_DN
			@branch.entry.should == :second_entry
		end


		it "can create children under itself" do
			newattrs = {
				:ipHostNumber => '127.0.0.1',
				:objectClass  => [:ipHost],
			}
			@directory.should_receive( :create ).
				with( an_instance_of(Treequel::Branch), newattrs ).
				and_return( true )

			@branch.cn( :chillyt ).create( newattrs )
		end


		it "can copy itself to a sibling entry" do
			newbranch = stub( "copied sibling branch" )
			Treequel::Branch.should_receive( :new ).with( @directory, TEST_PERSON2_DN ).
				and_return( newbranch )
			@entry.should_receive( :merge ).with( {} ).and_return( :merged_attributes )
			@directory.should_receive( :create ).with( newbranch, :merged_attributes ).
				and_return( true )

			@branch.copy( TEST_PERSON2_DN ).should == newbranch
		end


		it "can copy itself to a sibling entry with attribute changes" do
			oldattrs = { :sn => "Davies", :firstName => 'David' }
			newattrs = { :sn => "Michaels", :firstName => 'George' }
			newbranch = stub( "copied sibling branch" )
			Treequel::Branch.should_receive( :new ).with( @directory, TEST_PERSON2_DN ).
				and_return( newbranch )
			@entry.should_receive( :merge ).with( newattrs ).and_return( newattrs )
			@directory.should_receive( :create ).with( newbranch, newattrs ).
				and_return( true )

			@branch.copy( TEST_PERSON2_DN, newattrs ).should == newbranch
		end


		it "can modify its entry's attributes en masse by merging a Hash" do
			attributes = {
				:displayName => 'Chilly T. Penguin',
				:description => "A chilly little penguin.",
			}

			@directory.should_receive( :modify ).with( @branch, attributes )

			@branch.merge( attributes )
		end


		it "can delete all values of one of its entry's individual attributes" do
			LDAP::Mod.should_receive( :new ).with( LDAP::LDAP_MOD_DELETE, 'displayName', [] ).
				and_return( :mod_delete )
			@directory.should_receive( :modify ).with( @branch, [:mod_delete] )

			@branch.delete( :displayName )
		end

		it "can delete all values of more than one of its entry's individual attributes" do
			LDAP::Mod.should_receive( :new ).with( LDAP::LDAP_MOD_DELETE, 'displayName', [] ).
				and_return( :first_mod_delete )
			LDAP::Mod.should_receive( :new ).with( LDAP::LDAP_MOD_DELETE, 'gecos', [] ).
				and_return( :second_mod_delete )
			@directory.should_receive( :modify ).
				with( @branch, [:first_mod_delete, :second_mod_delete] )

			@branch.delete( :displayName, :gecos )
		end

		it "can delete one particular value of its entry's individual attributes" do
			LDAP::Mod.should_receive( :new ).
				with( LDAP::LDAP_MOD_DELETE, 'objectClass', ['apple-user'] ).
				and_return( :mod_delete )
			@directory.should_receive( :modify ).with( @branch, [:mod_delete] )

			@branch.delete( :objectClass => 'apple-user' )
		end

		it "can delete particular values of more than one of its entry's individual attributes" do
			LDAP::Mod.should_receive( :new ).
				with( LDAP::LDAP_MOD_DELETE, 'objectClass', ['apple-user', 'inetOrgPerson'] ).
				and_return( :first_mod_delete )
			LDAP::Mod.should_receive( :new ).
				with( LDAP::LDAP_MOD_DELETE, 'cn', [] ).and_return( :second_mod_delete )
			@directory.should_receive( :modify ).
				with( @branch, array_including(:first_mod_delete, :second_mod_delete) )

			@branch.delete( :objectClass => ['apple-user',:inetOrgPerson], :cn => [] )
		end

		it "deletes its entry entirely if no attributes are specified" do
			@directory.should_receive( :delete ).with( @branch )
			@branch.delete
		end


		it "knows how to represent its DN as an RFC1781-style UFN" do
			@branch.to_ufn.should =~ /Hosts, acme\.com/i
		end


		it "knows how to represent itself as LDIF" do
			@entry.should_receive( :keys ).and_return([ 'description', 'l' ])
			@entry.should_receive( :[] ).with( 'description' ).
				and_return([ 'A chilly little penguin.' ])
			@entry.should_receive( :[] ).with( 'l' ).
				and_return([ 'Antartica', 'Galapagos' ])

			ldif = @branch.to_ldif
			ldif.should =~ /dn: #{TEST_HOSTS_DN_ATTR}=#{TEST_HOSTS_DN_VALUE},#{TEST_BASE_DN}/i
			ldif.should =~ /description: A chilly little penguin./
		end


		LONG_TEST_VALUE = 'A poet once said, "The whole universe is in ' +
			'a glass of wine." We will probably never know in what sense ' +
			'he meant that, for poets do not write to be understood. But ' +
			'it is true that if we look at a glass of wine closely enough ' +
			'we see the entire universe.'

		it "knows how to split long lines in LDIF output" do
			@entry.should_receive( :keys ).and_return([ 'description', 'l' ])
			@entry.should_receive( :[] ).with( 'description' ).
				and_return([ LONG_TEST_VALUE ])
			@entry.should_receive( :[] ).with( 'l' ).
				and_return([ 'Antartica', 'Galapagos' ])

			ldif = @branch.to_ldif( 20 )
			val = ldif[ /(description: (?:[^\n]|\n )+)/, 1 ]
			lines = val.split( /\n/ )

			lines.first.should =~ /.{20}/
			lines[1..-2].each do |line|
				line.should =~ / .{19}/
			end
			lines.last.should =~ / .{1,19}/
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
			@entry.should_receive( :keys ).and_return([ 'description', 'l' ])
			@entry.should_receive( :[] ).with( 'description' ).
				and_return([ LONG_BINARY_TEST_VALUE ])
			@entry.should_receive( :[] ).with( 'l' ).
				and_return([ 'Antartica', 'Galapagos' ])

			ldif = @branch.to_ldif( 20 )
			ldif.scan( /^description/ ).length.should == 1

			val = ldif[ /^(description:: (?:[^\n]|\n )+)/, 1 ]
			lines = val.split( /\n/ )
			lines.first.should =~ /.{20}/
			lines[1..-2].each do |line|
				line.should =~ / .{19}/
			end
			lines.last.should =~ / .{1,19}/
		end


		it "knows how to represent itself as a Hash" do
			@entry.should_receive( :keys ).and_return([ 'description', 'dn', 'l' ])
			@entry.should_receive( :[] ).with( 'description' ).
				and_return([ 'A chilly little penguin.' ])
			@entry.should_receive( :[] ).with( 'l' ).
				and_return([ 'Antartica', 'Galapagos' ])

			@branch.to_hash.should == {
				'description' => ['A chilly little penguin.'],
				'l' => [ 'Antartica', 'Galapagos' ],
				'dn' => TEST_HOSTS_DN,
			}
		end

		it "returns a Treequel::BranchCollection with equivalent Branchsets if added to another " +
		   "Branch" do
			other_branch = Treequel::Branch.new( @directory, TEST_SUBHOSTS_DN )

			Treequel::Branchset.should_receive( :new ).with( @branch ).and_return( :branchset )
			Treequel::Branchset.should_receive( :new ).with( other_branch ).and_return( :other_branchset )
			Treequel::BranchCollection.should_receive( :new ).with( :branchset, :other_branchset ).
				and_return( :a_collection )

			(@branch + other_branch).should == :a_collection
		end


		### Attribute reader
		describe "index fetch operator" do

			it "fetches a multi-value attribute as an Array of Strings" do
				@schema.should_receive( :attribute_types ).and_return({ :glumpy => @attribute_type })
				@attribute_type.should_receive( :single? ).and_return( false )
				@entry.should_receive( :[] ).with( 'glumpy' ).at_least( :once ).
					and_return([ 'glumpa1', 'glumpa2' ])

				@attribute_type.stub( :syntax ).and_return( @syntax )
				@directory.stub( :convert_to_object ).and_return {|_,str| str }

				@branch[ :glumpy ].should == [ 'glumpa1', 'glumpa2' ]
			end

			it "fetches a single-value attribute as a scalar String" do
				@schema.should_receive( :attribute_types ).and_return({ :glumpy => @attribute_type })
				@attribute_type.should_receive( :single? ).and_return( true )
				@entry.should_receive( :[] ).with( 'glumpy' ).at_least( :once ).
					and_return([ 'glumpa1' ])

				@attribute_type.stub( :syntax ).and_return( @syntax )
				@directory.stub( :convert_to_object ).and_return {|_,str| str }

				@branch[ :glumpy ].should == 'glumpa1'
			end

			it "returns the entry without conversion if there is no such attribute in the schema" do
				@schema.should_receive( :attribute_types ).and_return({})
				@entry.should_receive( :[] ).with( 'glumpy' ).at_least( :once ).
					and_return([ 'glumpa1' ])
				@branch[ :glumpy ].should == [ 'glumpa1' ]
			end

			it "returns nil if record doesn't have the attribute set" do
				@entry.should_receive( :[] ).with( 'glumpy' ).and_return( nil )
				@branch[ :glumpy ].should == nil
			end

			it "caches the value fetched from its entry" do
				@schema.stub( :attribute_types ).and_return({ :glump => @attribute_type })
				@attribute_type.stub( :single? ).and_return( true )
				@attribute_type.stub( :syntax ).and_return( @syntax )
				@directory.stub( :convert_to_object ).and_return {|_,str| str }
				@entry.should_receive( :[] ).with( 'glump' ).once.and_return( [:a_value] )
				2.times { @branch[ :glump ] }
			end

			it "maps attributes through its directory" do
				@schema.should_receive( :attribute_types ).and_return({ :bvector => @attribute_type })
				@attribute_type.should_receive( :single? ).and_return( true )
				@entry.should_receive( :[] ).with( 'bvector' ).at_least( :once ).
					and_return([ '010011010101B' ])
				@syntax.stub( :oid ).and_return( OIDS::BIT_STRING_SYNTAX )
				@directory.should_receive( :convert_to_object ).
					with( OIDS::BIT_STRING_SYNTAX, '010011010101B' ).
					and_return( 1237 )

				@branch[ :bvector ].should == 1237
			end

		end

		### Attribute writer
		describe "index set operator" do

			it "writes a single value attribute via its directory" do
				@directory.should_receive( :modify ).with( @branch, { 'glumpy' => ['gits'] } )
				@entry.should_receive( :[]= ).with( 'glumpy', ['gits'] )
				@branch[ :glumpy ] = 'gits'
			end

			it "writes multiple attribute values via its directory" do
				@directory.should_receive( :modify ).with( @branch, { 'glumpy' => ['gits', 'crumps'] } )
				@entry.should_receive( :[]= ).with( 'glumpy', ['gits', 'crumps'] )
				@branch[ :glumpy ] = [ 'gits', 'crumps' ]
			end

			it "clears the cache after a successful write" do
				@schema.stub( :attribute_types ).and_return({ :glorpy => @attribute_type })
				@attribute_type.stub( :single? ).and_return( true )
				@attribute_type.stub( :syntax ).and_return( @syntax )
				@directory.stub( :convert_to_object ).and_return {|_,val| val }
				@entry.should_receive( :[] ).with( 'glorpy' ).and_return( [:firstval], [:secondval] )

				@directory.should_receive( :modify ).with( @branch, {'glorpy' => ['chunks']} )
				@directory.stub( :convert_to_attribute ).and_return {|_,val| val }
				@entry.should_receive( :[]= ).with( 'glorpy', ['chunks'] )

				@branch[ :glorpy ].should == :firstval
				@branch[ :glorpy ] = 'chunks'
				@branch[ :glorpy ].should == :secondval
			end
		end

		it "can fetch multiple values via #values_at" do
			@branch.should_receive( :[] ).with( :cn ).and_return( :cn_value )
			@branch.should_receive( :[] ).with( :desc ).and_return( :desc_value )
			@branch.should_receive( :[] ).with( :l ).and_return( :l_value )

			@branch.values_at( :cn, :desc, :l ).should == [ :cn_value, :desc_value, :l_value ]
		end

	end

end


# vim: set nosta noet ts=4 sw=4:
