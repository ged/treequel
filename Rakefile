#!/usr/bin/env rake

begin
	require 'hoe'
rescue LoadError
	abort "This Rakefile requires hoe (gem install hoe)"
end

require 'rake/clean'

Hoe.plugin :mercurial
Hoe.plugin :signing
Hoe.plugin :manualgen
Hoe.plugin :deveiate

Hoe.plugins.delete :rubyforge

hoespec = Hoe.spec 'treequel' do
	self.readme_file = 'README.rdoc'
	self.history_file = 'History.rdoc'
	self.extra_rdoc_files = Rake::FileList[ '*.rdoc' ]
	self.spec_extras[:rdoc_options] = ['-f', 'fivefish', '-t', 'Treequel']
	self.license 'BSD-3-Clause'

	self.need_tar = true
	self.need_zip = true

	self.developer 'Michael Granger', 'ged@FaerieMUD.org'
	self.developer 'Mahlon E. Smith', 'mahlon@martini.nu'

	if RUBY_PLATFORM == 'java'
		self.dependency 'jruby-ldap', '~> 0.0.1'
	else
		self.dependency 'ruby-ldap', '~> 0.9'
	end
	self.dependency 'loggability', '~> 0.4'

	self.dependency 'rspec', '~> 2.8', :developer   # FIXME needs updates
	self.dependency 'sequel', '>= 3.38', :developer # FIXME test with v4

	self.spec_extras[:post_install_message] = [
		'-' * 72,
		"NOTE: The Treequel command-line tools are no longer distributed ",
		"with the Treequel gem; to get the tools, install the 'treequel-shell' ",
		"gem. Thanks!",
		'-' * 72
	  ].join( "\n" )

	self.require_ruby_version( '>=2.2' )

	self.hg_sign_tags = true if self.respond_to?( :hg_sign_tags= )
	self.check_history_on_release = true if self.respond_to?( :check_history_on_release= )
	self.manual_source_dir = 'src' if self.respond_to?( :manual_source_dir= )

	self.rdoc_locations << "deveiate:/usr/local/www/public/code/#{remote_rdoc_dir}"
end

ENV['VERSION'] ||= hoespec.spec.version.to_s

# Ensure the specs pass before checking in
task 'hg:precheckin' => [ 'ChangeLog', :check_history, :check_manifest, :spec ]

# Rebuild the ChangeLog immediately before release
task :prerelease => 'ChangeLog'


desc "Build a coverage report"
task :coverage do
	ENV["COVERAGE"] = 'yes'
	Rake::Task[:spec].invoke
end

if Rake::Task.task_defined?( '.gemtest' )
	Rake::Task['.gemtest'].clear
	task '.gemtest' do
		$stderr.puts "Not including a .gemtest until I'm confident the test suite is idempotent."
	end
end


# Add admin app testing directories to the clobber list
CLOBBER.include( 'ChangeLog' )


