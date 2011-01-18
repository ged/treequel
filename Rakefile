#!/usr/bin/env rake

require 'hoe'

Hoe.plugin :mercurial
Hoe.plugin :yard
Hoe.plugin :signing
Hoe.plugin :manualgen



Hoe.plugins.delete :rubyforge

hoespec = Hoe.spec 'treequel' do
	self.name = 'treequel'
	self.readme_file = 'README.md'

	self.developer 'Michael Granger', 'ged@FaerieMUD.org'
	self.developer 'Mahlon E. Smith', 'mahlon@martini.nu'

	self.extra_deps.push *{
		'ruby-ldap' => '~> 0.9.11',
		'diff-lcs'  => '~> 1.1.2',
	}
	self.extra_dev_deps.push *{
		'rspec'         => '~> 2.4.0',
		'ruby-termios'  => '~> 0.9.6',
		'ruby-terminfo' => '~> 0.1.1',
		'columnize'     => '~> 0.3.1',
		'sysexits'      => '~> 1.0.2',
	}

	self.spec_extras[:licenses] = ["BSD"]
	self.spec_extras[:post_install_message] = [
		"If you want to use the included 'treequel' LDAP shell, you'll need to install",
		"the following libraries as well:",
		'',
		"    - termios",
		"    - ruby-terminfo",
		"    - columnize",
		'',
		"You can install those automatically if you use the --development flag when",
		"installing Treequel."
	  ].join( "\n" )
	self.spec_extras[:signing_key] = '/Volumes/Keys/ged-private_gem_key.pem'

	self.require_ruby_version( '>=1.8.7' )

	self.hg_sign_tags = true if self.respond_to?( :hg_sign_tags= )
	self.manual_source_dir = 'src' if self.respond_to?( :manual_source_dir= )
	self.yard_opts = [ '--use-cache', '--protected', '--verbose' ] if
		self.respond_to?( :yard_opts= )

	self.rdoc_locations << "deveiate:/usr/local/www/public/code/#{remote_rdoc_dir}"
end

ENV['VERSION'] ||= hoespec.spec.version.to_s

begin
	include Hoe::MercurialHelpers

	task 'hg:precheckin' => :spec

	### Task: prerelease
	desc "Append the package build number to package versions"
	task :pre do
		rev = get_numeric_rev()
		trace "Current rev is: %p" % [ rev ]
		hoespec.spec.version.version << "pre#{rev}"
		Rake::Task[:gem].clear

		Gem::PackageTask.new( hoespec.spec ) do |pkg|
			pkg.need_zip = true
			pkg.need_tar = true
		end
	end

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

rescue NameError => err
	task :no_hg_helpers do
		fail "Couldn't define the :pre task: %s: %s" % [ err.class.name, err.message ]
	end

	task :pre => :no_hg_helpers
	task 'ChangeLog' => :no_hg_helpers

end

