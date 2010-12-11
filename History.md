2010-12-08  Michael Granger  <ged@FaerieMUD.org>

	* lib/treequel.rb, lib/treequel/model.rb:
	Added more debugging to the mixin application in Treequel::Model.
	Bumped version to 1.2.1.
	[b9106049e6aa] [tip]

2010-11-30  Michael Granger  <ged@FaerieMUD.org>

	* .hgtags:
	Added tag v1.2.0 for changeset 3ceba5117883
	[610ee837acd2]

	* .hgsigs:
	Added signature for changeset c6166a5cbc23
	[3ceba5117883] [v1.2.0]

	* .hgsubstate, Rakefile:
	Updated build system.
	[c6166a5cbc23]

2010-11-24  Michael Granger  <ged@FaerieMUD.org>

	* .hgsubstate, Rakefile, project.yml:
	Updated build system.
	[ccdee2d78e68]

	* .hgsubstate, lib/treequel/branch.rb, spec/treequel/branch_spec.rb:
	Added hash-key conversion so Branches can be constructed with
	Symbol-key hashargs.
	[47697f2ebc27]

2010-11-18  Michael Granger  <ged@FaerieMUD.org>

	* lib/treequel.rb, lib/treequel/branchset.rb, spec/lib/constants.rb,
	spec/lib/helpers.rb, spec/treequel/branchset_spec.rb,
	spec/treequel/model_spec.rb:
	Adding 'Treequel::Branchset#from' mutator for changing the base DN.
	 * Bump version to 1.2.0
	 * Add Treequel::Branchset#from and specs for it.
	 * Spec cleanup
	   - Refactored some specs to mock completely outside the library
	   - Added a fixturing function to the spec helpers:
	get_fixtured_directory()
	   - Replaced nested describes in some specs with contexts instead.
	[44f8be0662c4]

2010-11-11  Michael Granger  <ged@FaerieMUD.org>

	* Merging with 316:33a7dcde80a1
	[72dd41272f6f]

	* .hgsubstate, lib/treequel/model.rb, spec/treequel/branch_spec.rb,
	spec/treequel/model_spec.rb, spec/treequel/monkeypatches_spec.rb:
	Spec fixes for RSpec 2.0
	 * Fix RSpec regex workaround for Treequel::Model#respond_to?
	 * Fix monkeypatch Time tests for running outside of PST8PDT
	[9f9460125077]

2010-11-09  Michael Granger  <ged@FaerieMUD.org>

	* .hgsub, .hgsubstate:
	Readding subrepo
	[33a7dcde80a1]

	* .hgsub, .hgsubstate, .hgsubstate:
	Fixing subrepo corruption caused by rollback
	[fc9ae9f5b034]

	* README:
	Merged with 310:cc7c63ff15a0
	[c1b750e4e9fc]

	* .hgsubstate, lib/treequel/branch.rb, lib/treequel/model.rb,
	spec/treequel/branch_spec.rb,
	spec/treequel/branchcollection_spec.rb,
	spec/treequel/branchset_spec.rb,
	spec/treequel/controls/pagedresults_spec.rb,
	spec/treequel/controls/sortedresults_spec.rb,
	spec/treequel/directory_spec.rb, spec/treequel/model_spec.rb:
	stub! -> stub; added more debugging to try to track down the model
	test failure
	[380662d385e0]

2010-11-03  Michael Granger  <ged@FaerieMUD.org>

	* README, README.md:
	Converting the README to Markdown
	[cc7c63ff15a0]

2010-11-08  Michael Granger  <ged@FaerieMUD.org>

	* bin/treequel:
	Fixed treequel shell's cp to support relative and absolute DNs
	[7f20ab74d6b1]

2010-10-22  Michael Granger  <ged@FaerieMUD.org>

	* lib/treequel/schema.rb, spec/lib/control_behavior.rb,
	spec/lib/helpers.rb, spec/lib/matchers.rb,
	spec/treequel/branch_spec.rb,
	spec/treequel/branchcollection_spec.rb,
	spec/treequel/branchset_spec.rb, spec/treequel/control_spec.rb,
	spec/treequel/controls/contentsync_spec.rb,
	spec/treequel/controls/pagedresults_spec.rb,
	spec/treequel/controls/sortedresults_spec.rb,
	spec/treequel/directory_spec.rb, spec/treequel/filter_spec.rb,
	spec/treequel/mixins_spec.rb,
	spec/treequel/model/objectclass_spec.rb,
	spec/treequel/model_spec.rb, spec/treequel/monkeypatches_spec.rb,
	spec/treequel/schema/attributetype_spec.rb,
	spec/treequel/schema/ldapsyntax_spec.rb,
	spec/treequel/schema/matchingrule_spec.rb,
	spec/treequel/schema/matchingruleuse_spec.rb,
	spec/treequel/schema/objectclass_spec.rb,
	spec/treequel/schema/table_spec.rb, spec/treequel/schema_spec.rb,
	spec/treequel_spec.rb:
	Converted to RSpec 2.0
	[26c3853695ea]

	* .hgsub, .hgsubstate, Rakefile, project.yml:
	Updating build system; add requirement for Ruby 1.8.7
	[98b6847de872]

2010-09-21  Michael Granger  <ged@FaerieMUD.org>

	* .hgtags:
	Added tag 1.1.1 for changeset e52c71f4e4ca
	[7f70394868e2]

	* .hgsigs:
	Added signature for changeset c6d26ab6a7a4
	[e52c71f4e4ca] [1.1.1]

	* lib/treequel.rb, lib/treequel/branch.rb, lib/treequel/model.rb,
	spec/treequel/model_spec.rb:
	Critical bugfix.
	 * Fix a critical bug in the mapping of objectClasses to Model objects
	when the object is created with an entry hash rather than lazy-
	loaded.
	 * Bump version to 1.1.1.
	[c6d26ab6a7a4]

2010-09-20  Michael Granger  <ged@FaerieMUD.org>

	* .hgtags:
	Added tag 1.1.0 for changeset b415e0fce774
	[92c28b14730a]

	* .hgsigs:
	Added signature for changeset 4ba782a3a7e4
	[b415e0fce774] [1.1.0]

2010-09-17  Michael Granger  <ged@FaerieMUD.org>

	* lib/treequel/model.rb, lib/treequel/schema/objectclass.rb,
	spec/treequel/model_spec.rb,
	spec/treequel/schema/objectclass_spec.rb:
	Include mixins for inherited objectClasses, too.
	[4ba782a3a7e4]

	* Rakefile:
	Updated build system
	[f075a27a35eb]

	* docs/manual/src/index.page:
	Manual updates for the Model section (paired with Mahlon)
	[c77bac0bf816]

2010-09-15  Michael Granger  <ged@FaerieMUD.org>

	* lib/treequel/schema/attributetype.rb:
	Use the #syntax method instead of the syntax_oid in #inspect output
	so inherited syntaxes are shown
	[1b375c5dc123]

	* bin/treeirb:
	Use the system LDAP config if no URI is given
	[0786411cd707]

	* lib/treequel/branch.rb:
	Un-spam debugging on entry lookup
	[d3a6c89d8004]

	* lib/treequel/model.rb:
	Overriding #inspect in Treequel::Model to show the list of
	extensions applied to the entry
	[2101482df41f]

2010-08-25  Michael Granger  <ged@FaerieMUD.org>

	* lib/treequel/model.rb, spec/treequel/model_spec.rb:
	Rescue the right error in Treequel::Model#method_missing and add a
	spec for the negative case.
	[a384412c0e6f]

	* lib/treequel/model.rb, spec/treequel/model_spec.rb:
	Load the entry from Model's #method_missing to catch calls to
	methods that are added via objectClass mixins.
	[b220a83d31b5]

2010-08-23  Michael Granger  <ged@FaerieMUD.org>

	* lib/treequel/branch.rb, lib/treequel/schema/attributetype.rb,
	spec/treequel/branch_spec.rb:
	Fixing object/attribute mapping for attributes whose types that
	inherit their syntax from their superclass
	[2753f8405caf]

	* Rakefile.local, docs/Treequel Manual Diagrams.graffle,
	docs/manual/src/index.page, lib/treequel.rb, lib/treequel/branch.rb,
	lib/treequel/directory.rb, lib/treequel/model/objectclass.rb,
	lib/treequel/monkeypatches.rb, spec/lib/constants.rb,
	spec/treequel/branch_spec.rb,
	spec/treequel/branchcollection_spec.rb,
	spec/treequel/branchset_spec.rb, spec/treequel/directory_spec.rb,
	spec/treequel/filter_spec.rb, spec/treequel/mixins_spec.rb,
	spec/treequel/model/objectclass_spec.rb,
	spec/treequel/monkeypatches_spec.rb,
	spec/treequel/schema/table_spec.rb, spec/treequel/schema_spec.rb,
	spec/treequel/utils_spec.rb, spec/treequel_spec.rb:
	Coverage improvements, manual work
	 * Improved coverage
	 * More work on the manual and manual graphics
	[2e2b035d3721]

	* docs/manual/lib/links-filter.rb, docs/manual/src/index.page,
	lib/treequel.rb:
	Started catching the manual up to 1.1.0.
	[693a163bd068]

	* lib/treequel/branch.rb, spec/treequel/branch_spec.rb:
	Made Treequel::Branch#delete with no arguments delete the entry
	[df0b0594cb62]

2010-08-19  Michael Granger  <ged@FaerieMUD.org>

	* lib/treequel/branchcollection.rb, lib/treequel/branchset.rb,
	spec/lib/control_behavior.rb, spec/treequel/branch_spec.rb,
	spec/treequel/branchcollection_spec.rb,
	spec/treequel/branchset_spec.rb, spec/treequel/control_spec.rb,
	spec/treequel/controls/contentsync_spec.rb,
	spec/treequel/controls/pagedresults_spec.rb,
	spec/treequel/controls/sortedresults_spec.rb,
	spec/treequel/directory_spec.rb, spec/treequel/filter_spec.rb,
	spec/treequel/mixins_spec.rb,
	spec/treequel/model/objectclass_spec.rb,
	spec/treequel/model_spec.rb,
	spec/treequel/schema/attributetype_spec.rb,
	spec/treequel/schema/ldapsyntax_spec.rb,
	spec/treequel/schema/matchingrule_spec.rb,
	spec/treequel/schema/matchingruleuse_spec.rb,
	spec/treequel/schema/objectclass_spec.rb,
	spec/treequel/schema/table_spec.rb, spec/treequel/schema_spec.rb,
	spec/treequel/utils_spec.rb, spec/treequel_spec.rb:
	Fixes for Ruby 1.9.2.
	[31fc0ea1ea31]

	* Rakefile, project.yml:
	Build system update; fixed ruby-termios dependency
	[7c7d3e2034b0]

2010-08-18  Michael Granger  <ged@FaerieMUD.org>

	* lib/treequel/branchset.rb, lib/treequel/model.rb,
	spec/treequel/branchset_spec.rb:
	Implement Branchset operators
	 * COMPAT: Change the way Branchset#+ works with a Branch argument to
	work with Model methods that return related searches.
	 * Implement Branchset#-
	[f9151315d37f]

2010-08-16  Michael Granger  <ged@FaerieMUD.org>

	* lib/treequel/constants.rb, lib/treequel/schema.rb,
	lib/treequel/schema/attributetype.rb, spec/treequel/branch_spec.rb,
	spec/treequel/schema/attributetype_spec.rb,
	spec/treequel/schema_spec.rb:
	Reworked operational attributes to use the 'USAGE' attribute at
	Mahlon's suggestion.
	 * Operational attributes are now fetched from the schema.
	 * Treequel::Schema::AttributeType now has predicates for testing for
	various usage types.
	[cd3ef7e3ffb0]

	* lib/treequel/model.rb, spec/treequel/model_spec.rb:
	Fixes for Treequel::Model instantiation and lookup.
	 * Don't try to add objectclass mixins to the nil returned from a
	failed lookup.
	 * Expanded coverage for Treequel::Model.
	[dfb032f5e5c1]

	* lib/treequel/schema/table.rb, spec/treequel/schema/table_spec.rb:
	Made Treequel::Schema::Table Enumerable
	[844ee21c6916]

2010-08-06  Michael Granger  <ged@FaerieMUD.org>

	* lib/treequel/model.rb, spec/treequel/model_spec.rb:
	Don't add the objectClass attribute when searching through
	Treequel::Model if the search doesn't specify any return attributes.
	[ff2629196b4e]

	* lib/treequel/filter.rb:
	Handle Sequel's Ruby1.9 Symbol-operator workaround in filter
	attributes
	[d4e58760ee34]

	* lib/treequel/branch.rb:
	Also output empty-string attributes as non-binary
	[d60c6b83db01]

2010-08-05  Michael Granger  <ged@FaerieMUD.org>

	* lib/treequel/branch.rb:
	Unwrap base64ed LDIF lines before wrapping them to the new line
	length.
	[bb182f705fe5]

	* lib/treequel/branch.rb, spec/treequel/branch_spec.rb:
	Fix LDIF-generation for really reals.
	[32084630894f]

	* lib/treequel/branch.rb, lib/treequel/directory.rb,
	lib/treequel/model.rb, spec/treequel/model_spec.rb:
	Optimizations, logging cleanup.
	 * Optimize falling through Treequel::Model#method_missing for branch-
	traversal methods to avoid talking to the directory if possible.
	 * Clean up some of the chattier but not-as-useful debug logging
	[aabbab99b093]

2010-08-02  Michael Granger  <ged@FaerieMUD.org>

	* lib/treequel/branch.rb, lib/treequel/model.rb, spec/lib/matchers.rb,
	spec/treequel/branch_spec.rb:
	Bugfixes.
	 * Handle empty-string DNs in Treequel::Branch#parent_dn
	 * Tidy up LDIF-generation
	 * Add an RSpec workaround for Treequel::Model#respond_to?
	[7a4f2e5bef0a]

2010-07-29  Michael Granger  <ged@FaerieMUD.org>

	* lib/treequel/filter.rb, lib/treequel/model.rb:
	Filter component symmetry, Model refactor
	 * Added an append method for Treequel::Filter::AndComponent to serve
	as the underpinnings for an .and() method as soon as I figure out
	a way to track the last-appended component so I can
	collapse/follow apprpriately.
	 * Refactored Treequel::Model#find_attribute_type
	[2f741e5294bf]

2010-07-28  Michael Granger  <ged@FaerieMUD.org>

	* lib/treequel/branchset.rb, lib/treequel/filter.rb,
	spec/treequel/branchset_spec.rb, spec/treequel/filter_spec.rb:
	Added support for Sequel-style #or: branchset.filter( :something
	).or( :somethingelse ).
	[bc0bc3aea136]

	* lib/treequel/model.rb, spec/treequel/model_spec.rb:
	Added Treequel::Model#respond_to?
	[30091794b910]

2010-07-27  Michael Granger  <ged@FaerieMUD.org>

	* lib/treequel/branch.rb, lib/treequel/constants.rb,
	lib/treequel/directory.rb, lib/treequel/model.rb,
	lib/treequel/monkeypatches.rb, lib/treequel/schema.rb,
	spec/treequel/branch_spec.rb, spec/treequel/branchset_spec.rb,
	spec/treequel/directory_spec.rb, spec/treequel/model_spec.rb,
	spec/treequel/schema_spec.rb:
	Bugfix, make object conversion work for setting attributes too.
	 * Add 'objectClass' to a Branchset that's resolved through a
	Treequel::Model so the model knows what ObjectClass modules to
	extend the results with.
	 * Make setters on a Treequel::Branch do conversion from Ruby objects
	to correct LDAP attribute strings.
	 * Added operational-attribute awareness to Treequel::Schema objects
	[e9c908b1f426]

