# \Schema Introspection

The information about the structure of the directory comes from its
schema, and Treequel provides instrospection tools for accessing it in
an object-oriented manner. You can get the Treequel::Schema from the
directory by calling its Treequel::Directory#schema method.

```ruby
irb> dir.schema
# => #<Treequel::Schema:0x66511b 1119 attribute types, 31 ldap syntaxes, 54 matching rule uses, 72 matching rules, 310 object classes>
```

## Object Classes

You can fetch information about the [ObjectClasses](http://tools.ietf.org/html/rfc4512#section-2.4) the directory knows about through the schema's Treequel::Schema#object_classes Hash:

```ruby
irb> dir.schema.object_classes[:inetOrgPerson] 
# => #<Treequel::Schema::StructuralObjectClass:0x65d91b inetOrgPerson(2.16.840.1.113730.3.2.2) < "organizationalPerson" "RFC2798: Internet Organizational Person" MUST: [], MAY: [:audio, :businessCategory, :carLicense, :departmentNumber, :displayName, :employeeNumber, :employeeType, :givenName, :homePhone, :homePostalAddress, :initials, :jpegPhoto, :labeledURI, :mail, :manager, :mobile, :o, :pager, :photo, :roomNumber, :secretary, :uid, :userCertificate, :x500uniqueIdentifier, :preferredLanguage, :userSMIMECertificate, :userPKCS12]>
```

This hash is keyed by both OID and any associated names (as Symbols), and the value is a Treequel::Schema::ObjectClass object that contains the information about that objectClass parsed from the schema.

```ruby
irb> inetOrgPerson = dir.schema.object_classes[:inetOrgPerson] 
# => #<Treequel::Schema::StructuralObjectClass ...>
irb> inetOrgPerson.oid
# => "2.16.840.1.113730.3.2.2"
irb> inetOrgPerson.names
# => [:inetOrgPerson]
irb> inetOrgPerson.may_oids
# => [:audio, :businessCategory, :carLicense, :departmentNumber, :displayName, :employeeNumber, :employeeType, :givenName, :homePhone, :homePostalAddress, :initials, :jpegPhoto, :labeledURI, :mail, :manager, :mobile, :o, :pager, :photo, :roomNumber, :secretary, :uid, :userCertificate, :x500uniqueIdentifier, :preferredLanguage, :userSMIMECertificate, :userPKCS12]
irb> inetOrgPerson.desc
# => "RFC2798: Internet Organizational Person"
irb> inetOrgPerson.sup
# => #<Treequel::Schema::StructuralObjectClass:0x65fe6e person(2.5.6.6) < #<Treequel::Schema::AbstractObjectClass:0x6637ad top(2.5.6.0) < nil "top of the superclass chain" MUST: [:objectClass], MAY: []> "RFC2256: a person" MUST: [:sn, :cn], MAY: [:userPassword, :telephoneNumber, :seeAlso, :description]>
```

Treequel::Branch objects provide a shortcut for looking up the Treequel::ObjectClass objects that correspond to its `objectClass` properties:

```ruby
irb> dir.base.object_classes
# => [#<Treequel::Schema::AuxiliaryObjectClass:0x68b168 dcObject(1.3.6.1.4.1.1466.344) < #<Treequel::Schema::AbstractObjectClass:0x690555 top(2.5.6.0) < nil "top of the superclass chain" MUST: [:objectClass], MAY: []> "RFC2247: domain component object" MUST: [:dc], MAY: []>, #<Treequel::Schema::StructuralObjectClass:0x68d02b organization(2.5.6.4) < #<Treequel::Schema::AbstractObjectClass:0x690555 top(2.5.6.0) < nil "top of the superclass chain" MUST: [:objectClass], MAY: []> "RFC2256: an organization" MUST: [:o], MAY: [:userPassword, :searchGuide, :seeAlso, :businessCategory, :x121Address, :registeredAddress, :destinationIndicator, :preferredDeliveryMethod, :telexNumber, :teletexTerminalIdentifier, :telephoneNumber, :internationaliSDNNumber, :facsimileTelephoneNumber, :street, :postOfficeBox, :postalCode, :postalAddress, :physicalDeliveryOfficeName, :st, :l, :description]>]
```

## Attribute Types

You can also fetch introspection information on entry [attributeTypes](http://tools.ietf.org/html/rfc4512#section-2.5.1) via the schema's `#attribute_types` Hash:

```ruby
irb> dir.schema.attribute_types[:surname]
# => #<Treequel::Schema::AttributeType:0x146abd sn(2.5.4.4) "RFC2256: last (family) name(s) for which the entity is known by" SYNTAX: nil (length: unlimited)>
```

Like with objectClasses, they are keyed both by numeric OID strings and their associated names (as Symbols), and the values are instances of Treequel::Schema::AttributeType.

```ruby
irb> sn = dir.schema.attribute_types[:surname]
# => #<Treequel::Schema::AttributeType:0x696ec8 sn(2.5.4.4) "RFC2256: last (family) name(s) for which the entity is known by" SYNTAX: nil (length: unlimited)>
irb> sn.oid
# => "2.5.4.4"
irb> sn.names
# => [:sn, :surname]
irb> sn.desc
# => "RFC2256: last (family) name(s) for which the entity is known by"
irb> sn.obsolete?
# => false
irb> sn.sup
sn.sup_oid   sn.sup_oid=  sn.sup       
irb> sn.sup
# => #<Treequel::Schema::AttributeType:0x69e542 name(2.5.4.41) "RFC4519: common supertype of name attributes" SYNTAX: "1.3.6.1.4.1.1466.115.121.1.15" (length: 32768)>
irb> sn.eq
sn.eql?                    sn.eqmatch_oid=            sn.equal?                  sn.equality_matching_rule  
sn.eqmatch_oid             
irb> sn.equal
sn.equal?                  sn.equality_matching_rule  
irb> sn.equality_matching_rule
# => #<Treequel::Schema::MatchingRule:0x687f7c caseIgnoreMatch(2.5.13.2)  SYNTAX: #<Treequel::Schema::LDAPSyntax:0x689043 1.3.6.1.4.1.1466.115.121.1.15(Directory String)>>
irb> sn.substr_matching_rule
# => #<Treequel::Schema::MatchingRule:0x688026 caseIgnoreSubstringsMatch(2.5.13.4)  SYNTAX: nil>
irb> sn.user_modifiable?
# => true
```

Branches also know how to fetch the attribute types that are allowed by their objectClasses' _MUST_ and _MAY_ OIDs:

```ruby
irb> base = dir.base
# => #<Treequel::Branch:0x1a7f8cc dc=acme,dc=com @ localhost:389 (dc=acme,dc=com, tls, anonymous) entry=nil>
irb> base.may_oids
# => [:userPassword, :searchGuide, :seeAlso, :businessCategory, :x121Address, :registeredAddress, :destinationIndicator, :preferredDeliveryMethod, :telexNumber, :teletexTerminalIdentifier, :telephoneNumber, :internationaliSDNNumber, :facsimileTelephoneNumber, :street, :postOfficeBox, :postalCode, :postalAddress, :physicalDeliveryOfficeName, :st, :l, :description]
irb> base.may_attribute_types
# => [#<Treequel::Schema::AttributeType:0x69e1af userPassword(2.5.4.35) "RFC4519/2307: password of user" SYNTAX: "1.3.6.1.4.1.1466.115.121.1.40" (length: 128)>, #<Treequel::Schema::AttributeType:0x6968ce searchGuide(2.5.4.14) "RFC2256: search guide, deprecated by enhancedSearchGuide" SYNTAX: "1.3.6.1.4.1.1466.115.121.1.25" (length: unlimited)>, #<Treequel::Schema::AttributeType:0x69dfa7 seeAlso(2.5.4.34) "RFC4519: DN of related object" SYNTAX: nil (length: unlimited)>, ...]
```

## Other \Schema Information

The Schema object also facilitates access to the directory's [syntaxes and matching rules](http://tools.ietf.org/html/rfc4517) via the Treequel::Schema::LDAPSyntax, Treequel::Schema::MatchingRule, and Treequel::Schema::MatchingRuleUse classes. They are accessed via the Treequel::Schema#ldap_syntaxes, Treequel::Schema::#matching_rules, and Treequel::Schema#matching_rule_uses attributes of the Schema, respectively. They, like `#object_classes` and `#attribute_types`, are Hashes keyed both by OID and names as Symbols.


