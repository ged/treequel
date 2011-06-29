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
	self.name = 'treequel'
	self.readme_file = 'README.md'
	self.history_file = 'History.md'

	self.developer 'Michael Granger', 'ged@FaerieMUD.org'
	self.developer 'Mahlon E. Smith', 'mahlon@martini.nu'

	if RUBY_PLATFORM == 'java'
		self.dependency 'jruby-ldap', '~> 0.0.1'
	else
		self.dependency 'ruby-ldap', '~> 0.9'
	end
	self.dependency 'diff-lcs', '~> 1.1'
	self.dependency 'rspec', ['>= 2.6.0', '< 3.0.0'], :developer
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
	self.spec_extras[:signing_key] = '/Volumes/Keys/ged-private_gem_key.pem'

	self.require_ruby_version( '>=1.8.7' )

	self.rspec_options += ['-cfd'] if self.respond_to?( :rspec_options= )
	self.hg_sign_tags = true if self.respond_to?( :hg_sign_tags= )
	self.manual_source_dir = 'src' if self.respond_to?( :manual_source_dir= )

	self.rdoc_locations << "deveiate:/usr/local/www/public/code/#{remote_rdoc_dir}"
end

ENV['VERSION'] ||= hoespec.spec.version.to_s

# Tests use RSpec
task :test => :spec

