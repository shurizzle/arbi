Gem::Specification.new {|g|
    g.name          = 'arbi'
    g.version       = '1.0.8'
    g.author        = 'shura'
    g.email         = 'shura1991@gmail.com'
    g.homepage      = 'http://github.com/shurizzle/arbi'
    g.platform      = Gem::Platform::RUBY
    g.description   = ''
    g.summary       = ''
    g.files         = Dir.glob('lib/**/*.rb')
    g.require_path  = 'lib'
    g.executables   = ['arbid', 'arbi']
    g.has_rdoc      = true

    g.add_dependency('sys-filesystem')
    g.add_dependency('eventmachine')
    g.add_dependency('json')
}
