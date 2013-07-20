
Gem::Specification.new do |s|

  s.name = 'rufus-verbs'

  s.version = File.read(
    File.expand_path('../lib/rufus/verbs/version.rb', __FILE__)
  ).match(/ VERSION *= *['"]([^'"]+)/)[1]
    # avoiding requiring version.rb...

  s.platform = Gem::Platform::RUBY
  s.authors = [ 'John Mettraux' ]
  s.email = [ 'jmettraux@gmail.com' ]
  s.homepage = 'http://github.com/jmettraux/rufus-verbs'
  s.rubyforge_project = 'rufus'
  s.summary = 'GET, POST, PUT, DELETE, with something around'

  s.description = %{
GET, POST, PUT, DELETE, with something around.

A HTTP client Ruby gem, with conditional GET, basic auth, and more.
  }.strip

  #s.required_ruby_version = '>= 1.8.6'

  #s.files = `git ls-files`.split("\n")
  s.files = Dir[
    'Rakefile',
    'lib/**/*.rb', 'spec/**/*.rb', 'test/**/*.rb',
    '*.gemspec', '*.txt', '*.rdoc', '*.md'
  ]

  s.add_runtime_dependency 'rufus-lru'

  s.add_development_dependency 'rake'
  s.add_development_dependency 'rspec', '>= 2.13.0'

  s.require_path = 'lib'
end

