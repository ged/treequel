
# Branch Collections

So far we've been searching from a single base DN, but sometimes what
you want is located in different branches of the directory.

For example, hosts might be listed under different domainComponents
under the base that correspond to subdomains:

```ruby
irb> dir.filter( :objectClass => 'dcObject' ).scope( :one ).map( :dc )
# => ["sales", "marketing", "admin", "it", "vpn"]
```

Treequel::BranchCollection can be used to form searches from multiple
bases. They can be constructed from one or more Branchsets:

```ruby
irb> collection = Treequel::BranchCollection.new( dir.dc(:marketing).branchset, dir.dc(:sales).branchset )
# => #<Treequel::BranchCollection:0x10ef8c0 2 branchsets: ["dc=marketing,dc=acme,dc=com/(objectClass=*)", "dc=sales,dc=acme,dc=com/(objectClass=*)"]>
```

or directly from Branches, which will be converted to Branchsets:

```ruby
irb> collection = Treequel::BranchCollection.new( dir.dc(:marketing), dir.dc(:sales) )
# => #<Treequel::BranchCollection:0x10c2dfc 2 branchsets: ["dc=marketing,dc=acme,dc=com/(objectClass=*)", "dc=sales,dc=acme,dc=com/(objectClass=*)"]>
```

or via Treequel::Branchset `#collection` method:

```ruby
irb> collection = dir.scope(:one).filter(:objectClass => 'dcObject', :dc => ['sales', 'marketing']).collection
# => #<Treequel::BranchCollection:0x50b644 2 branchsets: ["dc=marketing,dc=acme,dc=com/(objectClass=*)", "dc=sales,dc=acme,dc=com/(objectClass=*)"]>
```

You can also compose BranchCollections by appending new Branchsets:

```ruby
irb> coll = Treequel::BranchCollection.new
# => #<Treequel::BranchCollection:0x1021420 0 branchsets: []>
irb> coll << dir.dc( :sales )
# => #<Treequel::BranchCollection:0x1021420 1 branchsets: ["dc=sales,dc=acme,dc=com/(objectClass=*)"]>
irb> coll << dir.dc( :marketing )
# => #<Treequel::BranchCollection:0x1021420 2 branchsets: ["dc=sales,dc=acme,dc=com/(objectClass=*)", "dc=marketing,dc=acme,dc=com/(objectClass=*)"]>
```

or by adding one BranchCollection to another:

```ruby
irb> east_coast = dir.filter( :dc => [:admin, :it] ).collection
# => #<Treequel::BranchCollection:0x594aac 2 branchsets: ["dc=it,dc=acme,dc=com/(objectClass=*)", "dc=admin,dc=acme,dc=com/(objectClass=*)"]>
irb> west_coast = dir.filter( :dc => [:sales, :marketing] ).collection
# => #<Treequel::BranchCollection:0x55d980 2 branchsets: ["dc=marketing,dc=acme,dc=com/(objectClass=*)", "dc=sales,dc=acme,dc=com/(objectClass=*)"]>
irb> national = east_coast + west_coast
# => #<Treequel::BranchCollection:0x554ec0 4 branchsets: ["dc=it,dc=acme,dc=com/(objectClass=*)", "dc=admin,dc=acme,dc=com/(objectClass=*)", "dc=marketing,dc=acme,dc=com/(objectClass=*)", "dc=sales,dc=acme,dc=com/(objectClass=*)"]>
```

BranchCollections work via delegation to their Branchsets, so all of the
mutator methods on Branchset are supported by BranchCollection. This
means that you can chain collections and filters together, with
collections serving as the base for further finer-grained searches:

```ruby
dir.filter( :ou => 'hosts' ).collection.filter( :cn => 'www' )
```