2010-07-26  Michael Granger  <ged@FaerieMUD.org>

	* lib/treequel/branch.rb, spec/treequel/branch_spec.rb:
	Bugfixes, coverage of LDIF-generation.
	 * Added support for empty base DNs to Treequel::Branch.
	 * Added a spec example for LDIF output; still need one for
	Base64-encoded values, however.
	[30ba889041a8]

2010-07-16  Michael Granger  <ged@FaerieMUD.org>

	* bin/treequel:
	Fixing the "cd .." special case
	[a6dd7b685a6a]

2010-07-14  Michael Granger  <ged@FaerieMUD.org>

	* lib/treequel/model.rb:
	Untaint objectClasses passed to
	Treequel::Model::mixins_for_objectclasses.
	[2793fa802dad]

2010-07-13  Michael Granger  <ged@FaerieMUD.org>

	* lib/treequel/directory.rb, spec/treequel/directory_spec.rb:
	The workaround for two-param syntax mapping Procs didn't work after
	all. Modifying the default mappings to take that into account.
	[b76dd9ca1f3f]

	* experiments/schema_roundtrip.rb, lib/treequel/directory.rb,
	lib/treequel/schema.rb, lib/treequel/schema/attributetype.rb,
	lib/treequel/schema/ldapsyntax.rb,
	lib/treequel/schema/matchingrule.rb,
	lib/treequel/schema/matchingruleuse.rb,
	lib/treequel/schema/objectclass.rb, spec/treequel/directory_spec.rb,
	spec/treequel/schema/attributetype_spec.rb,
	spec/treequel/schema/ldapsyntax_spec.rb,
	spec/treequel/schema/matchingrule_spec.rb,
	spec/treequel/schema/matchingruleuse_spec.rb,
	spec/treequel/schema/objectclass_spec.rb:
	Added schema-object roundtripping, with a script/specs to test it.
	[70cc87a200ad]

	* lib/treequel/directory.rb, spec/treequel/directory_spec.rb:
	Added the ability to set the default results class on a per-
	directory basis.
	[47e865bfef9e]

	* bin/treequel, lib/treequel/model.rb, spec/treequel/model_spec.rb:
	Fixes for Apache DS and bugfix in Treequel::Model.
	 * Don't assume the 'structuralObjectClass' operational attribute
	exists in entries in the Treequel shell; Apache DS, for one,
	doesn't have it.
	 * Fix a bug in Treequel::Model which caused under_barred attributes
	not to try their camelCased equivalent.
	[c61373e3dc49]

2010-07-10  Michael Granger  <ged@FaerieMUD.org>

	* lib/treequel/branch.rb, lib/treequel/model.rb,
	lib/treequel/model/objectclass.rb, spec/treequel/model_spec.rb:
	Treequel::Model bugfix
	 * Fixed Treequel::Model registration logic for objectclasses with no
	model_bases by registering them under the empty-string DN.
	 * Return duplicates from
	Treequel::Model::ObjectClass::model_objectclasses and
	::model_bases.
	 * Add an alias for #include_operational_attrs ->
	include_operational_attributes
	[601003ff3077]

2010-07-09  Michael Granger  <ged@FaerieMUD.org>

	* experiments/mixohm.rb, lib/treequel.rb, lib/treequel/model.rb,
	lib/treequel/model/objectclass.rb,
	spec/treequel/model/objectclass_spec.rb,
	spec/treequel/model_spec.rb,
	spec/treequel/schema/objectclass_spec.rb:
	Adding Treequel::Model, bumping version to 1.1.0.
	 * New classes/modules: Treequel::Model, Treequel::Model::ObjectClass
	 * Adding the spike for the OHM implementation
	[a76065cfeba0]

	* Merged with 47bb9cd7af3b
	[6dd6cb37f5ce]

2010-07-08  Michael Granger  <ged@FaerieMUD.org>

	* .hgignore, lib/treequel/directory.rb:
	Delegate the Treequel::Directory#root_dse method through its #conn
	method too.
	[3f4134d20d9d]

2010-07-07  Michael Granger  <ged@FaerieMUD.org>

	* .hgtags:
	Added tag 1.0.4 for changeset 0ec4ff0ce67f
	[0188c2ba5b7e]

	* .hgsigs:
	Added signature for changeset c8534439a5bc
	[0ec4ff0ce67f] [1.0.4]

	* lib/treequel.rb:
	Bumping version to 1.0.4 because I'm an idiot and included some
	files that were intended for a future version in 1.0.3.
	[c8534439a5bc]

	* .hgtags:
	Added tag 1.0.3 for changeset 65be21a77bfe
	[47bb9cd7af3b]

	* .hgsigs:
	Added signature for changeset fd86e30957a6
	[65be21a77bfe] [1.0.3]

	* Rakefile, experiments/control-syntax-spike.rb, experiments/ohm.rb,
	lib/treequel/branch.rb, lib/treequel/branchcollection.rb,
	lib/treequel/branchset.rb, lib/treequel/exceptions.rb,
	lib/treequel/mixins.rb, lib/treequel/schema/attributetype.rb,
	lib/treequel/schema/objectclass.rb, lib/treequel/schema/table.rb,
	spec/lib/constants.rb, spec/treequel/branch_spec.rb,
	spec/treequel/branchcollection_spec.rb,
	spec/treequel/branchset_spec.rb, spec/treequel/mixins_spec.rb,
	spec/treequel/schema/attributetype_spec.rb,
	spec/treequel/schema/objectclass_spec.rb:
	Build system update, prep for 1.0.3 release.
	 * Refactored some methods in Treequel::Branch to allow for easier
	subclassing.
	 * Fixed an edge case in Treequel::BranchCollection mutators when they
	are called without a mutating value, but require one.
	 * Added Treequel::Branchset#+
	 * Factored out DN normalization functions into a
	Treequel::Normalization mixin
	 * Made Treequel::Schema::ObjectClass include its ancestors' MUST and
	MAY OIDs by default in #must_oids and #may_oids.
	 * Covered some more edge cases in the specs
	[fd86e30957a6]

2010-06-14  Michael Granger  <ged@FaerieMUD.org>

	* bin/treequel:
	Fix the 'parent' command in the treequel shell and the success
	message for the 'cp' command.
	[dd880dcd1b9a]

	* bin/treequel, lib/treequel/directory.rb,
	spec/treequel/directory_spec.rb:
	Treequel shell cleanup, new subcommand,
	Treequel::Directory#bound_user
	 * 'treequel' shell:
	   - Options and help consistency fixes
	   - Added 'whoami' command
	 * Make the bound user's DN fetchable via
	Treequel::Directory#bound_user
	[c2a696248d22]

2010-06-10  Michael Granger  <ged@FaerieMUD.org>

	* Rakefile.local, bin/treequel, docs/manual/src/index.page,
	lib/treequel/constants.rb:
	Added 'cp' treequel shell command, removed FOLDED_LDIF_ATTRVAL_SPEC
	pattern.
	[61d5aae13b7e]

2010-05-27  Michael Granger  <ged@FaerieMUD.org>

	* bin/treequel, lib/treequel/branch.rb, spec/treequel/branch_spec.rb:
	Treequel shell cleanup, support config-loaded directory, Branch#move
	fixes
	* Treequel shell:
	  - Cleaned up the option-parsing/startup code
	  - Made the shell use the system config with no URL argument via
	Treequel.directory_from_config instead of just defaulting to
	ldap://localhost
	  - Fixed the 'mv' command
	* Cleaned up the Treequel::Branch#move command, removing the
	unfinished attribute-modification code, which was redundant.
	[d9073c3a9f0e]

2010-05-03  Michael Granger  <ged@FaerieMUD.org>

	* bin/treequel, lib/treequel/schema/table.rb:
	Treequel shell work, made schema tables more Hash-like.
	* Treequel shell:
	  - Added a 'mv' command
	  - Added a confirmation for the deletion of each sub-entry to 'rm', and
	a -f(orce) flag to avoid it.
	* Made Treequel::Schema::Table a bit more Hash-like with more
	delegation.
	[0982bb19bfb9]

2010-04-14  Michael Granger  <ged@FaerieMUD.org>

	* lib/treequel.rb, spec/treequel_spec.rb:
	Fixed a bug in Treequel.read_opts_from_config which caused
	directory_from_config not to work. Thanks to Mahlon for spotting
	this.
	[b725e5424fa9]

2010-04-13  Michael Granger  <ged@FaerieMUD.org>

	* lib/treequel/branch.rb, lib/treequel/directory.rb:
	More YARD docs
	[561646be1b80]

2010-04-11  Michael Granger  <ged@FaerieMUD.org>

	* bin/treequel, lib/treequel/branch.rb, lib/treequel/constants.rb:
	Fixed LDIF and highlighting in treequel shell
	* Replaced LDIF function from ruby-ldap, as it modifies its receiver
	and has hardcoded column width.
	* Made the LDIF-matching pattern handle folded attribute values.
	[94b428852c7a]

2010-04-10  Michael Granger  <ged@FaerieMUD.org>

	* Rakefile:
	Updated build system.
	[a42d7297577a]

2010-04-08  Michael Granger  <ged@FaerieMUD.org>

	* Rakefile, lib/treequel/branch.rb, lib/treequel/directory.rb,
	spec/treequel/branch_spec.rb:
	Updated build system, more YARDificiation.
	[a039187fcbfd]

2010-04-07  Michael Granger  <ged@FaerieMUD.org>

	* Rakefile:
	Updated build system.
	[b54fe9c1171d]

	* .hgignore, Rakefile, bin/treequel, docs/manual/src/index.page,
	lib/treequel.rb, lib/treequel/branch.rb,
	lib/treequel/branchcollection.rb, lib/treequel/branchset.rb,
	lib/treequel/control.rb, lib/treequel/controls/contentsync.rb,
	lib/treequel/controls/pagedresults.rb,
	lib/treequel/controls/persistentsearch.rb,
	lib/treequel/controls/sortedresults.rb, lib/treequel/directory.rb,
	lib/treequel/exceptions.rb, lib/treequel/filter.rb,
	lib/treequel/mixins.rb, lib/treequel/monkeypatches.rb,
	lib/treequel/schema/ldapsyntax.rb,
	lib/treequel/schema/matchingrule.rb,
	lib/treequel/schema/matchingruleuse.rb,
	lib/treequel/sequel_integration.rb, lib/treequel/utils.rb,
	project.yml, spec/lib/control_behavior.rb, spec/lib/matchers.rb,
	spec/treequel/branch_spec.rb,
	spec/treequel/branchcollection_spec.rb,
	spec/treequel/controls/contentsync_spec.rb,
	spec/treequel/controls/pagedresults_spec.rb,
	spec/treequel/controls/sortedresults_spec.rb,
	spec/treequel/mixins_spec.rb, spec/treequel/schema/table_spec.rb:
	More specs, more YARD docs.
	* Finished SortedResultsControl spec
	* Added YARD docs for the top-level namespace, started work on the
	rest.
	* Added a warning when trying to use the ContentSyncControl
	* Removed the PersistentSearchControl, which isn't supported by any of
	my test servers, and has been replaced by the ContentSyncControl
	anyway.
	* Criteria in SortedResultsControl are now contained in a Struct
	instead of a Hash for more literate code.
	* Added an extension module (Treequel::LDAPControlExtensions) to add
	comparability to LDAP::Control
	* treequel shell: 'ls' command
	  - added several sort criteria
	  - refactored into smaller methods
	* Fixed ArgumentError in Treequel::Branch#delete, added the ability to
	delete individual attribute values
	* Started a collection of RSpec matchers (spec/lib/matchers.rb)
	[96125f5e3297]

2010-04-06  Michael Granger  <ged@FaerieMUD.org>

	* lib/treequel/branch.rb, lib/treequel/directory.rb,
	spec/treequel/branch_spec.rb, spec/treequel/directory_spec.rb:
	New method Treequel::Branch#values_at, rewrote #delete to be
	consistent with Hash#delete.
	* Added the #values_at method which works like Hash#values_at.
	* Made #delete operate on Branch attributes instead of duplicating the
	functionality of Directory#delete.
	* Made Treequel::Directory#modify take an Array of LDAP::Mod objects
	in addition to a hash of attribute modifications.
	[91486cbc9047]

2010-03-23  Michael Granger  <ged@FaerieMUD.org>

	* lib/treequel.rb, spec/treequel_spec.rb:
	Added NSS-style ldap.conf support.
	[bc24a82b0e9c]

