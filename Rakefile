#!/usr/bin/env rake

require 'hoe'

Hoe.plugin :mercurial
Hoe.plugin :signing
Hoe.plugin :yard
Hoe.plugin :manualgen

Hoe.plugins.delete :rubyforge

hoespec = Hoe.spec 'treequel' do
	self.name = 'treequel'
	self.readme_file = 'README.md'
	self.history_file = 'History.md'

	self.developer 'Michael Granger', 'ged@FaerieMUD.org'
	self.developer 'Mahlon E. Smith', 'mahlon@martini.nu'

	self.extra_deps.push *{
		'ruby-ldap' => '~> 0.9',
		'diff-lcs'  => '~> 1.1',
	}
	self.extra_dev_deps.push *{
		'rspec'         => '~> 2.4',
		'ruby-termios'  => '~> 0.9',
		'ruby-terminfo' => '~> 0.1',
		'columnize'     => '~> 0.3',
		'sysexits'      => '~> 1.0',
		'sequel'        => '~> 3.20',
	}

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

