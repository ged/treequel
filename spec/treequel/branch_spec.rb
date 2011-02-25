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
### C O N T E X T S
#####################################################################

describe Treequel::Branch do

	before( :all ) do
		setup_logging( :fatal )
	end

	after( :all ) do
		reset_logging()
	end

	before( :each ) do
		@conn = mock( "ldap connection object", :bound? => false )
		@directory = get_fixtured_directory( @conn )
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

	it "can be constructed from an entry returned from LDAP::Conn.search_ext2"	do
		entry = {
			'dn'				=> [TEST_PERSON_DN],
			TEST_PERSON_DN_ATTR => TEST_PERSON_DN_VALUE,
		}
		branch = Treequel::Branch.new_from_entry( entry, @directory )

		branch.rdn_attributes.should == { TEST_PERSON_DN_ATTR => [TEST_PERSON_DN_VALUE] }
		branch.entry.should == { TEST_PERSON_DN_ATTR => TEST_PERSON_DN_VALUE }
		branch.dn.should == entry['dn'].first
	end

	it "can be constructed from an entry with Symbol keys"	do
		entry = {
			:dn					=> [TEST_PERSON_DN],
			TEST_PERSON_DN_ATTR => TEST_PERSON_DN_VALUE,
		}
		branch = Treequel::Branch.new_from_entry( entry, @directory )

		branch.rdn_attributes.should == { TEST_PERSON_DN_ATTR => [TEST_PERSON_DN_VALUE] }
		branch.entry.should == {
			TEST_PERSON_DN_ATTR => TEST_PERSON_DN_VALUE,
		}
		branch.dn.should == entry[:dn].first
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
			@entry = {
				'description' => ["A string", "another string"],
				'l' => [ 'Antartica', 'Galapagos' ],
				'objectClass' => ['organizationalUnit'],
				'rev' => ['03eca02ba232'],
				'ou' => ['Hosts'],
			}
			@conn.stub( :bound? ).and_return( false )
			@conn.stub( :search_ext2 ).
				with( TEST_HOSTS_DN, LDAP::LDAP_SCOPE_BASE, "(objectClass=*)" ).
				and_return([ @entry ])
			@branch = Treequel::Branch.new( @directory, TEST_HOSTS_DN )
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


		it "knows that it hasn't loaded its entry yet if it's nil" do
			@branch.loaded?.should be_false()
		end

		it "knows that it has loaded its entry if it's non-nil" do
			@branch.instance_variable_set( :@entry, {} )
			@branch.loaded?.should be_true()
		end

		it "knows that it exists in the directory if it can fetch its entry" do
			@branch.exists?.should be_true()
		end

		it "knows that it doesn't exist in the directory if it can't fetch its entry" do
			@conn.stub( :search_ext2 ).
				with( TEST_HOSTS_DN, LDAP::LDAP_SCOPE_BASE, "(objectClass=*)" ).
				and_return([])
			@branch.exists?.should be_false()
		end

		it "fetch their LDAP::Entry from the directory if they don't already have one" do
			@conn.should_receive( :search_ext2 ).
				with( TEST_HOSTS_DN, LDAP::LDAP_SCOPE_BASE, "(objectClass=*)" ).
				exactly( :once ).
				and_return([ @entry ])

			@branch.entry.should == @entry
			@branch.entry.should == @entry # this should fetch the cached one
		end

		it "fetch their LDAP::Entry with operational attributes if include_operational_attrs is set" do
			@conn.should_receive( :search_ext2 ).
				with( TEST_HOSTS_DN, LDAP::LDAP_SCOPE_BASE, "(objectClass=*)", ["*", "+"] ).once.
				and_return([ @entry ])

			@branch.include_operational_attrs = true
			@branch.entry.should == @entry
		end

		it "can search its directory for values using itself as a base" do
			subentry = {'objectClass' => ['ipHost'], 'dn' => [TEST_HOST_DN] }
			@conn.should_receive( :search_ext2 ).
				with( TEST_HOSTS_DN, LDAP::LDAP_SCOPE_ONELEVEL, "(objectClass=*)", 
					  ["*"], false, nil, nil, 0, 0, 0, "", nil ).
				and_return([ subentry ])

			branches = @branch.search( :one, '(objectClass=*)' )

			branches.should have( 1 ).member
			branches.first.should be_a( Treequel::Branch )
			branches.first.dn.should == TEST_HOST_DN
		end

		it "can search its directory for values with a block" do
			subentry = {
				'objectClass' => ['ipHost'],
				TEST_HOST_DN_ATTR => [TEST_HOST_DN_VALUE],
				'dn' => [TEST_HOST_DN],
			}
			@conn.should_receive( :search_ext2 ).
				with( TEST_HOSTS_DN, LDAP::LDAP_SCOPE_ONELEVEL, "(objectClass=*)", 
					  ["*"], false, nil, nil, 0, 0, 0, "", nil ).
				and_return([ subentry ])

			yielded_val = nil
			@branch.search( :one, '(objectClass=*)' ) do |val|
				yielded_val = val
			end
			yielded_val.should be_a( Treequel::Branch )
			yielded_val.entry.should == {
				'objectClass' => ['ipHost'],
				TEST_HOST_DN_ATTR => [TEST_HOST_DN_VALUE],
			}
		end

		it "clears any cached values if its include_operational_attrs attribute is changed" do
			@directory.should_receive( :get_entry ).with( @branch ).exactly( :once ).
				and_return( TEST_PEOPLE_ENTRY.dup )
			@directory.should_receive( :get_extended_entry ).with( @branch ).exactly( :once ).
				and_return( TEST_OPERATIONAL_PEOPLE_ENTRY.dup )

			@branch.entry.should == TEST_PEOPLE_ENTRY.dup.tap {|entry| entry.delete('dn') }
			@branch.include_operational_attrs = true
			@branch.entry.should == TEST_OPERATIONAL_PEOPLE_ENTRY.dup.tap {|entry| entry.delete('dn') }
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
			rval = @branch.cn( 'rondori' )
			rval.dn.should == "cn=rondori,#{TEST_HOSTS_DN}"

			rval2 = rval.ou( 'Config' )
			rval2.dn.should == "ou=Config,cn=rondori,#{TEST_HOSTS_DN}"
		end

		it "create sub-branches for messages with additional attribute pairs" do
			rval = @branch.cn( 'rondori', :l => 'Portland' )
			rval.dn.should == "cn=rondori+l=Portland,#{TEST_HOSTS_DN}"

			rval2 = rval.ou( 'Config' )
			rval2.dn.should == "ou=Config,cn=rondori+l=Portland,#{TEST_HOSTS_DN}"
		end

		it "don't create sub-branches for messages that don't match valid attributeType OIDs" do
			@conn.stub( :bound? ).and_return( false )
			expect {
				@branch.facelart( 'sbc' )
			}.to raise_exception( NoMethodError, /undefined method.*facelart/i )
		end

		it "don't create sub-branches for multi-value RDNs with an invalid attribute" do
			@conn.stub( :bound? ).and_return( false )
			expect {
				@branch.cn( 'benchlicker', :facelart => 'sbc' )
			}.to raise_exception( NoMethodError, /invalid secondary attribute.*facelart/i )
		end

		it "can return all of its immediate children as Branches" do
			@directory.should_receive( :search ).with( @branch, :one, '(objectClass=*)', {} ).
				and_return([ :the_children ])
			@branch.children.should == [ :the_children ]
		end

		it "can return its parent as a Branch" do
			@branch.parent.should be_a( Treequel::Branch )
			@branch.parent.dn.should == TEST_BASE_DN
		end


		it "returns nil if a Branch for the base DN is asked for its parent" do
			@branch.parent.parent.should be_nil()
		end


		it "can construct a Treequel::Branchset that uses it as its base" do
			@branch.branchset.should be_a( Treequel::Branchset )
			@branch.branchset.base_dn.should == @branch.dn
		end

		it "can create a filtered Treequel::Branchset for itself" do
			branchset = @branch.filter( :cn => 'acme' )

			branchset.should be_a( Treequel::Branchset )
			branchset.filter_string.should =~ /\(cn=acme\)/
		end

		it "can create a Treequel::Branchset from itself that returns instances of another class" do
			otherclass = Class.new( Treequel::Branch )
			branchset = @branch.as( otherclass )

			branchset.should be_a( Treequel::Branchset )
			branchset.branch.should be_a( otherclass )
		end

		it "doesn't restrict the number of arguments passed to #filter (bugfix)" do
			branchset = @branch.filter( :uid => [:rev, :grumpy, :glee] )

			branchset.should be_a( Treequel::Branchset )
			branchset.filter_string.should =~ /\(\|\(uid=rev\)\(uid=grumpy\)\(uid=glee\)\)/i
		end

		it "can create a scoped Treequel::Branchset for itself" do
			branchset = @branch.scope( :onelevel )

			branchset.should be_a( Treequel::Branchset )
			branchset.scope.should == :onelevel
		end

		it "can create a selective Treequel::Branchset for itself" do
			branchset = @branch.select( :uid, :l, :familyName, :givenName )

			branchset.should be_a( Treequel::Branchset )
			branchset.select.should == %w[uid l familyName givenName]
		end

		it "knows which objectClasses it has" do
			@branch.object_classes.
				should include( @directory.schema.object_classes[:organizationalUnit] )
		end

		it "knows what operational attributes it has" do
			op_attrs = @directory.schema.attribute_types.values.select do |attrtype|
				attrtype.operational?
			end.uniq

			@branch.operational_attribute_types.should have( op_attrs.length ).members
			@branch.operational_attribute_types.should include( *op_attrs )
		end

		it "knows what the OIDs of its operational attributes are" do
			op_numeric_oids = @directory.schema.attribute_types.values.select do |attrtype|
				attrtype.operational?
			end.uniq.map( &:oid )
			op_names = @directory.schema.attribute_types.values.select do |attrtype|
				attrtype.operational?
			end.uniq.map( &:names ).flatten

			op_oids = op_numeric_oids + op_names

			@branch.operational_attribute_oids.should have( op_oids.length ).members
			@branch.operational_attribute_oids.should include( *op_oids )
		end

		it "can return the set of all its MUST attributes' OIDs based on which objectClasses " +
		   "it has" do
			@conn.stub( :search_ext2 ).
				with( TEST_HOSTS_DN, LDAP::LDAP_SCOPE_BASE, "(objectClass=*)" ).
				and_return([ {'objectClass' => %w[ipHost device ieee802device]} ])

			must_oids = @branch.must_oids
			must_oids.should have( 3 ).members
			must_oids.should include( :objectClass, :cn, :ipHostNumber )
		end

		it "can return the set of all its MUST attributeTypes based on which objectClasses it has" do
			@conn.stub( :search_ext2 ).
				with( TEST_HOSTS_DN, LDAP::LDAP_SCOPE_BASE, "(objectClass=*)" ).
				and_return([ {'objectClass' => %w[ipHost device ieee802device]} ])

			expected_attrtypes = @directory.schema.attribute_types.
				values_at( :objectClass, :cn, :ipHostNumber )

			must_attrs = @branch.must_attribute_types
			must_attrs.should have( 3 ).members
			must_attrs.should include( *expected_attrtypes )
		end

		it "can return a Hash pre-populated with pairs that correspond to its MUST attributes" do
			@conn.stub( :search_ext2 ).
				with( TEST_HOSTS_DN, LDAP::LDAP_SCOPE_BASE, "(objectClass=*)" ).
				and_return([ {'objectClass' => %w[ipHost device ieee802device]} ])

			@branch.must_attributes_hash.
				should include({ :cn => [''], :ipHostNumber => [''], :objectClass => ['top'] })
		end


		it "can return the set of all its MAY attributes' OIDs based on which objectClasses " +
		   "it has" do
			@conn.stub( :search_ext2 ).
				with( TEST_HOSTS_DN, LDAP::LDAP_SCOPE_BASE, "(objectClass=*)" ).
				and_return([ {'objectClass' => %w[ipHost device ieee802device]} ])

			must_oids = @branch.may_oids
			must_oids.should have( 9 ).members
			must_oids.should include( :l, :description, :manager, :serialNumber, :seeAlso, 
				:owner, :ou, :o, :macAddress )
		end

		it "can return the set of all its MAY attributeTypes based on which objectClasses it has" do
			@conn.should_receive( :search_ext2 ).
				with( TEST_HOSTS_DN, LDAP::LDAP_SCOPE_BASE, "(objectClass=*)" ).
				and_return([ {'objectClass' => %w[ipHost device ieee802device]} ])

			expected_attrtypes = @directory.schema.attribute_types.values_at( :l, :description, 
				:manager, :serialNumber, :seeAlso, :owner, :ou, :o, :macAddress )

			@branch.may_attribute_types.should include( *expected_attrtypes )
		end

		it "can return a Hash pre-populated with pairs that correspond to its MAY attributes" do
			@conn.should_receive( :search_ext2 ).
				with( TEST_HOSTS_DN, LDAP::LDAP_SCOPE_BASE, "(objectClass=*)" ).
				and_return([ {'objectClass' => %w[ipHost device ieee802device]} ])

			@branch.may_attributes_hash.should include({
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

			all_attrs.should have( 57 ).members
			all_attrs.should include( @directory.schema.attribute_types[:ou] )
			all_attrs.should include( @directory.schema.attribute_types[:l] )
		end


		it "can return a Hash pre-populated with pairs that correspond to all of its valid " +
		   "attributes" do
			@branch.valid_attributes_hash.should == {
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
			}
		end


		it "can return the set of all of its valid attribute OIDs, which is a union of its " +
		   "MUST and MAY attribute OIDs" do
			all_attr_oids = @branch.valid_attribute_oids

			all_attr_oids.should have( 23 ).members all_attr_oids.should include( 
				:objectClass, :ou,
				:userPassword, :searchGuide, :seeAlso, :businessCategory, :x121Address,
				:registeredAddress, :destinationIndicator, :telexNumber, :teletexTerminalIdentifier,
				:telephoneNumber, :internationaliSDNNumber, :facsimileTelephoneNumber, :street,
				:postOfficeBox, :postalCode, :postalAddress, :physicalDeliveryOfficeName, :st, :l,
				:description, :preferredDeliveryMethod
			 )
		end

		it "knows if an attribute is valid given its objectClasses" do
			@branch.valid_attribute?( :ou ).should be_true()
			@branch.valid_attribute?( :rubberChicken ).should be_false()
		end

		it "can be moved to a new location within the directory" do
			newdn = "ou=oldhosts,#{TEST_BASE_DN}"
			@conn.should_receive( :modrdn ).
				with( TEST_HOSTS_DN, "ou=oldhosts", true )
			@branch.move( newdn )
		end


		it "resets any cached data when its DN changes" do
			@conn.should_receive( :search_ext2 ).
				with( TEST_HOSTS_DN, LDAP::LDAP_SCOPE_BASE, "(objectClass=*)" ).
				and_return([ @entry ])
			@branch.entry

			@branch.dn = TEST_SUBHOSTS_DN

			@conn.should_receive( :search_ext2 ).
				with( TEST_SUBHOSTS_DN, LDAP::LDAP_SCOPE_BASE, "(objectClass=*)" ).
				and_return([ @entry ])
			@branch.entry
		end


		it "can create children under itself" do
			newattrs = {
				:ipHostNumber => '127.0.0.1',
				:objectClass  => [:ipHost, :device],
			}

			@conn.should_receive( :add ).
				with( "cn=chillyt,#{TEST_HOSTS_DN}",
				      "ipHostNumber"=>["127.0.0.1"],
				      "objectClass"=>["ipHost", "device"] )

			res = @branch.cn( :chillyt ).create( newattrs )
			res.should be_a( Treequel::Branch )
			res.dn.should == "cn=chillyt,#{TEST_HOSTS_DN}"
		end


		it "can copy itself to a sibling entry" do
			@conn.should_receive( :add ).with( TEST_SUBHOSTS_DN, @entry )

			newbranch = @branch.copy( TEST_SUBHOSTS_DN )
			newbranch.dn.should == TEST_SUBHOSTS_DN
		end


		it "can copy itself to a sibling entry with attribute changes" do
			@conn.should_receive( :add ).
				with( TEST_SUBHOSTS_DN, @entry.merge('description' => ['Hosts in a subdomain.']) )

			newbranch = @branch.copy( TEST_SUBHOSTS_DN, :description => ['Hosts in a subdomain.'] )
			newbranch.dn.should == TEST_SUBHOSTS_DN
		end


		it "can modify its entry's attributes en masse by merging a Hash" do
			attributes = {
				:displayName => 'Chilly T. Penguin',
				:description => "A chilly little penguin.",
			}
			@conn.should_receive( :modify ).
				with( TEST_HOSTS_DN,
				      'displayName' => ['Chilly T. Penguin'],
				      'description' => ["A chilly little penguin."] )

			@branch.merge( attributes )
		end


		it "can delete all values of one of its entry's individual attributes" do
			mod = LDAP::Mod.new( LDAP::LDAP_MOD_DELETE, 'displayName', [] )
			@conn.should_receive( :modify ).with( TEST_HOSTS_DN, [mod] )
			@branch.delete( :displayName )
		end

		it "can delete all values of more than one of its entry's individual attributes" do
			mod1 = LDAP::Mod.new( LDAP::LDAP_MOD_DELETE, 'displayName', [] )
			mod2 = LDAP::Mod.new( LDAP::LDAP_MOD_DELETE, 'gecos', [] )
			@conn.should_receive( :modify ).with( TEST_HOSTS_DN, [mod1, mod2] )

			@branch.delete( :displayName, :gecos )
		end

		it "can delete one particular value of its entry's individual attributes" do
			mod = LDAP::Mod.new( LDAP::LDAP_MOD_DELETE, 'objectClass', ['apple-user'] )
			@conn.should_receive( :modify ).with( TEST_HOSTS_DN, [mod] )

			@branch.delete( :objectClass => 'apple-user' )
		end

		it "can delete one particular non-String value of its entry's individual attributes" do
			mod = LDAP::Mod.new( LDAP::LDAP_MOD_DELETE, 'pwdChangedTime', ['20000101201501Z'] )
			@conn.should_receive( :modify ).with( TEST_HOSTS_DN, [mod] )

			@branch.delete( :pwdChangedTime => Time.gm(2000,"jan",1,20,15,1) )
		end

		it "can delete particular values of more than one of its entry's individual attributes" do
			mod1 = LDAP::Mod.new( LDAP::LDAP_MOD_DELETE, 'objectClass',
			                      ['apple-user', 'inetOrgPerson'] )
			mod2 = LDAP::Mod.new( LDAP::LDAP_MOD_DELETE, 'cn', [] )
			@conn.should_receive( :modify ).with( TEST_HOSTS_DN, array_including(mod1, mod2) )

			@branch.delete( :objectClass => ['apple-user',:inetOrgPerson], :cn => [] )
		end

		it "deletes its entry entirely if no attributes are specified" do
			@conn.should_receive( :delete ).with( TEST_HOSTS_DN )
			@branch.delete
		end


		it "knows how to represent its DN as an RFC1781-style UFN" do
			@branch.to_ufn.should =~ /Hosts, acme\.com/i
		end


		it "knows how to represent itself as LDIF" do
			ldif = @branch.to_ldif
			ldif.should =~ /dn: #{TEST_HOSTS_DN_ATTR}=#{TEST_HOSTS_DN_VALUE},#{TEST_BASE_DN}/i
			ldif.should =~ /description: A string/
			ldif.should =~ /description: another string/
			ldif.should =~ /l: Antartica/
			ldif.should =~ /l: Galapagos/
			ldif.should =~ /ou: Hosts/
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
			@conn.stub( :search_ext2 ).
				with( TEST_HOSTS_DN, LDAP::LDAP_SCOPE_BASE, "(objectClass=*)" ).
				and_return([ entry ])

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
			entry = {
				'description' => [LONG_BINARY_TEST_VALUE],
				'l' => [ 'Antartica', 'Galapagos' ]
			}
			@conn.stub( :search_ext2 ).
				with( TEST_HOSTS_DN, LDAP::LDAP_SCOPE_BASE, "(objectClass=*)" ).
				and_return([ entry ])

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
			@branch.to_hash.should == {
				'description' => ['A string', 'another string'],
				'l' => [ 'Antartica', 'Galapagos' ],
				'objectClass' => ['organizationalUnit'],
				'ou' => ['Hosts'],
				'rev' => ['03eca02ba232']
			}
		end

		it "returns a Treequel::BranchCollection with equivalent Branchsets if added to another " +
		   "Branch" do
			other_branch = Treequel::Branch.new( @directory, TEST_SUBHOSTS_DN )

			coll = (@branch + other_branch)

			coll.should be_a( Treequel::BranchCollection )
			coll.branchsets.should have( 2 ).members
			coll.branchsets.map( &:base_dn ).should include( TEST_HOSTS_DN, TEST_SUBHOSTS_DN )
		end


		### Attribute reader
		describe "index fetch operator" do

			it "fetches a multi-value attribute as an Array of Strings" do
				entry = {
					'description' => ["A string", "another string"],
					'l' => [ 'Antartica', 'Galapagos' ],
					'objectClass' => ['organizationalUnit'],
				}
				@conn.should_receive( :search_ext2 ).
					with( TEST_HOSTS_DN, LDAP::LDAP_SCOPE_BASE, "(objectClass=*)" ).
					and_return([ entry ])

				@branch[ :description ].should include( 'A string', 'another string' )
				@branch[ :l ].should include( 'Galapagos', 'Antartica' )
			end

			it "fetches an empty Array if a record doesn't have an attribute set" do
				@branch[ :cn ].should == []
			end

			it "fetches an empty Array for an attribute if the entry doesn't exist" do
				@conn.stub( :search_ext2 ).
					with( TEST_HOSTS_DN, LDAP::LDAP_SCOPE_BASE, "(objectClass=*)" ).
					and_return( [] )
				@branch[ :cn ].should == []
			end

			it "fetches a single-value attribute as a scalar String" do
				test_dn = "cn=ssh,cn=www,#{TEST_HOSTS_DN}"
				entry = {
					'ipServicePort' => ['22'],
					'ipServiceProtocol' => ['tcp'],
					'objectClass' => ['ipService'],
					'cn' => ['www'],
				}
				@conn.should_receive( :search_ext2 ).
					with( test_dn, LDAP::LDAP_SCOPE_BASE, "(objectClass=*)" ).
					and_return([ entry ])

				branch = Treequel::Branch.new( @directory, test_dn )

				branch[ :ipServicePort ].should == 22
				branch[ :ipServiceProtocol ].should == ['tcp']
			end

			it "returns the entry without conversion if there is no such attribute in the schema" do
				@branch[ :rev ].should == [ '03eca02ba232' ]
			end

			it "returns nil if a record doesn't have a SINGLE-type attribute set" do
				@branch[ :displayName ].should == nil
			end

			it "caches the value fetched from its entry" do
				@conn.should_receive( :search_ext2 ).
					with( TEST_HOSTS_DN, LDAP::LDAP_SCOPE_BASE, "(objectClass=*)" ).
					exactly( :once ).
					and_return([ @entry ])

				2.times { @branch[ :description ] }
			end

			it "doesn't cache nil values that don't correspond to an attribute type in the schema" do
				@conn.should_receive( :search_ext2 ).
					with( TEST_HOSTS_DN, LDAP::LDAP_SCOPE_BASE, "(objectClass=*)" ).
					and_return([ @entry ])

				@branch[ :string_beans ]
				@branch.instance_variable_get( :@values ).should_not have_key( :string_beans )
			end

			it "freezes the values fetched from its entry by default to prevent accidental " +
			   "in-place modification" do
				@conn.should_receive( :search_ext2 ).
					with( TEST_HOSTS_DN, LDAP::LDAP_SCOPE_BASE, "(objectClass=*)" ).
					exactly( :once ).
					and_return([ @entry ])

				expect {
					@branch[ :description ] << "Another description"
				}.to raise_error( /can't modify frozen/i )
			end

			it "doesn't freeze the values fetched from its entry if it's told not to" do
				@conn.should_receive( :search_ext2 ).
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
				@conn.should_receive( :search_ext2 ).
					with( test_dn, LDAP::LDAP_SCOPE_BASE, "(objectClass=*)" ).
					and_return([ entry ])

				branch = Treequel::Branch.new( @directory, test_dn )

				branch[ :ipServicePort ].should be_a( Fixnum )
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
				@conn.should_receive( :search_ext2 ).
					with( test_dn, LDAP::LDAP_SCOPE_BASE, "(objectClass=*)" ).
					and_return([ entry ])
				branch = Treequel::Branch.new( @directory, test_dn )

				@conn.should_receive( :modify ).
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
				@conn.should_receive( :search_ext2 ).
					with( test_dn, LDAP::LDAP_SCOPE_BASE, "(objectClass=*)" ).
					and_return([ entry ])
				branch = Treequel::Branch.new( @directory, test_dn )

				@conn.should_receive( :modify ).
					with( test_dn, "apple-computers" => 
						  ["chernobyl", "beetlejuice", "toronaga", "glider", "creeper"] )

				branch[ 'apple-computers' ] += %w[glider creeper]
			end

			it "writes multiple attribute values via its directory" do
				test_dn = "cn=ssh,cn=www,#{TEST_HOSTS_DN}"
				branch = Treequel::Branch.new( @directory, test_dn )

				@conn.should_receive( :modify ).
					with( test_dn, 
						  'ipServicePort' => ['56'],
						  'ipServiceProtocol' => ['udp']
					  )

				branch.merge( :ipServicePort => 56, :ipServiceProtocol => 'udp' )
			end
		end

		it "can fetch multiple values via #values_at" do
			results = @branch.values_at( TEST_HOSTS_DN_ATTR, :description )

			results.should have( 2 ).members
			results.first.should == [TEST_HOSTS_DN_VALUE]
			results.last.should == @entry['description']
		end

	end

end


# vim: set nosta noet ts=4 sw=4:
