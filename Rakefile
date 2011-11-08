#!/usr/bin/env rake

begin
	require 'hoe'
rescue LoadError
	abort "This Rakefile requires hoe (gem install hoe)"
end

Hoe.plugin :mercurial
Hoe.plugin :signing
Hoe.plugin :manualgen

Hoe.plugins.delete :rubyforge

hoespec = Hoe.spec 'treequel' do
	self.readme_file = 'README.rdoc'
	self.history_file = 'History.rdoc'
	self.extra_rdoc_files = Rake::FileList[ '*.rdoc' ]

	self.need_tar = true
	self.need_zip = true

	self.developer 'Michael Granger', 'ged@FaerieMUD.org'
	self.developer 'Mahlon E. Smith', 'mahlon@martini.nu'

	if RUBY_PLATFORM == 'java'
		self.dependency 'jruby-ldap', '~> 0.0.1'
	else
		self.dependency 'ruby-ldap', '~> 0.9'
	end
	self.dependency 'diff-lcs', '~> 1.1'
	self.dependency 'rspec', '~> 2.7', :developer
	self.dependency 'ruby-termios', '~> 0.9', :developer
	self.dependency 'ruby-terminfo', '~> 0.1', :developer
	self.dependency 'columnize', '~> 0.3', :developer
	self.dependency 'sysexits', '~> 1.0', :developer
	self.dependency 'sequel', '~> 3.20', :developer

	self.spec_extras[:licenses] = ["BSD"]
	self.spec_extras[:post_install_message] = [
		"If you want to use the included 'treequel' LDAP shell, you'll need to install",
		"the following libraries as well:",
		'',
		"    - ruby-termios",
		"    - ruby-terminfo",
		"    - columnize",
		"    - sysexits",
		'',
		"You can install them automatically if you use the --development flag when",
		"installing Treequel."
	  ].join( "\n" )

	self.require_ruby_version( '>=1.8.7' )

	self.hg_sign_tags = true if self.respond_to?( :hg_sign_tags= )
	self.check_history_on_release = true if self.respond_to?( :check_history_on_release= )
	self.manual_source_dir = 'src' if self.respond_to?( :manual_source_dir= )

	self.rdoc_locations << "deveiate:/usr/local/www/public/code/#{remote_rdoc_dir}"
end

ENV['VERSION'] ||= hoespec.spec.version.to_s

# Ensure the specs pass before checking in
task 'hg:precheckin' => [ :check_history, :check_manifest, :spec ]

### Make the ChangeLog update if the repo has changed since it was last built
file '.hg/branch'
file 'ChangeLog' => '.hg/branch' do |task|
	$stderr.puts "Updating the changelog..."
	content = make_changelog()
	File.open( task.name, 'w', 0644 ) do |fh|
		fh.print( content )
	end
end

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


