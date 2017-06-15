# -*- encoding: utf-8 -*-
# stub: treequel 1.12.0.pre20170614182118 ruby lib

Gem::Specification.new do |s|
  s.name = "treequel".freeze
  s.version = "1.12.0.pre20170614182118"

  s.required_rubygems_version = Gem::Requirement.new("> 1.3.1".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Michael Granger".freeze, "Mahlon E. Smith".freeze]
  s.cert_chain = ["certs/ged.pem".freeze]
  s.date = "2017-06-15"
  s.description = "Treequel is an LDAP toolkit for Ruby. It is intended to allow quick, easy\naccess to LDAP directories in a manner consistent with LDAP's hierarchical,\nfree-form nature.\n\nIt's inspired by and modeled after [Sequel][sequel], a\nkick-ass database library.\n\nFor more information on how to use it, check out the [manual](manual/index_md.html).".freeze
  s.email = ["ged@FaerieMUD.org".freeze, "mahlon@martini.nu".freeze]
  s.extra_rdoc_files = ["History.md".freeze, "Manifest.txt".freeze, "README.md".freeze, "History.md".freeze, "README.md".freeze]
  s.files = ["ChangeLog".freeze, "History.md".freeze, "Manifest.txt".freeze, "README.md".freeze, "Rakefile".freeze, "examples/company-directory.rb".freeze, "examples/ldap-rack-auth.rb".freeze, "examples/ldap_state.rb".freeze, "examples/webroot/css/master.css".freeze, "lib/treequel.rb".freeze, "lib/treequel/behavior/control.rb".freeze, "lib/treequel/branch.rb".freeze, "lib/treequel/branchcollection.rb".freeze, "lib/treequel/branchset.rb".freeze, "lib/treequel/constants.rb".freeze, "lib/treequel/control.rb".freeze, "lib/treequel/controls/contentsync.rb".freeze, "lib/treequel/controls/pagedresults.rb".freeze, "lib/treequel/controls/sortedresults.rb".freeze, "lib/treequel/directory.rb".freeze, "lib/treequel/exceptions.rb".freeze, "lib/treequel/filter.rb".freeze, "lib/treequel/mixins.rb".freeze, "lib/treequel/model.rb".freeze, "lib/treequel/model/errors.rb".freeze, "lib/treequel/model/objectclass.rb".freeze, "lib/treequel/model/schemavalidations.rb".freeze, "lib/treequel/monkeypatches.rb".freeze, "lib/treequel/schema.rb".freeze, "lib/treequel/schema/attributetype.rb".freeze, "lib/treequel/schema/ldapsyntax.rb".freeze, "lib/treequel/schema/matchingrule.rb".freeze, "lib/treequel/schema/matchingruleuse.rb".freeze, "lib/treequel/schema/objectclass.rb".freeze, "lib/treequel/schema/table.rb".freeze, "lib/treequel/sequel_integration.rb".freeze, "lib/treequel/utils.rb".freeze, "misc/ruby-ldap-controlsfix.patch".freeze, "spec/data/ad_schema.yml".freeze, "spec/data/objectClasses.yml".freeze, "spec/data/opends.yml".freeze, "spec/data/schema.yml".freeze, "spec/data/ticket11.yml".freeze, "spec/spec_constants.rb".freeze, "spec/spec_helpers.rb".freeze, "spec/treequel/branch_spec.rb".freeze, "spec/treequel/branchcollection_spec.rb".freeze, "spec/treequel/branchset_spec.rb".freeze, "spec/treequel/control_spec.rb".freeze, "spec/treequel/controls/contentsync_spec.rb".freeze, "spec/treequel/controls/pagedresults_spec.rb".freeze, "spec/treequel/controls/sortedresults_spec.rb".freeze, "spec/treequel/directory_spec.rb".freeze, "spec/treequel/filter_spec.rb".freeze, "spec/treequel/mixins_spec.rb".freeze, "spec/treequel/model/errors_spec.rb".freeze, "spec/treequel/model/objectclass_spec.rb".freeze, "spec/treequel/model/schemavalidations_spec.rb".freeze, "spec/treequel/model_spec.rb".freeze, "spec/treequel/monkeypatches_spec.rb".freeze, "spec/treequel/schema/attributetype_spec.rb".freeze, "spec/treequel/schema/ldapsyntax_spec.rb".freeze, "spec/treequel/schema/matchingrule_spec.rb".freeze, "spec/treequel/schema/matchingruleuse_spec.rb".freeze, "spec/treequel/schema/objectclass_spec.rb".freeze, "spec/treequel/schema/table_spec.rb".freeze, "spec/treequel/schema_spec.rb".freeze, "spec/treequel_spec.rb".freeze]
  s.homepage = "http://deveiate.org/projects/Treequel".freeze
  s.licenses = ["BSD-3-Clause".freeze]
  s.post_install_message = "------------------------------------------------------------------------\nNOTE: The Treequel command-line tools are no longer distributed \nwith the Treequel gem; to get the tools, install the 'treequel-shell' \ngem. Thanks!\n------------------------------------------------------------------------".freeze
  s.rdoc_options = ["--main".freeze, "README.md".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.2".freeze)
  s.rubygems_version = "2.6.12".freeze
  s.summary = "Treequel is an LDAP toolkit for Ruby".freeze

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<ruby-ldap>.freeze, [">= 0.9.19", "~> 0.9"])
      s.add_runtime_dependency(%q<loggability>.freeze, ["~> 0.4"])
      s.add_development_dependency(%q<hoe-mercurial>.freeze, ["~> 1.4"])
      s.add_development_dependency(%q<hoe-deveiate>.freeze, ["~> 0.9"])
      s.add_development_dependency(%q<hoe-highline>.freeze, ["~> 0.2"])
      s.add_development_dependency(%q<rspec>.freeze, ["~> 2.8"])
      s.add_development_dependency(%q<sequel>.freeze, [">= 3.38"])
      s.add_development_dependency(%q<rdoc>.freeze, ["~> 4.0"])
      s.add_development_dependency(%q<hoe>.freeze, ["~> 3.16"])
    else
      s.add_dependency(%q<ruby-ldap>.freeze, [">= 0.9.19", "~> 0.9"])
      s.add_dependency(%q<loggability>.freeze, ["~> 0.4"])
      s.add_dependency(%q<hoe-mercurial>.freeze, ["~> 1.4"])
      s.add_dependency(%q<hoe-deveiate>.freeze, ["~> 0.9"])
      s.add_dependency(%q<hoe-highline>.freeze, ["~> 0.2"])
      s.add_dependency(%q<rspec>.freeze, ["~> 2.8"])
      s.add_dependency(%q<sequel>.freeze, [">= 3.38"])
      s.add_dependency(%q<rdoc>.freeze, ["~> 4.0"])
      s.add_dependency(%q<hoe>.freeze, ["~> 3.16"])
    end
  else
    s.add_dependency(%q<ruby-ldap>.freeze, [">= 0.9.19", "~> 0.9"])
    s.add_dependency(%q<loggability>.freeze, ["~> 0.4"])
    s.add_dependency(%q<hoe-mercurial>.freeze, ["~> 1.4"])
    s.add_dependency(%q<hoe-deveiate>.freeze, ["~> 0.9"])
    s.add_dependency(%q<hoe-highline>.freeze, ["~> 0.2"])
    s.add_dependency(%q<rspec>.freeze, ["~> 2.8"])
    s.add_dependency(%q<sequel>.freeze, [">= 3.38"])
    s.add_dependency(%q<rdoc>.freeze, ["~> 4.0"])
    s.add_dependency(%q<hoe>.freeze, ["~> 3.16"])
  end
end