2010-03-19  Michael Granger  <ged@FaerieMUD.org>

	* lib/treequel/directory.rb, lib/treequel/mixins.rb,
	lib/treequel/schema.rb, lib/treequel/schema/table.rb,
	spec/treequel/schema/table_spec.rb:
	Converted hash-based schema tables to a case-insensitive Table class
	(fixes #1)
	* Created a new Treequel::Schema::Table class which provides case-
	insensitive (as well as struct-like method) access to schema
	information.
	* Aliased Treequel::Directory#bind to #bind_as
	[2f756d5f12e2]

2010-03-18  Michael Granger  <ged@FaerieMUD.org>

	* lib/treequel.rb, spec/treequel_spec.rb:
	Adding system-config methods to the Treequel methods
	[f8de798625ee]

2010-03-02  Michael Granger  <ged@FaerieMUD.org>

	* spec/treequel/branchcollection_spec.rb:
	Finished specs for BranchCollection#empty?
	[02660115ea46]

2010-03-01  Michael Granger  <ged@FaerieMUD.org>

	* bin/treequel, lib/treequel/branchcollection.rb,
	lib/treequel/branchset.rb, spec/treequel/branchcollection_spec.rb,
	spec/treequel/branchset_spec.rb:
	Treequel shell bugfixes, #empty? on Branchsets and BranchCollections
	* Handle tab when the command line is empty in the treequel shell.
	(Thanks Mahlon)
	* Add an #empty? predicate method to both Branchsets and
	BranchCollections (one spec still pending).
	[cbdb4342dc46]

2010-02-17  Michael Granger  <ged@FaerieMUD.org>

	* bin/treequel, lib/treequel.rb, spec/treequel_spec.rb:
	Added an 'irb' command to the treequel shell, fixed build-number
	parsing.
	[5af1ee6a7f6c]

2010-02-09  Michael Granger  <ged@FaerieMUD.org>

	* bin/treequel:
	Implemented the `-b bind_dn` option.
	[8a43b642fd91]

2010-02-03  Michael Granger  <ged@FaerieMUD.org>

	* bin/treequel:
	Merged 233:1d06d28159a6
	[2a1bac85c038]

	* bin/treequel, lib/treequel/constants.rb, lib/treequel/directory.rb,
	lib/treequel/schema.rb, lib/treequel/schema/attributetype.rb,
	spec/treequel/directory_spec.rb:
	Adding the beginnings of ActiveDirectory support, treequel shell
	options, server introspection.
	* Treequel shell:
	  - Added a few initial command-line options for connection type, bind
	DN, etc.
	  - Made colorization of encoded and URL attributes consistent with
	regular ones.
	  - Downcase attribute names before using them in the 'cdn' command.
	* Added more server-introspection support to Treequel::Directory;
	added more control OIDs, and new methods for fetching supported
	extensions and features.
	* Adding ActiveDirectory support to Treequel::Schema:
	  - Made alterations to the parser to support ActiveDirectory-style non-
	standard schema entries (OIDs in quotes, descriptors in
	attributeType SYNTAX attributes, etc.).
	  - Handle the case where the schema doesn't have syntaxes, matching
	rules, and/or matching rule use entries.
	[e96bbf2e7325]

2010-01-26  Michael Granger  <ged@FaerieMUD.org>

	* bin/treequel:
	Merged with 230:b994d8d9d608
	[1d06d28159a6]

	* experiments/sorted_results_example.rb, lib/treequel/branchset.rb,
	lib/treequel/constants.rb, lib/treequel/controls/contentsync.rb,
	lib/treequel/controls/sortedresults.rb, lib/treequel/exceptions.rb:
	Initial (untested) implementation of the sorted results control.
	* Added Treequel::SortedResultsControl
	* Added an experiment for testing the sorted results control.
	* Re-sorted the OID constants to be in OID order
	[8b2fb7415412]

2010-01-24  Michael Granger  <ged@FaerieMUD.org>

	* bin/treequel:
	Convert the option parsers to a class global instead of a constant
	[b994d8d9d608]

2010-01-13  Michael Granger  <ged@FaerieMUD.org>

	* bin/treequel:
	Make treequel shell's 'cat' command error for non-existant entries
	[84087b01d473]

	* bin/treequel:
	Fix the 'grep' command in the Treequel shell.
	[669a09149f48]

2010-01-12  Michael Granger  <ged@FaerieMUD.org>

	* LICENSE, bin/treequel, examples/ldap-rack-auth.rb,
	experiments/contentsync.rb, experiments/filter-syntax-spike.rb,
	lib/treequel/controls/contentsync.rb, lib/treequel/directory.rb,
	spec/treequel/directory_spec.rb:
	Operational attributes propagation and treequel shell fixes.
	* Fix propagation of Treequel::Branch#include_operational_attrs flag
	through search.
	* Made short-form 'ls' output show entries with subordinates appear
	with a '/'.
	* Removed some old copied cruft from the treequel shell.
	* Added content-sync control experiment.
	* Got a little closer to content-sync control functioning.
	[ab2a2ff43b60]

2010-01-07  Michael Granger  <ged@FaerieMUD.org>

	* bin/treequel:
	Merged with d77a0bf26034
	[14f5f723d0aa]

	* Rakefile:
	Updated build system
	[00ac1bc4e917]

2009-12-22  Michael Granger  <ged@FaerieMUD.org>

	* bin/treequel:
	Reworked LDIF display colors in the shell to be more visible.
	[d77a0bf26034]

	* bin/treequel:
	Make the treequel shell fall back to plain connect (with a warning)
	if TLS fails.
	[9aeccec1ee84]

2010-01-07  Michael Granger  <ged@FaerieMUD.org>

	* bin/treequel, lib/treequel/branch.rb, lib/treequel/constants.rb,
	lib/treequel/utils.rb:
	Improvements to the treequel shell, fixes for 1.9.1.
	* Fixes for 1.9.1:
	  - Handle the change in the URI::REGEXP namespace under 1.9.1
	  - Eliminated most of the shadowed variable warnings
	  - Fixed the compact 'ls' display
	* Got the 'create' treequel shell command working reasonably well
	* Made Treequel::Branch#object_classes raise an exception if one of
	the specified additional_classes
	[5afefa230ef0]

2010-01-06  Michael Granger  <ged@FaerieMUD.org>

	* lib/treequel/directory.rb, spec/treequel/directory_spec.rb:
	Eliminate duplicates when smushing RDN attributes on a
	Treequel::Directory#create
	[83b178f0850e]

2009-12-22  Michael Granger  <ged@FaerieMUD.org>

	* examples/ldap-monitor.rb, examples/ldap-
	monitor/public/css/master.css, examples/ldap-
	monitor/public/images/card_small.png, examples/ldap-
	monitor/public/images/chain_small.png, examples/ldap-
	monitor/public/images/globe_small.png, examples/ldap-
	monitor/public/images/globe_small_green.png, examples/ldap-
	monitor/public/images/plug.png, examples/ldap-
	monitor/public/images/shadows/large-30-down.png, examples/ldap-
	monitor/public/images/tick.png, examples/ldap-
	monitor/public/images/tick_circle.png, examples/ldap-
	monitor/public/images/treequel-favicon.png, examples/ldap-
	monitor/views/backends.erb, examples/ldap-
	monitor/views/connections.erb, examples/ldap-
	monitor/views/databases.erb, examples/ldap-
	monitor/views/dump_subsystem.erb, examples/ldap-
	monitor/views/index.erb, examples/ldap-monitor/views/layout.erb,
	examples/ldap-monitor/views/listeners.erb:
	Automated merge with ssh://hg@deveiate/Treequel
	[3bdd645530fe]

2009-12-18  Michael Granger  <ged@FaerieMUD.org>

	* Merged with 5fd4033e1556
	[9571c9d8e4dd]

2009-12-17  Michael Granger  <ged@FaerieMUD.org>

	* docs/openldap-oids.txt, lib/treequel/constants.rb,
	lib/treequel/controls/contentsync.rb,
	lib/treequel/controls/persistentsearch.rb,
	lib/treequel/directory.rb:
	More controls work, started several more control modules.
	* Adding a breakdown of all the controls the OpenLDAP server I have
	has, so I know which controls I can test against.
	* Added some control constants.
	* Added the ContentSyncControl and the PersistentSearchControl.
	* Added a Directory#supported_controls method.
	[ffc2ebacdfd0]

2009-12-22  Michael Granger  <ged@FaerieMUD.org>

	* bin/treequel, examples/ldap-monitor.rb, examples/ldap-
	monitor/public/css/master.css, examples/ldap-
	monitor/public/images/card_small.png, examples/ldap-
	monitor/public/images/chain_small.png, examples/ldap-
	monitor/public/images/globe_small.png, examples/ldap-
	monitor/public/images/globe_small_green.png, examples/ldap-
	monitor/public/images/plug.png, examples/ldap-
	monitor/public/images/shadows/large-30-down.png, examples/ldap-
	monitor/public/images/tick.png, examples/ldap-
	monitor/public/images/tick_circle.png, examples/ldap-
	monitor/public/images/treequel-favicon.png, examples/ldap-
	monitor/views/backends.erb, examples/ldap-
	monitor/views/connections.erb, examples/ldap-
	monitor/views/databases.erb, examples/ldap-
	monitor/views/dump_subsystem.erb, examples/ldap-
	monitor/views/index.erb, examples/ldap-monitor/views/layout.erb,
	examples/ldap-monitor/views/listeners.erb, lib/treequel.rb:
	Treequel shell fix, splitting off the LDAP monitor example, version
	bump.

	* Removed the check for an existing user record from the 'bind'
	command, as the user in question might not be visible until the
	bind happens.
	* Split off the ldap-monitor example into a project of its own
	(http://deveiate.org/misc.html).
	* Bumped the version to 1.0.2.
	[31c326800cc6]

2009-12-16  Michael Granger  <ged@FaerieMUD.org>

	* Rakefile, lib/treequel/mixins.rb, project.yml:
	Updated build system, normalized comments in mixins.rb.
	[5fd4033e1556]

2009-12-11  Michael Granger  <ged@FaerieMUD.org>

	* Rakefile.local, experiments/paged_results_example.rb,
	lib/treequel/controls/pagedresults.rb, lib/treequel/directory.rb,
	lib/treequel/mixins.rb, misc/ruby-ldap-controlsfix.patch,
	spec/lib/control_behavior.rb, spec/treequel/control_spec.rb,
	spec/treequel/controls/pagedresults_spec.rb:
	More work on controls,
	* Added a spec:gdb task for running specs under GDB.
	* Added a port of the paged-results control example that comes with
	Ruby-LDAP using Treequel instead.
	* Warn in the PagedResultsControl if the Ruby-LDAP that's installed is
	0.9.9 or earlier, since those versions have broken #search_ext and
	#search_ext2 methods, and added a patch for 0.9.9.
	* Minimized the codepath differences between the two styles of
	Directory#search calls (with and without a block).
	* Added a shared behavior for control module specs.
	* Finished specs for the control module and the paged-results control.
	[b04972837e63]

2009-12-08  Michael Granger  <ged@FaerieMUD.org>

	* lib/treequel.rb, lib/treequel/branch.rb, lib/treequel/branchset.rb,
	lib/treequel/constants.rb, lib/treequel/control.rb,
	lib/treequel/controls/pagedresults.rb, lib/treequel/directory.rb,
	lib/treequel/exceptions.rb, spec/treequel/branchset_spec.rb,
	spec/treequel/control_spec.rb, spec/treequel/directory_spec.rb:
	Finished initial Controls implementation, added PagedResultsControl.
	* Added delegators for
	Branchset->Branch->Directory->Conn#{controls,referrals}
	* Freeze the Treequel::Constants::Pattern constants so collisions show
	up right away. We'll reduce the number of exported constants soon,
	and the remaining ones will be the more-unique ones, but this
	change will at least stop it from happening (relatively) silently.
	* Finished the implementation of Treequel::Control
	* added tests for inclusion of controls in the searches that happen
	through Branchset
	* Added the interface for registering controls with Directory objects
	* Added Treequel::PagedResultsControl, which doesn't work quite yet
	because of a problem fetching the search cookie from the results.
	Not sure if this is a bug in Ruby-LDAP, or on our end.
	[d1ef2c0f53f2]

2009-12-07  Mahlon E. Smith  <mahlon@martini.nu>

	* lib/treequel/control.rb, spec/treequel/control_spec.rb:
	Add scaffolding for Treequel::Control.
	[b937fbec04ca]

2009-12-07  Michael Granger  <ged@FaerieMUD.org>

	* Rakefile, experiments/control-syntax-spike.rb,
	lib/treequel/branch.rb, lib/treequel/branchset.rb,
	spec/treequel/branch_spec.rb, spec/treequel/branchset_spec.rb:
	Law of Demeter fix and more work on the controls spike.
	[30f67c57d0bb]

2009-12-06  Michael Granger  <ged@FaerieMUD.org>

	* .irbrc, Rakefile, bin/treequel, lib/treequel/branch.rb,
	lib/treequel/constants.rb, project.yml:
	Fixed the shell 'edit' command, cleaned up LDIF output, dependency
	fixes.
	- Made the LDIF output highlight correctly by adding LDIF regexen
	- Dup output values before converting them to LDIF
	- Removed dependencies are aren't required except for the 'treequel'
	shell.
	[014435b07b2d]

	* bin/treequel, lib/treequel.rb:
	Adding '+' mode to 'cat' (stolen from shelldap)
	[b259ac7d021e]

2009-12-01  Mahlon E. Smith  <mahlon@martini.nu>

	* Rakefile:
	Heh heh heh, he said 'fem'
	[150d5cf819a9]

2009-11-17  Michael Granger  <ged@FaerieMUD.org>

	* .hgtags:
	Added tag 1.0.1 for changeset 9c9993ba908e
	[ff8226a744d8]

	* .hgsigs:
	Added signature for changeset c5e4cb039999
	[9c9993ba908e] [1.0.1]

	* bin/treequel, lib/treequel/branchset.rb,
	spec/treequel/branchset_spec.rb:
	Added Branchset#as, added 'yaml'/disabled 'edit' command in treequel
	shell
	[c5e4cb039999]

	* Rakefile, project.yml:
	Updated build system.
	[67502a7b9224]

2009-11-10  Michael Granger  <ged@FaerieMUD.org>

	* .hgignore:
	Ignore .orig files
	[fd8e18e00cf5]

	* Rakefile, bin/treequel, lib/treequel/mixins.rb,
	lib/treequel/utils.rb:
	Factored out generic utility code from the treequel binary; added
	color logging
	[e7d7f6b3c101]

2009-10-27  Michael Granger  <ged@FaerieMUD.org>

	* lib/treequel/filter.rb, spec/treequel/filter_spec.rb:
	Fix a bug in #filter( String => String )
	[8a309df5700a]

2009-10-19  Michael Granger  <ged@FaerieMUD.org>

	* bin/treequel:
	Fixing highlighting for wrapped LDIF values in the treequel shell.
	[32cf480d20a5]

2009-10-15  Michael Granger  <ged@FaerieMUD.org>

	* Rakefile, bin/treequel, examples/ldap-rack-auth.rb,
	experiments/ohm.rb, lib/treequel.rb:
	Version bump, build system updates, made 'treequel' gem-binary-
	friendly, and some experiments.
	 * Beginnings of experimental rack middleware to do LDAP
	authentication.
	 * Taking a different tack in the OHM idea.
	 * Removed the $0 == __FILE__ wrapper around 'treequel' startup so it
	works from the gem.
	 * Bumping version to 1.0.1.
	[ca660bd12f7f]

2009-10-14  Michael Granger  <ged@FaerieMUD.org>

	* bin/treequel:
	Adding features to bin/treequel
	 * Persistant history
	 * Completion for attributes in command arguments
	 * New 'rm' and 'grep' commands
	 * Made the prompt for 'bind' a little clearer
	[9e4ba9a59fd3]

2009-10-11  Michael Granger  <ged@FaerieMUD.org>

	* bin/treequel:
	Factored out short- and long-ls output generation into separate
	methods
	[b375e07370b2]

2009-10-02  Michael Granger  <ged@FaerieMUD.org>

	* Rakefile, bin/treequel, lib/treequel.rb:
	* Fixed option parsing. Thanks to apeiros and dominikh on #Ruby-Pro
	@Freenode for their help.
	[ac1efb8eea87]

	* bin/treequel:
	* Trying a different strategy for option-parsing
	[311df09556e1]

2009-10-01  Michael Granger  <ged@FaerieMUD.org>

	* Automated merge with ssh://hg@repo.deveiate.org/Treequel
	[59c98c071fc3]

	* Merged 192 and 193
	[186ab733dad9]

2009-09-30  Michael Granger  <ged@FaerieMUD.org>

	* experiments/control-syntax-spike.rb, lib/treequel.rb, misc/ruby-
	terminfo-0.1.1.gem:
	Adding rebuilt terminfo gem and the beginnings of a spike to work
	out branch-control syntax
	[01e0025b7bdd]

2009-08-13  Michael Granger  <ged@FaerieMUD.org>

	* .hgtags:
	Added tag 1.0.0 for changeset 300dd8a5aa24
	[744c193e6f50]

	* .hgsigs:
	Added signature for changeset a4e90241950d
	[f907b569dcbe]

	* README, Rakefile, lib/treequel/directory.rb:
	Miscellaneous docs fixups.
	[af4cd38971b0]

	* README, lib/treequel/branchset.rb, spec/treequel/branchset_spec.rb:
	Adding Branchset#to_hash
	[98303f8ae4d2]

	* Rakefile, project.yml:
	Updated build system.
	[3622b1711521]

	* examples/company-directory.rb:
	Fixed the display in the company directory example template.
	[aeae86442cac]

	* .hgignore, LICENSE, README, docs/manual/src/index.page, examples
	/company-directory.rb, examples/ldap-monitor.rb:
	* Adding some more examples, updating the README.
	 * Moving benthanks to the README and manual instead of LICENSE.
	[24d2ac287c7a]

	* LICENSE, README, Rakefile, project.yml:
	Some cleanup and additions for release.
	[9f455dbd34ef]

	* lib/treequel.rb:
	Bumping version for release.
	[73f377edf18e]

	* Rakefile, docs/manual/resources/js/sh.js, lib/treequel/filter.rb,
	spec/lib/helpers.rb, spec/treequel/filter_spec.rb,
	spec/treequel/mixins_spec.rb:
	Fixes for Ruby 1.9.1.
	[4c3e13d4e6c3]

	* examples/ldap-monitor.rb, examples/ldap-
	monitor/public/css/master.css, examples/ldap-
	monitor/public/images/globe_small.png, examples/ldap-
	monitor/public/images/globe_small_green.png, examples/ldap-
	monitor/public/images/plug.png, examples/ldap-
	monitor/views/backends.erb, examples/ldap-
	monitor/views/databases.erb, examples/ldap-
	monitor/views/listeners.erb:
	More work on the ldap-monitor example.
	[b4408d13d3c1]

2009-08-12  Michael Granger  <ged@FaerieMUD.org>

	* docs/manual/resources/css/deveiate.css,
	docs/manual/resources/js/sh.js, docs/manual/src/index.page,
	lib/treequel/directory.rb, lib/treequel/mixins.rb:
	* Removing unused deveiate-theme stylesheet.
	 * Made examples use a new IRb SyntaxHighlighter brush instead of the
	Ruby one.
	 * More manual work.
	 * Fixed a bug in Treequel::Directory's default syntax mapping for
	boolean types.
	 * Fixed a bug in Treequel::Delegation for delegated methods passed in
	as Symbols.
	 * Made Directory delegate all possible Branch methods via its #base
	instead of just a few.
	[da86adb16b81]

	* examples/ldap-monitor/public/css/master.css:
	Committing CSS I forgot to commit with the last rev
	[ec8f2af665c6]

2009-08-11  Michael Granger  <ged@FaerieMUD.org>

	* docs/treequel-favicon.png, examples/ldap-monitor.rb, examples/ldap-
	monitor/public/css/master.css, examples/ldap-
	monitor/public/images/card_small.png, examples/ldap-
	monitor/public/images/chain_small.png, examples/ldap-
	monitor/public/images/tick.png, examples/ldap-
	monitor/public/images/tick_circle.png, examples/ldap-
	monitor/public/images/treequel-favicon.png, examples/ldap-
	monitor/views/backends.erb, examples/ldap-
	monitor/views/connections.erb, examples/ldap-
	monitor/views/dump_subsystem.erb, examples/ldap-
	monitor/views/layout.erb, examples/ldap_state.rb,
	spec/treequel_spec.rb:
	* Added another real-world example and added a bit more work to the
	web monitor app.
	 * Made the rev spec tolerant of keywords being turned on or off.
	[bfc759ec3d3a]

	* examples/ldap-monitor.rb, examples/ldap-
	monitor/public/css/master.css, examples/ldap-
	monitor/public/images/shadows/large-30-down.png, examples/ldap-
	monitor/views/connections.erb, examples/ldap-
	monitor/views/dump_subsystem.erb, examples/ldap-
	monitor/views/index.erb, examples/ldap-monitor/views/layout.erb,
	lib/treequel/branch.rb, spec/treequel/branch_spec.rb,
	spec/treequel_spec.rb:
	* Added my nascent LDAP web monitor sinatra app under examples/
	 * Re-worked the way Treequel::Branch#[] works, as OpenLDAP's
	operational attributes don't seem to be in its schema, or at
	least not how it's being fetched currently. Need to investigate
	cn=subschema.
	 * Fix the Treequel.version spec to expect the rev keyword.
	[c9e2a6b28d39]

2009-08-10  Michael Granger  <ged@FaerieMUD.org>

	* docs/manual/src/index.page, experiments/userservice.rb,
	lib/treequel.rb, lib/treequel/branch.rb,
	lib/treequel/branchcollection.rb, lib/treequel/branchset.rb,
	lib/treequel/directory.rb, lib/treequel/exceptions.rb,
	lib/treequel/filter.rb, lib/treequel/schema.rb,
	lib/treequel/schema/attributetype.rb,
	lib/treequel/schema/ldapsyntax.rb,
	lib/treequel/schema/matchingrule.rb,
	lib/treequel/schema/matchingruleuse.rb,
	lib/treequel/schema/objectclass.rb, spec/treequel_spec.rb:
	Stripped SVN constants and headers.
	[83fc292048c9]

	* .irbrc, docs/manual/src/index.page,
	lib/treequel/branchcollection.rb, lib/treequel/filter.rb,
	spec/treequel/branchcollection_spec.rb,
	spec/treequel/branchset_spec.rb, spec/treequel/filter_spec.rb:
	* More manual work
	 * Removed 'order' from BranchCollection
	 * Fixed hash-filters for Hashes that contain both single matches and
	composite matches.
	[0b6835347c3b]

	* docs/manual/resources/css/manual.css:
	Fixes for the manual footer
	[6b35527b9525]

	* .hgignore, docs/Treequel Manual Diagrams.graffle,
	docs/manual/layouts/default.page, docs/manual/layouts/intro.page,
	docs/manual/resources/css/manual.css, docs/manual/resources/images
	/dialog-error.png, docs/manual/resources/images/dialog-
	information.png, docs/manual/resources/images/dialog-warning.png,
	docs/manual/resources/images/emblem-important.png,
	docs/manual/resources/images/logo-small.png,
	docs/manual/src/index.page, lib/treequel/branch.rb,
	lib/treequel/branchset.rb, lib/treequel/directory.rb,
	spec/treequel/branchset_spec.rb:
	* Removing Branch#order, since the client-library sort attribute and
	function don't do server-side ordering.
	[dfe7e7e17359]

2009-08-05  Michael Granger  <ged@FaerieMUD.org>

	* docs/manual/resources/css/manual.css, docs/manual/src/index.page,
	lib/treequel/filter.rb, spec/treequel/filter_spec.rb:
	* Manual headings have a bit more top-margin.
	 * More manual work.
	 * Untangled Hash expressions from the Array cases and made them
	distinctly useful
	[21333d9653ff]

2009-08-03  Michael Granger  <ged@FaerieMUD.org>

	* docs/manual/src/index.page:
	Merged f9ac0e1fa95f
	[b1aa9a5642f5]

	* .irbrc, LICENSE, docs/manual/src/index.page:
	* Adding a prompt mode to the .irbrc for manual example generation.
	 * More manual work.
	 * Adding Mahlon to the license file.
	[4b7381e4c35c]

	* docs/manual/lib/examples-filter.rb,
	docs/manual/resources/css/manual.css, docs/manual/src/index.page:
	* Finished conversion of the manual to client-side syntax-
	highlighting instead of Ultraviolet.
	 * Merged some CSS from Redleaf's manual.
	[a0cbc5a505fb]

2009-08-01  Michael Granger  <ged@FaerieMUD.org>

	* docs/manual/src/index.page, experiments/filter-syntax-spike.rb,
	experiments/inspect_entry.rb, experiments/laika.rb,
	experiments/ohm.rb, experiments/syntax-spike.rb,
	lib/treequel/branch.rb, lib/treequel/mixins.rb,
	lib/treequel/utils.rb:
	* Added details about Branchset#filter, #scope, #limit, and #select
	 * Fixed the list of delegated branchset method in Treequel::Branch.
	[1d45903c1750]

2009-07-31  Michael Granger  <ged@FaerieMUD.org>

	* Rakefile, project.yml:
	Updated build system
	[a3aeb3c6c147]

	* .hgignore, Rakefile, docs/manual/src/index.page:
	Merged. Someday I'll get the hang of this.
	[0d8816a380da]

2009-07-29  Michael Granger  <ged@FaerieMUD.org>

	* .hgignore, Rakefile, docs/manual/src/index.page,
	lib/treequel/filter.rb, project.yml, spec/treequel/filter_spec.rb:
	* Adding coverage cache to the ignorefile.
	 * Added ruby-ldap dependency. Yay!
	 * More work on the manual.
	 * Made Treequel::Branch#filter treat a Hash like an array of tuples.
	[4ece63b2cc6e]

2009-07-28  Michael Granger  <ged@FaerieMUD.org>

	* .hgignore, Rakefile:
	Merged with 34cc97817266
	[067907cead97]

2009-07-27  Michael Granger  <ged@FaerieMUD.org>

	* .hgignore, Rakefile:
	Updated build system
	[109b2cbe661e]

	* Merging work from gont
	[e67354b564e1]

2009-07-24  Michael Granger  <ged@FaerieMUD.org>

	* .hgsub, .hgsubstate:
	Unlinking the subrepo, as it doesn't behave well enough quite yet.
	[9c59112d9e42]

2009-07-28  Michael Granger  <ged@FaerieMUD.org>

	* .hgignore, Rakefile, docs/manual/src/index.page:
	Manual rewording, .hgignore updates
	[4c4abfba98e0]

2009-07-24  Michael Granger  <ged@FaerieMUD.org>

	* .hgsub, .hgsubstate:
	Merging build system fixes
	[2e081686cd5d]

	* Rakefile:
	Updated build system
	[dcf67ec9818a] <build-system-fixes>

	* .hgsub, .hgsubstate, Rakefile:
	Removing subrepo, as it doesn't work quite the way I'd hoped.
	[b8de99344904] <build-system-fixes>

	* .hgignore, .hgsubstate, Rakefile, Rakefile.local, project.yml:
	Initial commit of Mercurial-based tasks
	[5415543ce713] <build-system-fixes>

2009-07-23  Michael Granger  <ged@FaerieMUD.org>

	* .hgsubstate, Rakefile, docs/treequel-red-small.png:
	Started converting svn-specific helpers and tasks to vcs-agnostic
	ones
	[48d9fbeb2d3e] <build-system-fixes>

2009-07-21  Michael Granger  <ged@FaerieMUD.org>

	* .hgsub, .hgsubstate:
	Adding experimental .hgsub for the rake tasklibs
	[ae447545aa01]

2009-07-21  Mahlon E. Smith  <mahlon@martini.nu>

	* docs/manual/src/index.page:
	Manual updates for Branches, Branchsets, and Directory.base.
	[7779841b6553]

2009-07-21  Michael Granger  <ged@FaerieMUD.org>

	* docs/manual/resources/images/cc-by.png, docs/manual/src/index.page,
	lib/treequel/branch.rb, lib/treequel/branchset.rb,
	lib/treequel/directory.rb, lib/treequel/schema/objectclass.rb,
	spec/treequel/directory_spec.rb:
	* Treequel::Branch
	   - Clear caches after a #delete
	   - Return self from #create
	 * Cleaned up Treequel::Schema::ObjectClass#inspect's return value a
	bit.
	 * Check for non-existant objectClasses to avoid calling
	NilClass#structural? in Treequel::Directory#create.
	 * Treequel::Branchset
	   - Cleaned up #inspect's return value
	   - New method: Sequel::Dataset-style #map
	 * Manual work
	 * Added a cc-by license badge instead of hitting creativecommons.org
	every time.
	[9baa3aa59ac7]

	* lib/treequel/branch.rb, lib/treequel/directory.rb,
	spec/treequel/branch_spec.rb, spec/treequel/directory_spec.rb:
	* Fixing Treequel::Branch#copy, which was mistakenly using a modrdn
	to copy.
	 * Removing Treequel::Directory#copy, which was based on a misreading
	of `ldap_modrdn2()`.
	[d227d5d6f07e]

2009-07-20  Michael Granger  <ged@FaerieMUD.org>

	* docs/manual/src/index.page, lib/treequel/branch.rb,
	lib/treequel/directory.rb, lib/treequel/mixins.rb:
	* Treequel::Branch: Don't freeze non-Arrays in the cached attribute
	values hash.
	 * Make a distinct copy of the log proxy for duplicated objects.
	 * Manual work.
	[7af3d5893bbe]

	* Rakefile, Rakefile.local, docs/manual/src/index.page,
	lib/treequel/directory.rb, lib/treequel/mixins.rb,
	spec/treequel/directory_spec.rb, spec/treequel/mixins_spec.rb:
	* Made the Hash merge function a module_function instead of a
	constant
	 * Added copying to the manual, and fixed it in Treequel::Directory.
	 * Added a local Rakefile, and added a manual-check task
	[0f343c7bac68]

	* docs/manual/src/index.page, lib/treequel/branch.rb,
	lib/treequel/directory.rb, spec/treequel/branch_spec.rb,
	spec/treequel/directory_spec.rb:
	* Added the ability to include operational attributes in
	Treequel::Branch at the class and instance level.
	 * Bumped logging around binding/rebinding to INFO level.
	[88a37f71375a]

2009-07-19  Michael Granger  <ged@FaerieMUD.org>

	* docs/manual/resources/images/wrap.png:
	Adding missing wrap.png for the manual
	[741f1a399ca8]

2009-07-18  Michael Granger  <ged@FaerieMUD.org>

	* docs/manual/resources/images/logo.png, docs/manual/src/index.page,
	docs/treequel-red.png, docs/treequel-red.svg,
	lib/treequel/constants.rb, lib/treequel/directory.rb,
	lib/treequel/schema/objectclass.rb,
	spec/treequel/schema/objectclass_spec.rb:
	* Make ObjectClass#sup return the corresponding ObjectClass
	instance.
	 * Added #get_extended_entry to Directory.
	 * More manual work.
	[6f0e1d82faa4]

2009-07-17  Michael Granger  <ged@FaerieMUD.org>

	* docs/manual/resources/css/manual.css,
	docs/manual/resources/images/arrow_225_small.png,
	docs/manual/resources/images/arrow_315_small.png,
	docs/manual/resources/images/arrow_skip.png,
	docs/manual/resources/images/information.png,
	docs/manual/resources/images/logo.png,
	docs/manual/resources/images/magnifier_left.png,
	docs/manual/resources/images/printer.png,
	docs/manual/resources/images/question.png,
	docs/manual/resources/images/scripts_code.png,
	docs/manual/resources/js/manual.js, docs/manual/src/index.page, docs
	/treequel-red-medium.png, docs/treequel-red-small.png, docs
	/treequel-red.png, docs/treequel-red.svg, docs/treequel.svg:
	Cleaned up the manual syntax-highlighting a bunch. Red logo!
	[b470955b4277]

	* docs/manual/layouts/intro.page, docs/manual/lib/examples-filter.rb,
	docs/manual/resources/css/manual.css,
	docs/manual/resources/images/help.png,
	docs/manual/resources/images/magnifier.png,
	docs/manual/resources/images/page_white_code.png,
	docs/manual/resources/images/page_white_copy.png,
	docs/manual/resources/images/printer.png,
	docs/manual/resources/images/wrapping.png,
	docs/manual/resources/js/manual.js, docs/manual/resources/js/sh.js,
	docs/manual/resources/swf/clipboard.swf, docs/manual/src/index.page:
	Use client-side highlighting instead of Ultraviolet.
	[31ce6958889d]

2009-07-17  Mahlon E. Smith  <mahlon@martini.nu>

	* docs/manual/src/index.page, lib/treequel/branch.rb,
	spec/treequel/branch_spec.rb:
	* Wrap branch rdn attributes in an array for easy mungin' and
	merging.
	* Fix base_dn option from URI parsing and options hash.
	* Minor manual updates.
	[2f1b04aa4c88]

2009-07-17  Michael Granger  <ged@FaerieMUD.org>

	* docs/manual/lib/editorial-filter.rb,
	docs/manual/resources/css/manual.css,
	docs/manual/resources/js/manual.js, docs/manual/src/index.page:
	* Manual work.
	[7fec5e5e47cf]

	* docs/manual/layouts/intro.page,
	docs/manual/resources/images/logo.png,
	docs/manual/resources/js/jquery-1.3.2.min.js,
	docs/manual/resources/js/jquery.ThickBox.js,
	docs/manual/resources/js/manual.js, docs/manual/src/index.page:
	* Logo and other manual work
	 * Added the missing resources/js/ dir to the manual
	[4a9186101ea3]

	* bin/treequel, docs/manual/src/index.page, docs/treequel-blue.svgz,
	lib/treequel/branch.rb, lib/treequel/directory.rb,
	lib/treequel/schema/objectclass.rb, spec/treequel/branch_spec.rb,
	spec/treequel/directory_spec.rb:
	* Treequel::Branch
	   - Added #exists?, #get_child,
	   - Fixed #object_classes and other schema-related methods.
	 * Added Treequel::Schema::ObjectClass#structural?
	 * Added some fixes for Ruby/LDAP 0.9.9.
	[eea6b8cff79a]

2009-07-16  Mahlon E. Smith  <mahlon@martini.nu>

	* docs/manual/src/index.page, lib/treequel.rb, lib/treequel/branch.rb,
	lib/treequel/directory.rb, spec/treequel/branch_spec.rb,
	spec/treequel/directory_spec.rb, spec/treequel_spec.rb:
	* Wrap branch rdn attributes in an array for easy mungin' and
	merging.
	* Fix base_dn option from URI parsing and options hash.
	* Minor manual updates.
	[b27a0b79f367]

2009-07-15  Michael Granger  <ged@FaerieMUD.org>

	* lib/treequel/branch.rb, lib/treequel/filter.rb,
	spec/treequel/filter_spec.rb:
	* Order attributes by their key when composing a multi-value RDN
	from a pair + a Hash for predictabilty.
	 * Added support for negated Sequel expressions (e.g., `~:cn` =>
	`(!(cn=*))`, `~{:cn => 'foo'}` => `(!(cn=foo))` )
	[191820b894dc]

	* docs/treequel.svgz:
	Adding logo
	[9e3c3d925484]

2009-07-13  Michael Granger  <ged@FaerieMUD.org>

	* Rakefile, docs/manual/src/index.page, experiments/ohm.rb,
	lib/treequel.rb, lib/treequel/branch.rb,
	lib/treequel/branchcollection.rb, lib/treequel/branchset.rb,
	lib/treequel/constants.rb, lib/treequel/directory.rb,
	lib/treequel/schema.rb, lib/treequel/schema/ldapsyntax.rb,
	lib/treequel/schema/matchingrule.rb,
	lib/treequel/schema/matchingruleuse.rb,
	spec/treequel/branch_spec.rb,
	spec/treequel/branchcollection_spec.rb,
	spec/treequel/branchset_spec.rb, spec/treequel/directory_spec.rb,
	spec/treequel_spec.rb:
	* Updated build system
	 * Treequel::Branch:
	   - refactored so it uses its DN for everything instead of having to
	constantly build its DN from its RDN attribute/value pair.
	   - added support for multi-value RDNs (e.g., cn=foo+l=bar)
	   - new method: #uri
	 * Commented out the spammy debug from the schema-parsing functions
	 * Treequel::Directory
	   - Renamed #basedn to #base_dn
	   - Added #base method for creating a Branch that wraps the base DN
	   - Delegate Branch-ish methods through the new #base branch.
	   - New method #uri
	   - Refactored search methods to use search_ext2 for efficiency
	 * Treequel::Branchset
	   - refactored to explicitly use a Branch
	   - made it Enumerable and refactored #all out as an alias for #entries
	   - added a convenience method for creating a BranchCollection from the
	Branchset's results
	 * Treequel::BranchCollection
	   - made it Enumerable through each branchset's #each; refactored #all
	as an alias for #entries
	 * Treequel::Constants
	   - Added an inverse mapping for SCOPE.
	   - Disambiguated the 'ESCAPED' pattern for DNs from the one for
	attribute values.
	 * Updated the manual
	[aa1a22869419]

2009-07-08  Michael Granger  <ged@FaerieMUD.org>

	* bin/treequel, experiments/dn.abnf, experiments/ohm.rb,
	lib/treequel/branch.rb, lib/treequel/constants.rb,
	lib/treequel/directory.rb, spec/treequel/directory_spec.rb:
	* A bit more hacking on the OHM experiment.
	 * Treequel::Branch
	   - Made attribute values in #must_attributes_hash empty strings to
	distinguish them from those created by #may_attributes_hash.
	   - Added #valid_attributes_hash as a convenience method for a merged
	`must_attributes_hash` and `may_attributes_hash`.
	 * Made the collection class returned from Treequel::Directory#search
	settable via a hash parameter, with fallback to the class of the
	base argument if it supports `new_from_entry` or Treequel::Branch
	if not.
	 * Added RFC 4514 (Distinguished Names) productions to
	Treequel::Constants::Patterns
	 * Treequel shell:
	   - Changed the 'cd' command to 'cdn'
	   - Validate the RDN passed to 'cdn'
	   - Added a 'parent' command to allow changing up one RDN
	   - Added a 'log' command to allow setting of log level, default log
	level to 'WARN'
	[4f3928271278]

2009-07-03  Michael Granger  <ged@FaerieMUD.org>

	* docs/manual/src/index.page, lib/treequel/branch.rb,
	lib/treequel/branchset.rb, lib/treequel/directory.rb,
	lib/treequel/schema/objectclass.rb, spec/treequel/branch_spec.rb,
	spec/treequel/branchset_spec.rb, spec/treequel/directory_spec.rb:
	* Treequel::Branch
	   - Made entry-fetching not raise an exception, but just return nil
	instead.
	   - Added #must_attributes_hash and #may_attributes_hash
	   - Added a splat-array to #object_classes, #must_attribute_types,
	#must_oids, #may_attribute_types, #may_oids,
	 * Added a logged warning for the case-sensitivity bug
	 * Refactored the parameter-normalization stuff out of
	Treequel::Directory#search method for readability, and to
	simplify the argument signature of #search.
	[878ce9a276b2]

2009-07-02  Michael Granger  <ged@FaerieMUD.org>

	* docs/manual/src/index.page, experiments/delegation_cost.rb,
	experiments/userservice.rb, lib/treequel/branch.rb,
	lib/treequel/branchset.rb, lib/treequel/directory.rb,
	lib/treequel/filter.rb, spec/treequel/branch_spec.rb,
	spec/treequel/branchset_spec.rb, spec/treequel/directory_spec.rb,
	spec/treequel/filter_spec.rb:
	* Adding experimental Arrow service that uses Treequel to return
	ou=People records.
	 * Made Branch#create create the underlying entry instead of a child to
	better match what #delete, #modify, etc. are doing.
	 * Treequel::Directory:
	   - Fixed the argument list passed to LDAP::Conn#search_ext2 to match
	what the actual code expects.
	   - Modified #create to create the entry underlying the branch passed in
	the first argument instead of an entry specified by RDN.
	 * Treequel::Filter:
	   - Factored out the tuple-parsing part of .parse_array_expression into
	a separate method.
	   - Added a fallback to tuple-style expressions to handle expressions
	like { :uidNumber => 1414 }
	 * Treequel::Branchset
	   - Made it Enumerable
	   - Added #limit
	 * More work on the manual
	[f9b545b72c09]

2009-06-30  Michael Granger  <ged@FaerieMUD.org>

	* experiments/ohm.rb, spec/treequel/filter_spec.rb:
	Removing the call to `Time.today` from the specs, as it requires the
	loading of 'time'.
	[a5b773de4514]

	* lib/treequel/branch.rb, lib/treequel/connection.rb,
	lib/treequel/directory.rb, spec/treequel/branch_spec.rb,
	spec/treequel/connection_spec.rb, spec/treequel/directory_spec.rb:
	* Added Treequel::Branch#to_ufn
	 * Removed Treequel::Connection class in favor of just handling the
	specific problems in the #search method.
	 * Changed Treequel::Directory#search to be implemented in terms of
	#search_ext2 instead of the deprecated #search2
	[9e88e5e2559c]

2009-06-29  Michael Granger  <ged@FaerieMUD.org>

	* experiments/ohm.rb, lib/treequel/filter.rb,
	spec/treequel/filter_spec.rb:
	* Adding the beginnings of an experimental object-mapping (tree-
	based ORM analogue) for LDAP entries.
	 * Added handling for > and < Sequel expressions
	[e34950351275]

2009-06-27  Michael Granger  <ged@FaerieMUD.org>

	* lib/treequel/utils.rb:
	Updated HTML logger formatter to the latest.
	[3bfc1759a408]

2009-06-25  Michael Granger  <ged@FaerieMUD.org>

	* docs/manual/src/index.page, lib/treequel/branch.rb,
	spec/treequel/branch_spec.rb:
	* Renamed Treequel::Branch#modify to #merge
	 * More manual work.
	[ba8c0f6589c3]

2009-06-24  Michael Granger  <ged@FaerieMUD.org>

	* docs/manual/src/index.page:
	Fixed some LAIKA references in the manual.
	[9fc34044d06a]

2009-06-23  Michael Granger  <ged@FaerieMUD.org>

	* docs/Treequel Manual Diagrams.graffle,
	docs/manual/layouts/intro.page,
	docs/manual/resources/css/manual.css, docs/manual/src/index.page,
	lib/treequel.rb, lib/treequel/constants.rb,
	lib/treequel/directory.rb, lib/treequel/mixins.rb,
	spec/treequel/directory_spec.rb, spec/treequel_spec.rb:
	* Fixed docs on the binding arguments for
	Treequel::Directory#initialize.
	 * Fixed some typos.
	 * Stopdoc'ed the sub-modules under Treequel::Constants.
	 * Made Treequel.directory more flexible.
	 * Added a tentative logo to the diagrams.
	 * Updated the manual CSS and templates from Redleaf's.
	 * Manual work.
	 * Made the initial argument to Treequel::Directory#bind accept an
	object that duck-types as a Branch.
	[79dbb11efb67]

	* lib/treequel/connection.rb, lib/treequel/directory.rb,
	lib/treequel/mixins.rb, spec/treequel/connection_spec.rb:
	* Added delegation to the connection wrapper.
	 * Fixed a bug in the Treequel::Delegation code-generation when it
	generates a delegated assignment method (#foo=).
	[13c3ae870b11]

2009-06-22  Michael Granger  <ged@FaerieMUD.org>

	* docs/manual/layouts/default.page, docs/manual/src/index.page,
	lib/treequel.rb, lib/treequel/branch.rb,
	lib/treequel/branchcollection.rb, lib/treequel/branchset.rb,
	lib/treequel/connection.rb, lib/treequel/constants.rb,
	lib/treequel/directory.rb, lib/treequel/exceptions.rb,
	lib/treequel/filter.rb, lib/treequel/schema.rb,
	lib/treequel/schema/attributetype.rb,
	lib/treequel/schema/ldapsyntax.rb,
	lib/treequel/schema/matchingrule.rb,
	lib/treequel/schema/matchingruleuse.rb,
	lib/treequel/schema/objectclass.rb,
	spec/treequel/connection_spec.rb, spec/treequel/directory_spec.rb,
	spec/treequel/filter_spec.rb:
	* Fixed RDoc headers.
	 * Started work on a connection-abstraction that handles referrals,
	exception-normalization, and reconnection.
	 * Merged filter constants into the Constants module's namespace and
	factored out some duplication and inconsistency.
	 * Some manual work.
	 * Fixed a buggy substring filter spec that was uncovered by the
	constants refactoring.
	[726aa7f95eb7]

2009-06-18  Michael Granger  <ged@FaerieMUD.org>

	* README, Rakefile, docs/Treequel Manual Diagrams.graffle,
	lib/treequel.rb, lib/treequel/schema.rb, project.yml,
	spec/treequel/schema_spec.rb:
	* Updated the build system.
	 * Untaint all schema names before trying to turn them into Symbols so
	it works under $SAFE = 1.
	 * Fixed some documentation, updated the description with something
	less-vague.
	[062424db136b]

	* Rakefile, lib/treequel.rb, lib/treequel/branch.rb,
	lib/treequel/branchcollection.rb, lib/treequel/branchset.rb,
	spec/lib/constants.rb, spec/treequel/branch_spec.rb,
	spec/treequel/branchcollection_spec.rb,
	spec/treequel/branchset_spec.rb, spec/treequel_spec.rb:
	* Adding BranchCollection class.
	 * Treequel::Branchset
	   - Added #base_dn method
	   - Added the base to the inspection text
	 * Made argument to Treequel.directory optional
	[d175301aab61]

2009-10-01  Michael Granger  <ged@FaerieMUD.org>

	* bin/treequel:
	* More work on option-parsing
	[a4acbdcb366e]

2009-09-30  Michael Granger  <ged@FaerieMUD.org>

	* bin/treequel:
	Worked on the treequel shell, adding option-parsing and help
	[b1374ce2d79b]

	* bin/treequel, lib/treequel/directory.rb:
	* Fixes for the treequel shell, which was very broken in the initial
	release. :/
	 * Fixed method docs for Treequel::Directory#bind
	[0de4d48e9b2d]

2009-08-13  Michael Granger  <ged@FaerieMUD.org>

	* .hgtags:
	Added tag 1.0.0 for changeset 300dd8a5aa24
	[104e3d7685c3]

	* .hgsigs:
	Added signature for changeset a4e90241950d
	[300dd8a5aa24] [1.0.0]

	* README, Rakefile, lib/treequel/directory.rb:
	Miscellaneous docs fixups.
	[a4e90241950d]

	* README, lib/treequel/branchset.rb, spec/treequel/branchset_spec.rb:
	Adding Branchset#to_hash
	[e98fb34df0c0]

	* Rakefile, project.yml:
	Updated build system.
	[e18bfe831135]

	* examples/company-directory.rb:
	Fixed the display in the company directory example template.
	[a8927110eaa6]

	* .hgignore, LICENSE, README, docs/manual/src/index.page, examples
	/company-directory.rb, examples/ldap-monitor.rb:
	* Adding some more examples, updating the README.
	 * Moving benthanks to the README and manual instead of LICENSE.
	[dddcad307b99]

	* LICENSE, README, Rakefile, project.yml:
	Some cleanup and additions for release.
	[c8fc81f20772]

	* lib/treequel.rb:
	Bumping version for release.
	[e352bc86498a]

	* Rakefile, docs/manual/resources/js/sh.js, lib/treequel/filter.rb,
	spec/lib/helpers.rb, spec/treequel/filter_spec.rb,
	spec/treequel/mixins_spec.rb:
	Fixes for Ruby 1.9.1.
	[73775f828f6b]

	* examples/ldap-monitor.rb, examples/ldap-
	monitor/public/css/master.css, examples/ldap-
	monitor/public/images/globe_small.png, examples/ldap-
	monitor/public/images/globe_small_green.png, examples/ldap-
	monitor/public/images/plug.png, examples/ldap-
	monitor/views/backends.erb, examples/ldap-
	monitor/views/databases.erb, examples/ldap-
	monitor/views/listeners.erb:
	More work on the ldap-monitor example.
	[af19a52bb21a]

2009-08-12  Michael Granger  <ged@FaerieMUD.org>

	* docs/manual/resources/css/deveiate.css,
	docs/manual/resources/js/sh.js, docs/manual/src/index.page,
	lib/treequel/directory.rb, lib/treequel/mixins.rb:
	* Removing unused deveiate-theme stylesheet.
	 * Made examples use a new IRb SyntaxHighlighter brush instead of the
	Ruby one.
	 * More manual work.
	 * Fixed a bug in Treequel::Directory's default syntax mapping for
	boolean types.
	 * Fixed a bug in Treequel::Delegation for delegated methods passed in
	as Symbols.
	 * Made Directory delegate all possible Branch methods via its #base
	instead of just a few.
	[809044df70bd]

	* examples/ldap-monitor/public/css/master.css:
	Committing CSS I forgot to commit with the last rev
	[633687b023c4]

2009-08-11  Michael Granger  <ged@FaerieMUD.org>

	* docs/treequel-favicon.png, examples/ldap-monitor.rb, examples/ldap-
	monitor/public/css/master.css, examples/ldap-
	monitor/public/images/card_small.png, examples/ldap-
	monitor/public/images/chain_small.png, examples/ldap-
	monitor/public/images/tick.png, examples/ldap-
	monitor/public/images/tick_circle.png, examples/ldap-
	monitor/public/images/treequel-favicon.png, examples/ldap-
	monitor/views/backends.erb, examples/ldap-
	monitor/views/connections.erb, examples/ldap-
	monitor/views/dump_subsystem.erb, examples/ldap-
	monitor/views/layout.erb, examples/ldap_state.rb,
	spec/treequel_spec.rb:
	* Added another real-world example and added a bit more work to the
	web monitor app.
	 * Made the rev spec tolerant of keywords being turned on or off.
	[f9551821eced]

	* examples/ldap-monitor.rb, examples/ldap-
	monitor/public/css/master.css, examples/ldap-
	monitor/public/images/shadows/large-30-down.png, examples/ldap-
	monitor/views/connections.erb, examples/ldap-
	monitor/views/dump_subsystem.erb, examples/ldap-
	monitor/views/index.erb, examples/ldap-monitor/views/layout.erb,
	lib/treequel/branch.rb, spec/treequel/branch_spec.rb,
	spec/treequel_spec.rb:
	* Added my nascent LDAP web monitor sinatra app under examples/
	 * Re-worked the way Treequel::Branch#[] works, as OpenLDAP's
	operational attributes don't seem to be in its schema, or at
	least not how it's being fetched currently. Need to investigate
	cn=subschema.
	 * Fix the Treequel.version spec to expect the rev keyword.
	[85dadbaf70a9]

2009-08-10  Michael Granger  <ged@FaerieMUD.org>

	* docs/manual/src/index.page, experiments/userservice.rb,
	lib/treequel.rb, lib/treequel/branch.rb,
	lib/treequel/branchcollection.rb, lib/treequel/branchset.rb,
	lib/treequel/directory.rb, lib/treequel/exceptions.rb,
	lib/treequel/filter.rb, lib/treequel/schema.rb,
	lib/treequel/schema/attributetype.rb,
	lib/treequel/schema/ldapsyntax.rb,
	lib/treequel/schema/matchingrule.rb,
	lib/treequel/schema/matchingruleuse.rb,
	lib/treequel/schema/objectclass.rb, spec/treequel_spec.rb:
	Stripped SVN constants and headers.
	[c8c4db6916f1]

	* .irbrc, docs/manual/src/index.page,
	lib/treequel/branchcollection.rb, lib/treequel/filter.rb,
	spec/treequel/branchcollection_spec.rb,
	spec/treequel/branchset_spec.rb, spec/treequel/filter_spec.rb:
	* More manual work
	 * Removed 'order' from BranchCollection
	 * Fixed hash-filters for Hashes that contain both single matches and
	composite matches.
	[3624f71a141d]

	* docs/manual/resources/css/manual.css:
	Fixes for the manual footer
	[1b0eaa8f5a64]

	* .hgignore, docs/Treequel Manual Diagrams.graffle,
	docs/manual/layouts/default.page, docs/manual/layouts/intro.page,
	docs/manual/resources/css/manual.css, docs/manual/resources/images
	/dialog-error.png, docs/manual/resources/images/dialog-
	information.png, docs/manual/resources/images/dialog-warning.png,
	docs/manual/resources/images/emblem-important.png,
	docs/manual/resources/images/logo-small.png,
	docs/manual/src/index.page, lib/treequel/branch.rb,
	lib/treequel/branchset.rb, lib/treequel/directory.rb,
	spec/treequel/branchset_spec.rb:
	* Removing Branch#order, since the client-library sort attribute and
	function don't do server-side ordering.
	[72833e18e4f8]

2009-08-05  Michael Granger  <ged@FaerieMUD.org>

	* docs/manual/resources/css/manual.css, docs/manual/src/index.page,
	lib/treequel/filter.rb, spec/treequel/filter_spec.rb:
	* Manual headings have a bit more top-margin.
	 * More manual work.
	 * Untangled Hash expressions from the Array cases and made them
	distinctly useful
	[bacf91784530]

2009-08-03  Michael Granger  <ged@FaerieMUD.org>

	* docs/manual/src/index.page:
	Merged f9ac0e1fa95f
	[b53d391399ce]

	* docs/manual/lib/examples-filter.rb,
	docs/manual/resources/css/manual.css, docs/manual/src/index.page:
	* Finished conversion of the manual to client-side syntax-
	highlighting instead of Ultraviolet.
	 * Merged some CSS from Redleaf's manual.
	[afeff031274d]

	* .irbrc, LICENSE, docs/manual/src/index.page:
	* Adding a prompt mode to the .irbrc for manual example generation.
	 * More manual work.
	 * Adding Mahlon to the license file.
	[f9ac0e1fa95f]

2009-08-01  Michael Granger  <ged@FaerieMUD.org>

	* docs/manual/src/index.page, experiments/filter-syntax-spike.rb,
	experiments/inspect_entry.rb, experiments/laika.rb,
	experiments/ohm.rb, experiments/syntax-spike.rb,
	lib/treequel/branch.rb, lib/treequel/mixins.rb,
	lib/treequel/utils.rb:
	* Added details about Branchset#filter, #scope, #limit, and #select
	 * Fixed the list of delegated branchset method in Treequel::Branch.
	[1ddf7d4212c7]

2009-07-31  Michael Granger  <ged@FaerieMUD.org>

	* Rakefile, project.yml:
	Updated build system
	[6b5358420802]

	* .hgignore, Rakefile, docs/manual/src/index.page:
	Merged. Someday I'll get the hang of this.
	[a5e715f5f877]

2009-07-28  Michael Granger  <ged@FaerieMUD.org>

	* .hgignore, Rakefile:
	Merged with 34cc97817266
	[395b7bf6f248]

	* .hgignore, Rakefile, docs/manual/src/index.page:
	Manual rewording, .hgignore updates
	[89f74035c67d]

2009-07-29  Michael Granger  <ged@FaerieMUD.org>

	* .hgignore, Rakefile, docs/manual/src/index.page,
	lib/treequel/filter.rb, project.yml, spec/treequel/filter_spec.rb:
	* Adding coverage cache to the ignorefile.
	 * Added ruby-ldap dependency. Yay!
	 * More work on the manual.
	 * Made Treequel::Branch#filter treat a Hash like an array of tuples.
	[46e6dce0c011]

2009-07-27  Michael Granger  <ged@FaerieMUD.org>

	* .hgignore, Rakefile:
	Updated build system
	[34cc97817266]

	* Merging work from gont
	[daf0e44c41ac]

2009-07-24  Michael Granger  <ged@FaerieMUD.org>

	* .hgsub, .hgsubstate:
	Merging build system fixes
	[b7a919b2ad5d]

	* Rakefile:
	Updated build system
	[620807d4c6d5] <build-system-fixes>

	* .hgsub, .hgsubstate, Rakefile:
	Removing subrepo, as it doesn't work quite the way I'd hoped.
	[f631900a9ad8] <build-system-fixes>

	* .hgsub, .hgsubstate:
	Unlinking the subrepo, as it doesn't behave well enough quite yet.
	[fc3c3bac2c22]

	* .hgignore, .hgsubstate, Rakefile, Rakefile.local, project.yml:
	Initial commit of Mercurial-based tasks
	[65236b2101e5] <build-system-fixes>

2009-07-23  Michael Granger  <ged@FaerieMUD.org>

	* .hgsubstate, Rakefile, docs/treequel-red-small.png:
	Started converting svn-specific helpers and tasks to vcs-agnostic
	ones
	[76e4c3cc308b] <build-system-fixes>

2009-07-21  Michael Granger  <ged@FaerieMUD.org>

	* .hgsub, .hgsubstate:
	Adding experimental .hgsub for the rake tasklibs
	[8be8e94f829d]

2009-07-21  Mahlon E. Smith  <mahlon@martini.nu>

	* docs/manual/src/index.page:
	Manual updates for Branches, Branchsets, and Directory.base.
	[7bd626d9f0cd]

2009-07-21  Michael Granger  <ged@FaerieMUD.org>

	* docs/manual/resources/images/cc-by.png, docs/manual/src/index.page,
	lib/treequel/branch.rb, lib/treequel/branchset.rb,
	lib/treequel/directory.rb, lib/treequel/schema/objectclass.rb,
	spec/treequel/directory_spec.rb:
	* Treequel::Branch
	   - Clear caches after a #delete
	   - Return self from #create
	 * Cleaned up Treequel::Schema::ObjectClass#inspect's return value a
	bit.
	 * Check for non-existant objectClasses to avoid calling
	NilClass#structural? in Treequel::Directory#create.
	 * Treequel::Branchset
	   - Cleaned up #inspect's return value
	   - New method: Sequel::Dataset-style #map
	 * Manual work
	 * Added a cc-by license badge instead of hitting creativecommons.org
	every time.
	[8ca3428f711e]

	* lib/treequel/branch.rb, lib/treequel/directory.rb,
	spec/treequel/branch_spec.rb, spec/treequel/directory_spec.rb:
	* Fixing Treequel::Branch#copy, which was mistakenly using a modrdn
	to copy.
	 * Removing Treequel::Directory#copy, which was based on a misreading
	of `ldap_modrdn2()`.
	[15bfd9785019]

2009-07-20  Michael Granger  <ged@FaerieMUD.org>

	* docs/manual/src/index.page, lib/treequel/branch.rb,
	lib/treequel/directory.rb, lib/treequel/mixins.rb:
	* Treequel::Branch: Don't freeze non-Arrays in the cached attribute
	values hash.
	 * Make a distinct copy of the log proxy for duplicated objects.
	 * Manual work.
	[74b7a9bca977]

	* Rakefile, Rakefile.local, docs/manual/src/index.page,
	lib/treequel/directory.rb, lib/treequel/mixins.rb,
	spec/treequel/directory_spec.rb, spec/treequel/mixins_spec.rb:
	* Made the Hash merge function a module_function instead of a
	constant
	 * Added copying to the manual, and fixed it in Treequel::Directory.
	 * Added a local Rakefile, and added a manual-check task
	[3e4105c3ebaa]

	* docs/manual/src/index.page, lib/treequel/branch.rb,
	lib/treequel/directory.rb, spec/treequel/branch_spec.rb,
	spec/treequel/directory_spec.rb:
	* Added the ability to include operational attributes in
	Treequel::Branch at the class and instance level.
	 * Bumped logging around binding/rebinding to INFO level.
	[7a62ac4c346b]

2009-07-19  Michael Granger  <ged@FaerieMUD.org>

	* docs/manual/resources/images/wrap.png:
	Adding missing wrap.png for the manual
	[206b077875e5]

2009-07-18  Michael Granger  <ged@FaerieMUD.org>

	* docs/manual/resources/images/logo.png, docs/manual/src/index.page,
	docs/treequel-red.png, docs/treequel-red.svg,
	lib/treequel/constants.rb, lib/treequel/directory.rb,
	lib/treequel/schema/objectclass.rb,
	spec/treequel/schema/objectclass_spec.rb:
	* Make ObjectClass#sup return the corresponding ObjectClass
	instance.
	 * Added #get_extended_entry to Directory.
	 * More manual work.
	[1505adefc436]

2009-07-17  Michael Granger  <ged@FaerieMUD.org>

	* docs/manual/resources/css/manual.css,
	docs/manual/resources/images/arrow_225_small.png,
	docs/manual/resources/images/arrow_315_small.png,
	docs/manual/resources/images/arrow_skip.png,
	docs/manual/resources/images/information.png,
	docs/manual/resources/images/logo.png,
	docs/manual/resources/images/magnifier_left.png,
	docs/manual/resources/images/printer.png,
	docs/manual/resources/images/question.png,
	docs/manual/resources/images/scripts_code.png,
	docs/manual/resources/js/manual.js, docs/manual/src/index.page, docs
	/treequel-red-medium.png, docs/treequel-red-small.png, docs
	/treequel-red.png, docs/treequel-red.svg, docs/treequel.svg:
	Cleaned up the manual syntax-highlighting a bunch. Red logo!
	[12ec14055953]

	* docs/manual/layouts/intro.page, docs/manual/lib/examples-filter.rb,
	docs/manual/resources/css/manual.css,
	docs/manual/resources/images/help.png,
	docs/manual/resources/images/magnifier.png,
	docs/manual/resources/images/page_white_code.png,
	docs/manual/resources/images/page_white_copy.png,
	docs/manual/resources/images/printer.png,
	docs/manual/resources/images/wrapping.png,
	docs/manual/resources/js/manual.js, docs/manual/resources/js/sh.js,
	docs/manual/resources/swf/clipboard.swf, docs/manual/src/index.page:
	Use client-side highlighting instead of Ultraviolet.
	[8c8193c00a6a]

2009-07-17  Mahlon E. Smith  <mahlon@martini.nu>

	* docs/manual/src/index.page, lib/treequel/branch.rb,
	spec/treequel/branch_spec.rb:
	* Wrap branch rdn attributes in an array for easy mungin' and
	merging.
	* Fix base_dn option from URI parsing and options hash.
	* Minor manual updates.
	[1e2391e73329]

2009-07-17  Michael Granger  <ged@FaerieMUD.org>

	* docs/manual/lib/editorial-filter.rb,
	docs/manual/resources/css/manual.css,
	docs/manual/resources/js/manual.js, docs/manual/src/index.page:
	* Manual work.
	[96e0654c8652]

	* docs/manual/layouts/intro.page,
	docs/manual/resources/images/logo.png,
	docs/manual/resources/js/jquery-1.3.2.min.js,
	docs/manual/resources/js/jquery.ThickBox.js,
	docs/manual/resources/js/manual.js, docs/manual/src/index.page:
	* Logo and other manual work
	 * Added the missing resources/js/ dir to the manual
	[3e2835dbe859]

	* bin/treequel, docs/manual/src/index.page, docs/treequel-blue.svgz,
	lib/treequel/branch.rb, lib/treequel/directory.rb,
	lib/treequel/schema/objectclass.rb, spec/treequel/branch_spec.rb,
	spec/treequel/directory_spec.rb:
	* Treequel::Branch
	   - Added #exists?, #get_child,
	   - Fixed #object_classes and other schema-related methods.
	 * Added Treequel::Schema::ObjectClass#structural?
	 * Added some fixes for Ruby/LDAP 0.9.9.
	[cf1c7d481519]

2009-07-16  Mahlon E. Smith  <mahlon@martini.nu>

	* docs/manual/src/index.page, lib/treequel.rb, lib/treequel/branch.rb,
	lib/treequel/directory.rb, spec/treequel/branch_spec.rb,
	spec/treequel/directory_spec.rb, spec/treequel_spec.rb:
	* Wrap branch rdn attributes in an array for easy mungin' and
	merging.
	* Fix base_dn option from URI parsing and options hash.
	* Minor manual updates.
	[bf47d67f76f1]

2009-07-15  Michael Granger  <ged@FaerieMUD.org>

	* lib/treequel/branch.rb, lib/treequel/filter.rb,
	spec/treequel/filter_spec.rb:
	* Order attributes by their key when composing a multi-value RDN
	from a pair + a Hash for predictabilty.
	 * Added support for negated Sequel expressions (e.g., `~:cn` =>
	`(!(cn=*))`, `~{:cn => 'foo'}` => `(!(cn=foo))` )
	[7d8dc70f5fe1]

	* docs/treequel.svgz:
	Adding logo
	[f21be0277b19]

2009-07-13  Michael Granger  <ged@FaerieMUD.org>

	* Rakefile, docs/manual/src/index.page, experiments/ohm.rb,
	lib/treequel.rb, lib/treequel/branch.rb,
	lib/treequel/branchcollection.rb, lib/treequel/branchset.rb,
	lib/treequel/constants.rb, lib/treequel/directory.rb,
	lib/treequel/schema.rb, lib/treequel/schema/ldapsyntax.rb,
	lib/treequel/schema/matchingrule.rb,
	lib/treequel/schema/matchingruleuse.rb,
	spec/treequel/branch_spec.rb,
	spec/treequel/branchcollection_spec.rb,
	spec/treequel/branchset_spec.rb, spec/treequel/directory_spec.rb,
	spec/treequel_spec.rb:
	* Updated build system
	 * Treequel::Branch:
	   - refactored so it uses its DN for everything instead of having to
	constantly build its DN from its RDN attribute/value pair.
	   - added support for multi-value RDNs (e.g., cn=foo+l=bar)
	   - new method: #uri
	 * Commented out the spammy debug from the schema-parsing functions
	 * Treequel::Directory
	   - Renamed #basedn to #base_dn
	   - Added #base method for creating a Branch that wraps the base DN
	   - Delegate Branch-ish methods through the new #base branch.
	   - New method #uri
	   - Refactored search methods to use search_ext2 for efficiency
	 * Treequel::Branchset
	   - refactored to explicitly use a Branch
	   - made it Enumerable and refactored #all out as an alias for #entries
	   - added a convenience method for creating a BranchCollection from the
	Branchset's results
	 * Treequel::BranchCollection
	   - made it Enumerable through each branchset's #each; refactored #all
	as an alias for #entries
	 * Treequel::Constants
	   - Added an inverse mapping for SCOPE.
	   - Disambiguated the 'ESCAPED' pattern for DNs from the one for
	attribute values.
	 * Updated the manual
	[e434f63779e5]

2009-07-08  Michael Granger  <ged@FaerieMUD.org>

	* bin/treequel, experiments/dn.abnf, experiments/ohm.rb,
	lib/treequel/branch.rb, lib/treequel/constants.rb,
	lib/treequel/directory.rb, spec/treequel/directory_spec.rb:
	* A bit more hacking on the OHM experiment.
	 * Treequel::Branch
	   - Made attribute values in #must_attributes_hash empty strings to
	distinguish them from those created by #may_attributes_hash.
	   - Added #valid_attributes_hash as a convenience method for a merged
	`must_attributes_hash` and `may_attributes_hash`.
	 * Made the collection class returned from Treequel::Directory#search
	settable via a hash parameter, with fallback to the class of the
	base argument if it supports `new_from_entry` or Treequel::Branch
	if not.
	 * Added RFC 4514 (Distinguished Names) productions to
	Treequel::Constants::Patterns
	 * Treequel shell:
	   - Changed the 'cd' command to 'cdn'
	   - Validate the RDN passed to 'cdn'
	   - Added a 'parent' command to allow changing up one RDN
	   - Added a 'log' command to allow setting of log level, default log
	level to 'WARN'
	[f2b47be064b6]

2009-07-03  Michael Granger  <ged@FaerieMUD.org>

	* docs/manual/src/index.page, lib/treequel/branch.rb,
	lib/treequel/branchset.rb, lib/treequel/directory.rb,
	lib/treequel/schema/objectclass.rb, spec/treequel/branch_spec.rb,
	spec/treequel/branchset_spec.rb, spec/treequel/directory_spec.rb:
	* Treequel::Branch
	   - Made entry-fetching not raise an exception, but just return nil
	instead.
	   - Added #must_attributes_hash and #may_attributes_hash
	   - Added a splat-array to #object_classes, #must_attribute_types,
	#must_oids, #may_attribute_types, #may_oids,
	 * Added a logged warning for the case-sensitivity bug
	 * Refactored the parameter-normalization stuff out of
	Treequel::Directory#search method for readability, and to
	simplify the argument signature of #search.
	[57360b9b8143]

2009-07-02  Michael Granger  <ged@FaerieMUD.org>

	* docs/manual/src/index.page, experiments/delegation_cost.rb,
	experiments/userservice.rb, lib/treequel/branch.rb,
	lib/treequel/branchset.rb, lib/treequel/directory.rb,
	lib/treequel/filter.rb, spec/treequel/branch_spec.rb,
	spec/treequel/branchset_spec.rb, spec/treequel/directory_spec.rb,
	spec/treequel/filter_spec.rb:
	* Adding experimental Arrow service that uses Treequel to return
	ou=People records.
	 * Made Branch#create create the underlying entry instead of a child to
	better match what #delete, #modify, etc. are doing.
	 * Treequel::Directory:
	   - Fixed the argument list passed to LDAP::Conn#search_ext2 to match
	what the actual code expects.
	   - Modified #create to create the entry underlying the branch passed in
	the first argument instead of an entry specified by RDN.
	 * Treequel::Filter:
	   - Factored out the tuple-parsing part of .parse_array_expression into
	a separate method.
	   - Added a fallback to tuple-style expressions to handle expressions
	like { :uidNumber => 1414 }
	 * Treequel::Branchset
	   - Made it Enumerable
	   - Added #limit
	 * More work on the manual
	[1c3bd5a2a4f0]

2009-06-30  Michael Granger  <ged@FaerieMUD.org>

	* experiments/ohm.rb, spec/treequel/filter_spec.rb:
	Removing the call to `Time.today` from the specs, as it requires the
	loading of 'time'.
	[1853efa345e2]

	* lib/treequel/branch.rb, lib/treequel/connection.rb,
	lib/treequel/directory.rb, spec/treequel/branch_spec.rb,
	spec/treequel/connection_spec.rb, spec/treequel/directory_spec.rb:
	* Added Treequel::Branch#to_ufn
	 * Removed Treequel::Connection class in favor of just handling the
	specific problems in the #search method.
	 * Changed Treequel::Directory#search to be implemented in terms of
	#search_ext2 instead of the deprecated #search2
	[e5a2a960c89d]

2009-06-29  Michael Granger  <ged@FaerieMUD.org>

	* experiments/ohm.rb, lib/treequel/filter.rb,
	spec/treequel/filter_spec.rb:
	* Adding the beginnings of an experimental object-mapping (tree-
	based ORM analogue) for LDAP entries.
	 * Added handling for > and < Sequel expressions
	[9759280f111a]

2009-06-27  Michael Granger  <ged@FaerieMUD.org>

	* lib/treequel/utils.rb:
	Updated HTML logger formatter to the latest.
	[bc236240ca46]

2009-06-25  Michael Granger  <ged@FaerieMUD.org>

	* docs/manual/src/index.page, lib/treequel/branch.rb,
	spec/treequel/branch_spec.rb:
	* Renamed Treequel::Branch#modify to #merge
	 * More manual work.
	[35d0872f8b7f]

2009-06-24  Michael Granger  <ged@FaerieMUD.org>

	* docs/manual/src/index.page:
	Fixed some LAIKA references in the manual.
	[30445a043298]

2009-06-23  Michael Granger  <ged@FaerieMUD.org>

	* docs/Treequel Manual Diagrams.graffle,
	docs/manual/layouts/intro.page,
	docs/manual/resources/css/manual.css, docs/manual/src/index.page,
	lib/treequel.rb, lib/treequel/constants.rb,
	lib/treequel/directory.rb, lib/treequel/mixins.rb,
	spec/treequel/directory_spec.rb, spec/treequel_spec.rb:
	* Fixed docs on the binding arguments for
	Treequel::Directory#initialize.
	 * Fixed some typos.
	 * Stopdoc'ed the sub-modules under Treequel::Constants.
	 * Made Treequel.directory more flexible.
	 * Added a tentative logo to the diagrams.
	 * Updated the manual CSS and templates from Redleaf's.
	 * Manual work.
	 * Made the initial argument to Treequel::Directory#bind accept an
	object that duck-types as a Branch.
	[6cc39e6befdb]

	* lib/treequel/connection.rb, lib/treequel/directory.rb,
	lib/treequel/mixins.rb, spec/treequel/connection_spec.rb:
	* Added delegation to the connection wrapper.
	 * Fixed a bug in the Treequel::Delegation code-generation when it
	generates a delegated assignment method (#foo=).
	[3a204e54603e]

2009-06-22  Michael Granger  <ged@FaerieMUD.org>

	* docs/manual/layouts/default.page, docs/manual/src/index.page,
	lib/treequel.rb, lib/treequel/branch.rb,
	lib/treequel/branchcollection.rb, lib/treequel/branchset.rb,
	lib/treequel/connection.rb, lib/treequel/constants.rb,
	lib/treequel/directory.rb, lib/treequel/exceptions.rb,
	lib/treequel/filter.rb, lib/treequel/schema.rb,
	lib/treequel/schema/attributetype.rb,
	lib/treequel/schema/ldapsyntax.rb,
	lib/treequel/schema/matchingrule.rb,
	lib/treequel/schema/matchingruleuse.rb,
	lib/treequel/schema/objectclass.rb,
	spec/treequel/connection_spec.rb, spec/treequel/directory_spec.rb,
	spec/treequel/filter_spec.rb:
	* Fixed RDoc headers.
	 * Started work on a connection-abstraction that handles referrals,
	exception-normalization, and reconnection.
	 * Merged filter constants into the Constants module's namespace and
	factored out some duplication and inconsistency.
	 * Some manual work.
	 * Fixed a buggy substring filter spec that was uncovered by the
	constants refactoring.
	[6defed90cfcc]

2009-06-18  Michael Granger  <ged@FaerieMUD.org>

	* README, Rakefile, docs/Treequel Manual Diagrams.graffle,
	lib/treequel.rb, lib/treequel/schema.rb, project.yml,
	spec/treequel/schema_spec.rb:
	* Updated the build system.
	 * Untaint all schema names before trying to turn them into Symbols so
	it works under $SAFE = 1.
	 * Fixed some documentation, updated the description with something
	less-vague.
	[cdbb80f015b6]

	* Rakefile, bin/treequel, lib/treequel.rb, lib/treequel/branch.rb,
	lib/treequel/branchcollection.rb, lib/treequel/branchset.rb,
	spec/lib/constants.rb, spec/treequel/branch_spec.rb,
	spec/treequel/branchcollection_spec.rb,
	spec/treequel/branchset_spec.rb, spec/treequel_spec.rb:
	* Adding BranchCollection class.
	 * Treequel::Branchset
	   - Added #base_dn method
	   - Added the base to the inspection text
	 * Made argument to Treequel.directory optional
	[6da5c8ac1752]

2009-06-17  Michael Granger  <ged@FaerieMUD.org>

	* Rakefile, bin/treeirb, bin/treequel, docs/Treequel Manual
	Diagrams.graffle, docs/manual/src/index.page, lib/treequel.rb,
	lib/treequel/branch.rb, spec/treequel_spec.rb:
	* Updated build system
	 * Fixed a bug in Treequel::Branch#to_ldif
	 * Modified Treequel.directory to also accept a options hash.
	 * A little work on the manual
	 * Started an OmniGraffle doc for manual diagrams
	[8713fc4b41a9]

2009-06-11  Michael Granger  <ged@FaerieMUD.org>

	* docs/manual/layouts/default.page, docs/manual/lib/api-filter.rb,
	docs/manual/lib/editorial-filter.rb, docs/manual/lib/examples-
	filter.rb, docs/manual/lib/links-filter.rb,
	docs/manual/resources/css/deveiate.css,
	docs/manual/resources/css/manual.css, docs/manual/src/index.page:
	Adding the beginnings of a manual.
	[d33d81ff8327]

	* bin/shelldapper, bin/treequel, lib/treequel/branch.rb,
	lib/treequel/directory.rb, spec/treequel/branch_spec.rb,
	spec/treequel/directory_spec.rb:
	* Treequel::Branch:
	   - New methods: #rdn=, #split_dn, #<=>
	   - Added Comparable interface
	   - Made the proxy method actually check the schema for valid attribute
	type OIDs instead of assuming every message wanted a sub-
	branch.
	 * Treequel::Directory:
	   - Implemented #move
	   - Fixed non-functional #children.
	   - Same fix for #method_missing as in Branch.
	 * Renamed 'shelldapper' to 'treequel' to reflect a planned change in
	direction (i.e., closer) to Sequel's 'sequel' shell.
	[99d1553532f1]

	* bin/shelldapper, lib/treequel.rb, lib/treequel/directory.rb,
	spec/lib/constants.rb, spec/treequel/directory_spec.rb:
	* Fetch the default baseDN from the directory's root DSE instead of
	just using the empty string.
	 * Giving up on rbreadline -- too buggy and slow.
	 * More work on the shell.
	[3cf7a6589f40]

2009-06-09  Michael Granger  <ged@FaerieMUD.org>

	* bin/shelldapper, lib/treequel/branch.rb, lib/treequel/directory.rb,
	lib/treequel/utils.rb, spec/treequel/branch_spec.rb,
	spec/treequel/schema/matchingrule_spec.rb:
	* Added Branch#to_ldif
	 * Aliased Directory#dn to Directory#base
	 * Fleshed out the shelldapper proof-of-concept.
	 * Un-pendinged a Schema::MatchingRule spec that should have been
	passing, and made it pass.
	[decd99bd99e9]

2009-06-08  Michael Granger  <ged@FaerieMUD.org>

	* lib/treequel/branch.rb, lib/treequel/branchset.rb,
	lib/treequel/constants.rb, lib/treequel/directory.rb,
	spec/lib/constants.rb, spec/treequel/branch_spec.rb,
	spec/treequel/branchset_spec.rb, spec/treequel/directory_spec.rb:
	* Added datatype conversions for some of the default syntaxes to
	Directory.
	 * Made Branch#[] fetch values through its directory's datatype
	conversion method.
	[b27a2eb78d02]

2009-06-04  Michael Granger  <ged@FaerieMUD.org>

	* experiments/syntax-spike.rb, lib/treequel/branch.rb,
	lib/treequel/directory.rb, spec/lib/constants.rb,
	spec/treequel/branch_spec.rb, spec/treequel/directory_spec.rb:
	* Treequel::Branch
	   - Removed the #move method, as the requisite Directory#move method is
	not yet implemented.
	   - Made #copy a bit more flexible.
	[4c2477eb2a68]

2009-06-02  Michael Granger  <ged@FaerieMUD.org>

	* lib/treequel/constants.rb, lib/treequel/filter.rb,
	lib/treequel/schema/attributetype.rb,
	lib/treequel/schema/ldapsyntax.rb,
	spec/treequel/schema/attributetype_spec.rb:
	* Finished hooking up LDAPSyntax to AttributeType.
	 * Fixed malformed UTF<n> patterns.
	[b02d86bf9162]

2009-06-01  Michael Granger  <ged@FaerieMUD.org>

	* lib/treequel/constants.rb, lib/treequel/schema.rb,
	lib/treequel/schema/ldapsyntax.rb,
	lib/treequel/schema/matchingrule.rb,
	lib/treequel/schema/matchingruleuse.rb,
	spec/treequel/schema/ldapsyntax_spec.rb,
	spec/treequel/schema/matchingruleuse_spec.rb,
	spec/treequel/schema_spec.rb:
	* Finished implementation of matchingRuleUses and ldapSyntaxes.
	[7617a4b44fd9]

	* lib/treequel/schema.rb, lib/treequel/schema/attributetype.rb,
	lib/treequel/schema/ldapsyntax.rb,
	lib/treequel/schema/matchingrule.rb,
	spec/treequel/schema/matchingrule_spec.rb, spec/treequel_spec.rb:
	* Checkpoint commit of Treequel::Schema::LDAPSyntax class.
	[99fd606993ac]

2009-05-29  Michael Granger  <ged@FaerieMUD.org>

	* lib/treequel/constants.rb, lib/treequel/schema.rb,
	lib/treequel/schema/attributetype.rb,
	lib/treequel/schema/matchingrule.rb,
	spec/treequel/schema/attributetype_spec.rb,
	spec/treequel/schema/matchingrule_spec.rb,
	spec/treequel/schema/objectclass_spec.rb,
	spec/treequel/schema_spec.rb:
	* Adding Treequel::Schema::MatchingRule.
	 * Added some missing tests for Treequel::Schema class methods.
	[3dd18fa1c7fc]

	* lib/treequel/branch.rb, lib/treequel/directory.rb,
	spec/treequel/branch_spec.rb, spec/treequel/directory_spec.rb,
	spec/treequel/filter_spec.rb:
	* Treequel::Branch -- Changed the 'value' and 'attribute' attributes
	to 'rdn_value' and 'rdn_attribute' for clarification.
	 * Treequel::Directory#copy now automatically makes the necessary
	adjustments to the new record's RDN attribute and value.
	[cb93500e5d98]

	* lib/treequel/directory.rb, lib/treequel/exceptions.rb,
	lib/treequel/filter.rb, lib/treequel/schema.rb,
	spec/treequel/filter_spec.rb:
	* Added custom #inspect methods for Schema and Directory.
	 * Renamed Treequel::Filter::ExpressionError to
	Treequel::ExpressionError and moved it into
	lib/treequel/exceptions.rb.
	 * Added the morning's work on Sequel expression-parsing. Symbol#like
	now interpreted as either a wildcarded 'equal' or an 'approx'
	filter, depending on whether the value has at least one asterisk.
	[fb415faaeddb]

2009-05-23  Michael Granger  <ged@FaerieMUD.org>

	* Rakefile, lib/treequel/branch.rb, lib/treequel/directory.rb,
	project.yml, spec/treequel/directory_spec.rb:
	* Updated build system
	 * Made Treequel::Directory#modify normalize the hash of attributes
	before using it.
	 * Moved the dependency on 'ldap' to a requirement since there's no gem
	for 'ldap'.
	[aaef0c5c4703]

2009-05-20  Michael Granger  <ged@FaerieMUD.org>

	* lib/treequel/branch.rb, lib/treequel/directory.rb,
	lib/treequel/filter.rb, spec/lib/constants.rb,
	spec/treequel/branch_spec.rb, spec/treequel/directory_spec.rb:
	* Treequel::Branch
	  - Implemented #parent and #children
	  - Implemented #copy
	  - Implemented #modify
	[3132d19804a1]

2009-05-19  Michael Granger  <ged@FaerieMUD.org>

	* lib/treequel/schema/objectclass.rb:
	Include the superior class's name in
	Treequel::Schema::ObjectClass#inspect output.
	[e43f57f0f04c]

	* lib/treequel/branch.rb, lib/treequel/constants.rb,
	lib/treequel/directory.rb, spec/treequel/branch_spec.rb,
	spec/treequel/directory_spec.rb:
	* Treequel::Branch
	   - Implemented #delete and #create
	[3ebeec1eacf6]

2009-05-18  Michael Granger  <ged@FaerieMUD.org>

	* lib/treequel/branch.rb, lib/treequel/directory.rb,
	spec/treequel/branch_spec.rb, spec/treequel/directory_spec.rb:
	* Finished up Treequel::Branch#[]=
	[c615693a11e0]

2009-05-18  Mahlon E. Smith  <mahlon@martini.nu>

	* lib/treequel.rb, lib/treequel/constants.rb,
	lib/treequel/directory.rb, spec/treequel/directory_spec.rb,
	spec/treequel_spec.rb:
	* If a user/pass is supplied via the directory connect URI, bind
	immediately.
	 * Small whitespace cleanup(s)
	 * Ruby 1.8.7 has an URI::LDAPS (where ruby 1.8.6 does not), so add it
	conditionally.
	 * Don't attempt to connect via TLS if using the ldaps:// protocol.
	[72cd36c693ca]

2009-05-16  Michael Granger  <ged@FaerieMUD.org>

	* lib/treequel/branch.rb, lib/treequel/constants.rb,
	lib/treequel/schema/objectclass.rb, spec/treequel/branch_spec.rb,
	spec/treequel/schema/objectclass_spec.rb:
	* Treequel::Branch
	   - Remove #[] and #[]= delegators to the underlying entry in
	preparation for real accessors.
	   - Added attributeType and objectClass introspection
	   - Cache values fetched through #[] in preparation for datatype-
	conversion
	 * Added Treequel::Schema::ObjectClass#may
	 * Changed the quantifier for QDSTRINGS to zero-or-more as a workaround
	for malformed DESC attributes in the wild (namely the 'retcode'
	overlay in OpenLDAP)
	[a9bcbecb60f3]

2009-05-15  Michael Granger  <ged@FaerieMUD.org>

	* lib/treequel/branch.rb, lib/treequel/directory.rb,
	lib/treequel/schema.rb, lib/treequel/schema/attributetype.rb,
	lib/treequel/schema/objectclass.rb, spec/lib/constants.rb,
	spec/treequel/branch_spec.rb, spec/treequel/directory_spec.rb,
	spec/treequel/schema/attributetype_spec.rb,
	spec/treequel/schema/objectclass_spec.rb,
	spec/treequel/schema_spec.rb:
	* Treequel::Branch:
	   - Raise an exception if the entry associated with a Branch can't be
	fetched.
	   - Added the attribute-fetching operator (#[])
	 * Finished the implementation of Treequel::Schema::AttributeType.
	 * Added Treequel::Schema::ObjectClass#inspect
	 * Treequel::Schema component objects now have a reference to their
	schema so they can look up associated OIDs.
	 * Un-camelCased the schema component attributes
	 * Cache the Treequel::Directory's #schema instead of re-fetching it
	every time.
	[72ccdbdccd8d]

2009-05-14  Michael Granger  <ged@FaerieMUD.org>

	* lib/treequel/constants.rb, lib/treequel/mixins.rb,
	lib/treequel/schema.rb, lib/treequel/schema/attributetype.rb,
	lib/treequel/schema/objectclass.rb, spec/treequel/mixins_spec.rb,
	spec/treequel/schema/attributetype_spec.rb:
	* Finished the initial implementation of the
	Sequel::Schema::AttributeType class.
	 * Added a Treequel::AttributeDeclarations mixin for various kind of
	attribute declaration functions. This just contains the
	`predicate_attr` function for now.
	 * Factored the schema-part normalization methods across from
	Treequel::Schema::ObjectClass into Treequel::Schema so
	Treequel::Schema::AttributeType can use 'em too.
	[34bce6d3ec1a]

2009-05-13  Michael Granger  <ged@FaerieMUD.org>

	* lib/treequel/constants.rb, lib/treequel/directory.rb,
	lib/treequel/schema.rb, lib/treequel/schema/objectclass.rb,
	spec/treequel/directory_spec.rb, spec/treequel/schema_spec.rb:
	* Replaced the plain Treequel::Directory#schema method with the one
	that returns a new Treequel::Schema parsed from the directory's
	LDAP::Schema.
	 * Finished the objectClass portion of Treequel::Schema.
	 * Started work on schema attributeTypes.
	[3a222b303870]

	* lib/treequel/branch.rb, lib/treequel/branchset.rb,
	spec/lib/constants.rb, spec/treequel/branch_spec.rb,
	spec/treequel/branchset_spec.rb, spec/treequel/directory_spec.rb,
	spec/treequel/schema/objectclass_spec.rb:
	* Renamed Treequel::Branch#attr_pair to #rdn.
	[4946985217e9]

2009-05-12  Michael Granger  <ged@FaerieMUD.org>

	* lib/treequel/schema/objectclass.rb,
	spec/treequel/schema/objectclass_spec.rb:
	* Unified must/may oids into @must_oids and @may_oids to distinguish
	between them and the later Attribute objects that will be
	constructed from them.
	 * Added #obsolete? predicate method for the OBSOLETE attribute.
	[da533735fb9f]

2009-05-11  Michael Granger  <ged@FaerieMUD.org>

	* lib/treequel.rb, lib/treequel/schema/objectclass.rb,
	spec/treequel/schema/objectclass_spec.rb:
	* Added name, desc, kind, must, and may attribute normalization to
	Treequel::Schema::ObjectClass.
	[44a3834ff324]

	* lib/treequel.rb, lib/treequel/constants.rb,
	lib/treequel/exceptions.rb, lib/treequel/schema.rb,
	lib/treequel/schema/objectclass.rb, spec/data/objectClasses.yml,
	spec/data/schema.yml, spec/treequel/schema/objectclass_spec.rb,
	spec/treequel/schema_spec.rb:
	Checkpoint commit:
	 * More work on schema-parsing (objectClasses)
	 * Added some exception classes
	 * Removed accidentally-committed LAIKA objectClasses from the test
	schema data.
	[1d9b831d1579]

	* .irbrc, lib/treequel/constants.rb, lib/treequel/schema.rb,
	spec/treequel/schema_spec.rb:
	Checkpoint commit:
	 * Added some convenience stuff for testing patterns to .irbrc.
	 * Finished the objectClass pattern; no tests yet.
	[9a1ba6888856]

2009-05-08  Michael Granger  <ged@FaerieMUD.org>

	* .irbrc, lib/treequel/constants.rb:
	More work on parsing objectClasses.
	[fc25616368b8]

2009-05-07  Michael Granger  <ged@FaerieMUD.org>

	* lib/treequel/constants.rb, lib/treequel/schema.rb,
	spec/data/objectClasses.yml, spec/lib/helpers.rb,
	spec/treequel/schema_spec.rb:
	Checkpoint commit -- converting schema regexps to match the BNF in
	RFC 4512 instead of the one from 2252.
	[2378ca43e383]

2009-04-29  Michael Granger  <ged@FaerieMUD.org>

	* lib/treequel/constants.rb, spec/lib/helpers.rb:
	* Added more RFC2252 regexp patterns to constants.rb.
	 * Upgraded spec helpers to use the webkit RSpec formatter if it's
	available.
	[feedf3cfda8b]

2009-04-24  Michael Granger  <ged@FaerieMUD.org>

	* lib/treequel/branchset.rb, lib/treequel/constants.rb,
	lib/treequel/directory.rb, lib/treequel/schema.rb,
	spec/treequel/branchset_spec.rb, spec/treequel/directory_spec.rb,
	spec/treequel/schema_spec.rb:
	* Starting work on schema support.
	 * Fixed calls to search2 caused by misdocumented defaults in Ruby-
	LDAP.
	[f2fef4dea785]

2009-04-22  Michael Granger  <ged@FaerieMUD.org>

	* lib/treequel/filter.rb, spec/treequel/filter_spec.rb:
	* Fixed .filter( :attribute => value )
	 * Added support for .filter( :attribute => Range )
	[fa68642a4c6b]

	* .irbrc, lib/treequel.rb, lib/treequel/branchset.rb,
	lib/treequel/directory.rb, lib/treequel/filter.rb,
	lib/treequel/sequel_integration.rb, spec/treequel/branchset_spec.rb,
	spec/treequel/directory_spec.rb, spec/treequel/filter_spec.rb:
	* Started filter support for Sequel expressions
	 * Branchset
	   - Completed implementation for #order
	   - Renamed #no_timeout to #without_timeout
	 * Set up the connection in Treequel::Directory to be LDAPv3
	[d009a339d2cd]

2009-04-21  Michael Granger  <ged@FaerieMUD.org>

	* LICENSE, README, lib/treequel/branch.rb, lib/treequel/branchset.rb,
	lib/treequel/constants.rb, lib/treequel/filter.rb,
	spec/treequel/branch_spec.rb, spec/treequel/branchset_spec.rb,
	spec/treequel/filter_spec.rb:
	More filter work.
	[cb0752ae5ce9]

2009-04-20  Michael Granger  <ged@FaerieMUD.org>

	* lib/treequel/constants.rb, lib/treequel/filter.rb,
	spec/treequel/filter_spec.rb:
	Finished up initial filter work.
	[53fef8079a4e]

2009-04-18  Michael Granger  <ged@FaerieMUD.org>

	* lib/treequel/constants.rb, lib/treequel/filter.rb:
	* Committing yesterday's work on substring filters before I fall
	asleep.
	[621dbbe99418]

2009-04-16  Michael Granger  <ged@FaerieMUD.org>

	* experiments/filter-syntax-spike.rb, lib/treequel/filter.rb,
	spec/treequel/filter_spec.rb:
	* Started work on substring item filter syntax and class.
	 * Added support for string literal clauses in a logical filter
	[b71338a3b66f]

	* lib/treequel/branchset.rb, lib/treequel/filter.rb,
	spec/treequel/branchset_spec.rb, spec/treequel/filter_spec.rb:
	Checkpoint of more filter work.
	[27d7a681eb00]

2009-04-15  Michael Granger  <ged@FaerieMUD.org>

	* Rakefile, lib/treequel/filter.rb, project.yml,
	spec/treequel/branchset_spec.rb, spec/treequel/filter_spec.rb:
	Committing this morning's work.
	[53cf56feaad8]

2009-04-13  Michael Granger  <ged@FaerieMUD.org>

	* experiments/filter-syntax-spike.rb, lib/treequel/branchset.rb,
	lib/treequel/branchset/clauses.rb, lib/treequel/filter.rb,
	spec/treequel/branchset/clauses_spec.rb,
	spec/treequel/branchset_spec.rb, spec/treequel/filter_spec.rb:
	Checkpoint commit of this morning's work.
	[ba1440c71f01]

2009-04-10  Michael Granger  <ged@FaerieMUD.org>

	* bin/shelldapper, experiments/filter-syntax-spike.rb,
	lib/treequel.rb, lib/treequel/branch.rb, lib/treequel/branchset.rb,
	lib/treequel/branchset/clauses.rb, lib/treequel/directory.rb,
	spec/treequel/branchset/clauses_spec.rb,
	spec/treequel/branchset_spec.rb, spec/treequel/directory_spec.rb:
	Checkpoint commit.
	[e8fd5884c22f]

2009-04-09  Michael Granger  <ged@FaerieMUD.org>

	* experiments/syntax-spike.rb, lib/treequel/branch.rb,
	lib/treequel/branchset.rb, lib/treequel/directory.rb,
	spec/treequel/branch_spec.rb, spec/treequel/branchset_spec.rb:
	Checkpoint commit.
	[6924adc0feb2]

2009-03-30  Michael Granger  <ged@FaerieMUD.org>

	* experiments/laika.rb, experiments/syntax-spike.rb,
	lib/treequel/branch.rb, lib/treequel/branchset.rb,
	spec/treequel/branch_spec.rb, spec/treequel/branchset_spec.rb:
	Checkpoint commit.
	[0c1438a9105a]

2009-03-18  Michael Granger  <ged@FaerieMUD.org>

	* lib/treequel/branch.rb, spec/treequel/branch_spec.rb,
	spec/treequel_spec.rb:
	* Finished Treequel::Branch.new_from_dn
	 * Finished pending specs.
	[5f3f334406cf]

2009-03-10  Michael Granger  <ged@FaerieMUD.org>

	* experiments/inspect_entry.rb, lib/treequel.rb,
	lib/treequel/branch.rb, lib/treequel/directory.rb,
	spec/treequel/branch_spec.rb, spec/treequel/directory_spec.rb:
	* Checkpoint of the morning's work.
	[83d533b2987d]

	* .irbrc, lib/treequel.rb, lib/treequel/branch.rb,
	lib/treequel/directory.rb, spec/lib/constants.rb,
	spec/treequel/branch_spec.rb, spec/treequel/directory_spec.rb,
	spec/treequel_spec.rb:
	* Snapshot of today's work.
	[27b230b291a3]

2009-03-09  Michael Granger  <ged@FaerieMUD.org>

	* experiments/delegation_cost.rb, lib/treequel.rb,
	lib/treequel/branch.rb, lib/treequel/constants.rb,
	lib/treequel/directory.rb, lib/treequel/mixins.rb,
	spec/lib/constants.rb, spec/treequel/branch_spec.rb,
	spec/treequel/directory_spec.rb, spec/treequel/mixins_spec.rb:
	* Committing the morning's work.
	[f73835204ddc]

	* Rakefile, experiments/ldapexpr.rb, experiments/syntax-spike.rb,
	experiments/utils.rb, lib/treequel.rb, lib/treequel/directory.rb,
	lib/treequel/mixins.rb, lib/treequel/utils.rb,
	spec/lib/constants.rb, spec/lib/helpers.rb,
	spec/treequel/directory_spec.rb, spec/treequel/mixins_spec.rb,
	spec/treequel/utils_spec.rb, spec/treequel_spec.rb:
	* Updated build system
	 * Renamed the spike to `syntax-spike.rb` and fleshed it out a bunch
	 * Started on the actual implementation
	[7709b9520686]

2009-03-07  Michael Granger  <ged@FaerieMUD.org>

	* LICENSE, README, Rakefile, experiments/ldapexpr.rb, lib/treequel.rb,
	project.yml:
	* Started an initial spike and installed build system.
	[d8e78b6b4088]

2008-12-05  Michael Granger  <ged@FaerieMUD.org>

	* Creating repo
	[b21f833298d6]

