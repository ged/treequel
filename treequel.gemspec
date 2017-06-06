# -*- encoding: utf-8 -*-
# stub: treequel 1.10.0.pre20150817081017 ruby lib

Gem::Specification.new do |s|
  s.name = "treequel"
  s.version = "1.10.0.pre20150817081017"

  s.required_rubygems_version = Gem::Requirement.new("> 1.3.1") if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib"]
  s.authors = ["Michael Granger", "Mahlon E. Smith"]
  s.date = "2015-08-17"
  s.description = "Treequel is an LDAP toolkit for Ruby. It is intended to allow quick, easy\naccess to LDAP directories in a manner consistent with LDAP's hierarchical,\nfree-form nature.\n\nIt's inspired by and modeled after {Sequel}[http://sequel.rubyforge.org/], a\nkick-ass database library."
  s.email = ["ged@FaerieMUD.org", "mahlon@martini.nu"]
  s.extra_rdoc_files = ["History.rdoc", "Manifest.txt", "README.rdoc", "History.rdoc", "README.rdoc"]
  s.files = ["ChangeLog", "History.rdoc", "LICENSE", "Manifest.txt", "README.rdoc", "Rakefile", "examples/company-directory.rb", "examples/ldap-rack-auth.rb", "examples/ldap_state.rb", "examples/webroot/css/master.css", "lib/treequel.rb", "lib/treequel/behavior/control.rb", "lib/treequel/branch.rb", "lib/treequel/branchcollection.rb", "lib/treequel/branchset.rb", "lib/treequel/constants.rb", "lib/treequel/control.rb", "lib/treequel/controls/contentsync.rb", "lib/treequel/controls/pagedresults.rb", "lib/treequel/controls/sortedresults.rb", "lib/treequel/directory.rb", "lib/treequel/exceptions.rb", "lib/treequel/filter.rb", "lib/treequel/mixins.rb", "lib/treequel/model.rb", "lib/treequel/model/errors.rb", "lib/treequel/model/objectclass.rb", "lib/treequel/model/schemavalidations.rb", "lib/treequel/monkeypatches.rb", "lib/treequel/schema.rb", "lib/treequel/schema/attributetype.rb", "lib/treequel/schema/ldapsyntax.rb", "lib/treequel/schema/matchingrule.rb", "lib/treequel/schema/matchingruleuse.rb", "lib/treequel/schema/objectclass.rb", "lib/treequel/schema/table.rb", "lib/treequel/sequel_integration.rb", "spec/data/ad_schema.yml", "spec/data/objectClasses.yml", "spec/data/opends.yml", "spec/data/schema.yml", "spec/data/ticket11.yml", "spec/lib/constants.rb", "spec/lib/helpers.rb", "spec/lib/matchers.rb", "spec/treequel/branch_spec.rb", "spec/treequel/branchcollection_spec.rb", "spec/treequel/branchset_spec.rb", "spec/treequel/control_spec.rb", "spec/treequel/controls/contentsync_spec.rb", "spec/treequel/controls/pagedresults_spec.rb", "spec/treequel/controls/sortedresults_spec.rb", "spec/treequel/directory_spec.rb", "spec/treequel/filter_spec.rb", "spec/treequel/mixins_spec.rb", "spec/treequel/model/errors_spec.rb", "spec/treequel/model/objectclass_spec.rb", "spec/treequel/model/schemavalidations_spec.rb", "spec/treequel/model_spec.rb", "spec/treequel/monkeypatches_spec.rb", "spec/treequel/schema/attributetype_spec.rb", "spec/treequel/schema/ldapsyntax_spec.rb", "spec/treequel/schema/matchingrule_spec.rb", "spec/treequel/schema/matchingruleuse_spec.rb", "spec/treequel/schema/objectclass_spec.rb", "spec/treequel/schema/table_spec.rb", "spec/treequel/schema_spec.rb", "spec/treequel_spec.rb"]
  s.homepage = "http://deveiate.org/projects/Treequel"
  s.licenses = ["BSD"]
  s.post_install_message = "------------------------------------------------------------------------\nNOTE: The Treequel command-line tools are no longer distributed \nwith the Treequel gem; to get the tools, install the 'treequel-shell' \ngem. Thanks!\n------------------------------------------------------------------------"
  s.rdoc_options = ["--main", "README.rdoc"]
  s.required_ruby_version = Gem::Requirement.new(">= 2.0.0")
  s.rubygems_version = "2.4.7"
  s.summary = "Treequel is an LDAP toolkit for Ruby"

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<ruby-ldap>, ["~> 0.9"])
      s.add_runtime_dependency(%q<loggability>, ["~> 0.4"])
      s.add_development_dependency(%q<hoe-mercurial>, ["~> 1.4"])
      s.add_development_dependency(%q<hoe-deveiate>, ["~> 0.7"])
      s.add_development_dependency(%q<hoe-highline>, ["~> 0.2"])
      s.add_development_dependency(%q<rdoc>, ["~> 4.0"])
      s.add_development_dependency(%q<rspec>, ["~> 3.3"])
      s.add_development_dependency(%q<sequel>, ["~> 4.25"])
      s.add_development_dependency(%q<hoe>, ["~> 3.13"])
    else
      s.add_dependency(%q<ruby-ldap>, ["~> 0.9"])
      s.add_dependency(%q<loggability>, ["~> 0.4"])
      s.add_dependency(%q<hoe-mercurial>, ["~> 1.4"])
      s.add_dependency(%q<hoe-deveiate>, ["~> 0.7"])
      s.add_dependency(%q<hoe-highline>, ["~> 0.2"])
      s.add_dependency(%q<rdoc>, ["~> 4.0"])
      s.add_dependency(%q<rspec>, ["~> 3.3"])
      s.add_dependency(%q<sequel>, ["~> 4.25"])
      s.add_dependency(%q<hoe>, ["~> 3.13"])
    end
  else
    s.add_dependency(%q<ruby-ldap>, ["~> 0.9"])
    s.add_dependency(%q<loggability>, ["~> 0.4"])
    s.add_dependency(%q<hoe-mercurial>, ["~> 1.4"])
    s.add_dependency(%q<hoe-deveiate>, ["~> 0.7"])
    s.add_dependency(%q<hoe-highline>, ["~> 0.2"])
    s.add_dependency(%q<rdoc>, ["~> 4.0"])
    s.add_dependency(%q<rspec>, ["~> 3.3"])
    s.add_dependency(%q<sequel>, ["~> 4.25"])
    s.add_dependency(%q<hoe>, ["~> 3.13"])
  end
end
