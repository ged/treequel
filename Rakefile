#!/usr/bin/env rake

begin
	require 'hoe'
rescue LoadError
	abort "This Rakefile requires hoe (gem install hoe)"
end

require 'rake/clean'

GEMSPEC = 'treequel.gemspec'


Hoe.plugin :mercurial
Hoe.plugin :signing
Hoe.plugin :deveiate

Hoe.plugins.delete :rubyforge

hoespec = Hoe.spec 'treequel' do
	self.readme_file = 'README.md'
	self.history_file = 'History.md'
	self.extra_rdoc_files = FileList[ '*.rdoc', '*.md' ]
	self.license 'BSD-3-Clause'
	self.urls = {
		home:   'http://deveiate.org/projects/configurability',
		code:   'http://bitbucket.org/ged/configurability',
		docs:   'http://deveiate.org/code/configurability',
		github: 'http://github.com/ged/configurability',
	}

	self.developer 'Michael Granger', 'ged@FaerieMUD.org'
	self.developer 'Mahlon E. Smith', 'mahlon@martini.nu'

	if RUBY_PLATFORM == 'java'
		self.dependency 'jruby-ldap', '~> 0.0.1'
	else
		self.dependency 'ruby-ldap', ['~> 0.9', '>= 0.9.19']
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

	self.rdoc_locations << "deveiate:/usr/local/www/public/code/#{remote_rdoc_dir}"
end

ENV['VERSION'] ||= hoespec.spec.version.to_s

# Ensure the specs pass before checking in
task 'hg:precheckin' => [ 'ChangeLog', :gemspec, :check_history, :check_manifest, :spec ]

# Rebuild the ChangeLog immediately before release
task :prerelease => 'ChangeLog'
CLOBBER.include( 'ChangeLog' )

desc "Build a coverage report"
task :coverage do
	ENV["COVERAGE"] = 'yes'
	Rake::Task[:spec].invoke
end

# Use the fivefish formatter for docs generated from development checkout
if File.directory?( '.hg' )
	require 'rdoc/task'

	Rake::Task[ 'docs' ].clear
	RDoc::Task.new( 'docs' ) do |rdoc|
	    rdoc.main = "README.md"
		rdoc.markup = 'markdown'
	    rdoc.rdoc_files.include( "*.md", "ChangeLog", "lib/**/*.rb" )
	    rdoc.generator = :fivefish
		rdoc.title = 'Treequel'
	    rdoc.rdoc_dir = 'doc'
	end
end


task :gemspec => GEMSPEC
file GEMSPEC => [ __FILE__, 'Manifest.txt' ] do |task|
	spec = hoespec.spec
	spec.files.delete( '.gemtest' )
	spec.files.delete( 'LICENSE' )
	spec.signing_key = nil
	spec.version = "#{spec.version.bump}.0.pre#{Time.now.strftime("%Y%m%d%H%M%S")}"
	spec.cert_chain = [ 'certs/ged.pem' ]
	File.open( task.name, 'w' ) do |fh|
		fh.write( spec.to_ruby )
	end
end

task :default => :gemspec

