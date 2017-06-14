---
title: Working With Branches
layout: default
index: 4
filters:
  - erb
  - links
  - examples
  - editorial
  - api
  - textile
example_prelude: |-
  require 'treequel'
  dir = Treequel.directory
---

<div id="auto-toc"></div>

h2(#branches). Working With Branches

Once you've established a connection to a directory, you can fetch entries from the directory hierarchy by traversing the directory hierarchy using Branches. A Branch (<?api Treequel::Branch ?>) is just a wrapper around a DN. The wrapped DN doesn't necessarily need to map to an extant entry in the directory; the entry behind it isn't fetched until it's needed for something. 

You can get a Branch for a DN in several ways. The easiest, once you have a @Directory@, is to use the <abbr title="Relative Distinguished Name">RDN</abbr> from the base of the directory to fetch it. You can fetch a @Branch@ from a @Directory@ or any other @Branch@ by calling a method on it with the same name as one of the attributes of the @RDN@ you want to traverse, and passing the value as the first argument to that method.

For instance, my company's directory has people organized under a top-level <abbr title="Organizational Unit">OU</abbr> called "people", so I can fetch a @Branch@ for it like so:

<?example { language: irb, caption: "Fetching a branch ou=people." } ?>
irb> people = dir.ou( :people )
# => #<Treequel::Branch:0x19a76d4 ou=people,dc=acme,dc=com @ localhost:389 (dc=acme,dc=com, tls, anonymous) entry=nil>
irb> people.dn
# => "ou=people,dc=acme,dc=com"
<?end?>

Then you can fetch branches for individuals under @ou=People@ by calling their @RDN@ method, too. Since I happen to know that all of my company's People are keyed by @uid@, everyone's @RDN@ from @ou=People@ will be @uid=something@:

<?example { language: irb, caption: "Fetching a branch for uid=mgranger,ou=people." } ?>
irb> me = people.uid( :mgranger )
# => #<Treequel::Branch:0x19a4970 uid=mgranger,ou=people,dc=acme,dc=com @ localhost:389 (dc=acme,dc=com, tls, anonymous) entry=nil>
irb> me.dn
# => "uid=mgranger,ou=people,dc=acme,dc=com"
<?end?>

You can pass any additional attributes in the @RDN@ (if you have entries with multi-value @RDNs@) as a Hash:

<?example { language: irb, caption: "Fetching a branch for an entry with a multi-value RDN." } ?>
irb> hosts = dir.ou( :hosts )
# => #<Treequel::Branch:0x19a76d4 ou=hosts,dc=acme,dc=com @ localhost:389 (dc=acme,dc=com, tls, anonymous) entry=nil>
irb> hosts.cn( :ns1, :l => 'newyork' ).dn
# => "cn=ns1+l=newyork,ou=hosts,dc=acme,dc=com"
<?end?>

You can also create a Branch from the directory that contains it and its full DN:

<?example { language: irb, caption: "Fetching a branch using its DN." } ?>
irb> me = Treequel::Branch.new( dir, 'uid=mgranger,ou=people,dc=acme,dc=com' )
# => #<Treequel::Branch:0x12b676c uid=mgranger,ou=people,dc=acme,dc=com @ localhost:389 (dc=acme,dc=com, tls, anonymous) entry=nil>
<?end?>

or from a raw @LDAP::Entry@ object:

<?example { language: irb, caption: "Fetching a branch using its DN." } ?>
irb> conn = LDAP::SSLConn.new( 'localhost', 389, true )
# => #<LDAP::SSLConn:0x58bd94>
irb> entries = conn.search2( 'ou=people,dc=acme,dc=com', LDAP::LDAP_SCOPE_SUBTREE, '(uid=mgranger)' )
# => [{"gidNumber"=>["200"], "cn"=>["Michael Granger"], [...], "dn"=>["uid=mgranger,ou=People,dc=acme,dc=com"]}]
irb> me = Treequel::Branch.new_from_entry( entries.first, dir )
# => #<Treequel::Branch:0x129dd70 uid=mgranger,ou=People,dc=acme,dc=com @ localhost:389 (dc=acme,dc=com, tls, anonymous) entry={...}>
<?end?>

The directory also provides a special @Branch@ object for its base DN that's used to respond to any Branch methods called on it:

<?example { language: irb, caption: "Fetching the directory's base branch." } ?>
irb> dir.base
# => #<Treequel::Branch:0x1368548 dc=acme,dc=com @ localhost:389 (dc=acme,dc=com, tls, anonymous) entry=nil>
irb> dir.base.dn
# => "dc=acme,dc=com"
irb> dir.dn
# => "dc=acme,dc=com"
irb> dir.base.ou( :people )
# => #<Treequel::Branch:0x117f45c ou=people,dc=acme,dc=com @ localhost:389 (dc=acme,dc=com, tls, anonymous) entry=nil>
irb> dir.ou( :people )
# => #<Treequel::Branch:0x11850f0 ou=people,dc=acme,dc=com @ localhost:389 (dc=acme,dc=com, tls, anonymous) entry=nil>
<?end?>


Branches are also returned as the results from a search, but "that will be covered a little later":#searching-with-branchsets.

h3(#entries). The Branch's Entry

Once you have a Branch, you can fetch its corresponding entry from the directory via the @#entry@ method. If the entry doesn't exist, @#entry@ will return @nil@. You can test to see whether an entry for a branch exists via its @#exists?@ predicate method:

<?example { language: irb, caption: "Examining a Branch's entry." } ?>
irb> www = dir.ou( :hosts ).cn( :www )
# => #<Treequel::Branch:0x1932f8c cn=www,ou=hosts,dc=acme,dc=com @ localhost:389 (dc=acme,dc=com, tls, cn=admin,dc=acme,dc=com) entry=nil>
irb> www.exists?
# => true
irb> www.entry
# => {"cn"=>["www"], "ipHostNumber"=>["127.0.0.1"], "objectClass"=>["device", "ipHost"], "dn"=>["cn=www,ou=hosts,dc=acme,dc=com"]}
<?end?>

h3(#attributes). Attributes

Once you have a the Branch for the entry you need, you can also fetch its attributes just like a Hash:

<?example { language: irb, caption: "Fetching an attribute." } ?>
irb> me = people.uid( :mgranger )
irb> me[:gecos]
# => "Michael Granger"
<?end?>

If you have write privileges on the entry, you can set attributes the same way:

<?example { language: irb, caption: "Setting an attribute." } ?>
irb> dir.bound_as( me, 'password' ) { me[:gecos] = "Pasoquod Singular" }
irb> me[:gecos] 
# => "Pasoquod Singular"
<?end?>

Changes to the branch are written to the directory as soon as they're made, so if you have several attributes to change, you'll likely want to make them all at once for efficiency.

You can do that with the @#merge@ method:

<?example { language: irb, caption: "Merging attributes." } ?>
irb> me.merge( :gecos => 'Michael Granger', :uidNumber => 514 )
<?end?>

h3(#attribute-datatypes). Attribute Datatypes

Attribute values are cast to Ruby objects and vice-versa based on the "syntax rule":http://tools.ietf.org/html/rfc4517#section-3.3 that corresponds to its attribute type. By default, all attribute values from LDAP are mapped to <code>String</code>s except those contained in <var>Treequel::Directory::DEFAULT_ATTRIBUTE_CONVERSIONS</var>, which is a mapping of syntax rule <code>OID</code>s to an object which converts the @String@ value from the directory into a Ruby object. This object can be of any type which responds to @#call@, in which case it will be called with the attribute and the @Directory@ it belongs to, or to @#[]@ with a @String@ argument, e.g., a  @Hash@:

<?example { language: irb, caption: "Convert integer values to Ruby Integers" } ?>
irb> dir.add_attribute_conversion( Treequel::OIDS::INTEGER_SYNTAX ) {|string, _| Integer(string) }
# => #<Proc:0x00507080@(irb):3>
irb> dir.convert_to_object( Treequel::OIDS::INTEGER_SYNTAX, "181" )
# => 181
<?end ?>

This is, incidentally, how every attribute that's a <abbr title="Distingished Name">DN</abbr> gets returned as a @Treequel::Branch@ instead of the DN string. If you were doing this yourself (or wanted to override the conversion to return something else), you do:

<?example { language: irb, caption: "Mapping DNs to Treequel::Branches" } ?>
irb> dir = Treequel.directory 
# => #<Treequel::Directory:0x665783 localhost:389 (connected) base_dn="dc=acme,dc=com", bound as=anonymous, schema=(schema not loaded)>
irb> dir.add_attribute_conversion( Treequel::OIDS::DISTINGUISHED_NAME_SYNTAX ) {|dn, dir| Treequel::Branch.new(dir, dn) }
# => #<Proc:0x0198ddd8@(irb):2>
irb> sales_dept = dir.ou( :departments ).cn( :sales )
# => #<Treequel::Branch:0x18def54 cn=sales,ou=departments,dc=acme,dc=com @ localhost:389 (dc=acme,dc=com, tls, anonymous) entry=nil>
irb> sales_dept['supervisor']
# => #<Treequel::Branch:0x18db228 uid=mahlon,ou=People,dc=acme,dc=com @ localhost:389 (dc=acme,dc=com, tls, anonymous) entry=nil>
<?end?>

You could also do this by setting the @Directory.results_class@, but that'll come up later in the section about "Models":#treequel-model.

To map Ruby objects back into LDAP attribute strings, there's a corollary to the <var>DEFAULT_ATTRIBUTE_CONVERSIONS</var> called <var>DEFAULT_OBJECT_CONVERSIONS</var> that works the same way, but in reverse. The values registered with it are given the Ruby object and the @Directory@, and return the LDAP-encoded String:

<?example { language: irb, caption: "Convert objects to LDAP bit strings" } ?>
irb> dir.add_object_conversion( Treequel::OIDS::BIT_STRING_SYNTAX ) {|bs, _| bs.to_i.to_s(2) }
# => #<Proc:0x00000101840d80@(irb):3>
irb> dir.convert_to_attribute( Treequel::OIDS::BIT_STRING_SYNTAX, 169130 )
# => "101001010010101010"
<?end?>

<div class="callout note-callout">
Syntax mappings are per-directory, so you can establish different conversion rules for different directories. We're planning on adding a way to add or replace the default rules, too, but for now you'll have to either modify <var>Treequel::Directory::DEFAULT_ATTRIBUTE_CONVERSIONS</var> directly or
install custom mappings for each @Directory@ individually if you want the same rules for every one.
</div>

h3(#operational-attributes). Operational Attributes

In addition to its user-settable attributes, each entry in the directory also has a set of "operational attributes":http://tools.ietf.org/html/rfc4512#section-3.4 which are maintained by the server. These attributes are not normally visible, but you can enable them either for individual @Branch@ objects, or for all newly-created <code>Branch</code>es:

<?example { language: irb, caption: "Enabling the inclusion of operational attributes." } ?>
irb> dir.base.entry.keys.sort
# => ["dc", "description", "dn", "o", "objectClass"]
irb> dir.base.include_operational_attrs = true
# => true
irb> dir.base.entry.keys.sort
# => ["createTimestamp", "creatorsName", "dc", "description", "dn", "entryCSN", "entryDN", "entryUUID", "hasSubordinates", "modifiersName", "modifyTimestamp", "o", "objectClass", "structuralObjectClass", "subschemaSubentry"]
irb> Treequel::Branch.include_operational_attrs = true
# => true
irb> dir.ou( :people ).entry.keys.sort
# => ["createTimestamp", "creatorsName", "description", "dn", "entryCSN", "entryDN", "entryUUID", "hasSubordinates", "modifiersName", "modifyTimestamp", "objectClass", "ou", "structuralObjectClass", "subschemaSubentry"]
<?end?>

To see which operational attributes your directory software supports, ask the <code>Directory</code> object, which will return schema objects for each one:

<?example { language: irb, caption: "Get the list of supported operational attributes." } ?>
irb> dir.operational_attribute_types.map( &:name )
# => [:structuralObjectClass, :createTimestamp, :modifyTimestamp, :creatorsName, :modifiersName, :hasSubordinates, :subschemaSubentry, :entryDN, :entryUUID, :altServer, :namingContexts, :supportedControl, :supportedExtension, :supportedLDAPVersion, :supportedSASLMechanisms, :supportedFeatures, :vendorName, :vendorVersion, :matchingRules, :attributeTypes, :objectClasses, :matchingRuleUse, :ldapSyntaxes, :ref, :entryTtl, :dynamicSubtrees, :memberOf, :pwdChangedTime, :pwdAccountLockedTime, :pwdFailureTime, :pwdHistory, :pwdGraceUseTime, :pwdReset, :pwdPolicySubentry]
<?end?>


h3(#branch-ldif). Getting a Branch's LDIF

A convenient way to look at all of a branch's attributes is via its "LDIF":http://en.wikipedia.org/wiki/LDAP_Data_Interchange_Format string:

<?example { language: irb, caption: "Displaying a branch's entry as LDIF." } ?>
irb> puts me.to_ldif
dn: uid=mgranger,ou=people,dc=acme,dc=com
gidNumber: 200
cn: Michael Granger
l: Portland, OR
givenName: Michael
title: Lead Software Developer
gecos: Michael Granger
homeDirectory: /home/m/mgranger
uid: mgranger
mail: mgranger@acme.com
sn: Granger
mobile: +1 9075551212
loginShell: /bin/base
uidNumber: 2053
objectClass: inetOrgPerson
objectClass: organizationalPerson
objectClass: person
objectClass: top
objectClass: posixAccount
objectClass: shadowAccount
objectClass: apple-user
homePhone: +1 9075551212
departmentNumber: 18
<?end?>

h3(#heirarchical-traversal). Parents and Children

Each branch can also fetch its parent and its children:

<?example { language: irb, caption: "Fetching a branch's parent and its children." } ?>
irb> marketing_hosts = dir.dc( :marketing ).ou( :hosts )
# => #<Treequel::Branch:0x135ad94 ou=hosts,dc=marketing,dc=acme,dc=com @ localhost:389 (dc=acme,dc=com, tls, anonymous) entry=nil>
irb> marketing_hosts.parent
# => #<Treequel::Branch:0x13508d0 dc=marketing,dc=acme,dc=com @ localhost:389 (dc=acme,dc=com, tls, anonymous) entry=nil>
irb> marketing_hosts.children.map {|b| b.dn }
# => ["cn=rockbox,ou=Hosts,dc=marketing,dc=acme,dc=com", "cn=bone,ou=Hosts,dc=marketing,dc=acme,dc=com"]
<?end?>

h3(#create-copy-delete-move). Creating, Copying, Deleting, and Moving Entries

If you have a @Branch@ object for an entry which doesn't exist in the directory, you can create it via the @#create@ method. It takes any attributes that should be set when creating it, and requires at least that you provide a "structural objectClass":http://tools.ietf.org/html/rfc4512#page-18.

<?example { language: irb, caption: "Creating a new entry." } ?>
irb> mahlon_things = dir.ou( :people ).uid( :mahlon ).ou( :things )
# => #<Treequel::Branch:0xfb7b9e954 ou=things,uid=mahlon,ou=people,dc=acme,dc=com @ localhost:389 (dc=acme,dc=com, tls, anonymous) entry=nil>
irb> mahlon_things.create( :objectClass => [ 'top', 'organizationalUnit' ] )
# => true
irb> mahlon_things.cn( :thing ).create( :objectClass => 'room', :description => 'a thing' )
# => true
<?end?>

Some objectClasses require that the entry contain values for particular attributes (their @MUST@ attributes), and it's nice to be able to tell which ones you'll need if you're building tools that can create new entries. To that end, Treequel comes with a set of tools for fetching and using the information contained in a Directory's schema. We'll cover schema introspection "a little later":#schema-introspection.

You can also copy an existing entry:

<?example { language: irb, caption: "Copying an entry." } ?>
irb> dir.bind( 'cn=admin,dc=acme,dc=com', 'the_password' )
# => "cn=admin,dc=acme,dc=com"
irb> jtran = dir.ou( :people ).uid( :mahlon ).copy( 'uid=jtran', :givenName => 'Jim', :sn => 'Tran' )
# => #<Treequel::Branch:0x12bff60 uid=jtran,ou=people,dc=acme,dc=com @ localhost:389 (dc=acme,dc=com, tls, cn=admin,dc=acme,dc=com) entry=nil>
irb> jtran['sn']
# => ["Tran"]
<?end?>

or move (rename) it:

<?example { language: irb, caption: "Moving an entry." } ?>
# Rename 'Miriam Robson' to 'Miriam Price' when she gets married.
irb> user = dir.ou( :people ).uid( :mrobson ).move( 'uid=mprice', :sn => 'Price' )
# => #<Treequel::Branch:0x12bff60 uid=mprice,ou=people,dc=acme,dc=com @ localhost:389 (dc=acme,dc=com, tls, cn=admin,dc=acme,dc=com) entry=nil>
<?end?>

<?ed fixme:"Treequel currently doesn't support moving an entry to a new parent, only renaming it under its current parent, but you can always copy it to the new DN and delete the original. This will be corrected in a future version." ?>

Finally, you can delete an entry from its @Branch@, as well:

<?example { language: irb, caption: "Deleting an entry." } ?>
irb> dir.ou( :hosts ).cn( :ns1 ).delete
# => true
<?end?>
