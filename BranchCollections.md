---
title: Branch Collections
layout: default
index: 6
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

## Branch Collections

So far we've been searching from a single base DN, but sometimes what you want is located in different branches of the directory.

For example, hosts might be listed under different domainComponents under the base that correspond to subdomains:

<?example { language: irb, caption: "" } ?>
irb> dir.filter( :objectClass => 'dcObject' ).scope( :one ).map( :dc )
# => ["sales", "marketing", "admin", "it", "vpn"]
<?end ?>

<?api Treequel::BranchCollection ?>s can be used to form searches from multiple bases. They can be constructed from one or more Branchsets:

<?example { language: irb, caption: "Creating a collection from explicit Branchsets" } ?>
irb> collection = Treequel::BranchCollection.new( dir.dc(:marketing).branchset, dir.dc(:sales).branchset )
# => #<Treequel::BranchCollection:0x10ef8c0 2 branchsets: ["dc=marketing,dc=acme,dc=com/(objectClass=*)", "dc=sales,dc=acme,dc=com/(objectClass=*)"]>
<?end?>

or directly from Branches, which will be converted to Branchsets:

<?example { language: irb, caption: "Creating BranchCollection based on the results of a search" } ?>
irb> collection = Treequel::BranchCollection.new( dir.dc(:marketing), dir.dc(:sales) )
# => #<Treequel::BranchCollection:0x10c2dfc 2 branchsets: ["dc=marketing,dc=acme,dc=com/(objectClass=*)", "dc=sales,dc=acme,dc=com/(objectClass=*)"]>
<?end ?>

or via @Treequel::Branchset@'s @#collection@ method:

<?example { language: irb, caption: "A more-convenient way to turn the results returned by a Branchset into a collection." } ?>
irb> collection = dir.scope(:one).filter(:objectClass => 'dcObject', :dc => ['sales', 'marketing']).collection
# => #<Treequel::BranchCollection:0x50b644 2 branchsets: ["dc=marketing,dc=acme,dc=com/(objectClass=*)", "dc=sales,dc=acme,dc=com/(objectClass=*)"]>
<?end ?>

You can also compose BranchCollections by appending new Branchsets:

<?example { language: irb, caption: "Building up a BranchCollection gradually" } ?>
irb> coll = Treequel::BranchCollection.new
# => #<Treequel::BranchCollection:0x1021420 0 branchsets: []>
irb> coll << dir.dc( :sales )
# => #<Treequel::BranchCollection:0x1021420 1 branchsets: ["dc=sales,dc=acme,dc=com/(objectClass=*)"]>
irb> coll << dir.dc( :marketing )
# => #<Treequel::BranchCollection:0x1021420 2 branchsets: ["dc=sales,dc=acme,dc=com/(objectClass=*)", "dc=marketing,dc=acme,dc=com/(objectClass=*)"]>
<?end ?>

or by adding one BranchCollection to another:

<?example { language: irb, caption: "Combining two BranchCollections into one" } ?>
irb> east_coast = dir.filter( :dc => [:admin, :it] ).collection
# => #<Treequel::BranchCollection:0x594aac 2 branchsets: ["dc=it,dc=acme,dc=com/(objectClass=*)", "dc=admin,dc=acme,dc=com/(objectClass=*)"]>
irb> west_coast = dir.filter( :dc => [:sales, :marketing] ).collection
# => #<Treequel::BranchCollection:0x55d980 2 branchsets: ["dc=marketing,dc=acme,dc=com/(objectClass=*)", "dc=sales,dc=acme,dc=com/(objectClass=*)"]>
irb> national = east_coast + west_coast
# => #<Treequel::BranchCollection:0x554ec0 4 branchsets: ["dc=it,dc=acme,dc=com/(objectClass=*)", "dc=admin,dc=acme,dc=com/(objectClass=*)", "dc=marketing,dc=acme,dc=com/(objectClass=*)", "dc=sales,dc=acme,dc=com/(objectClass=*)"]>
<?end ?>

BranchCollections work via delegation to their Branchsets, so all of the mutator methods on Branchset are supported by BranchCollection. This means that you can chain collections and filters together, with collections serving as the base for further finer-grained searches:

<?example { language: irb, caption: "Find all hosts named 'www' under all @ou=hosts@ branches" } ?>
dir.filter( :ou => 'hosts' ).collection.filter( :cn => 'www' )
<?end ?>


