Gem::Specification.new do |s|
  s.name          = "seeka"
  s.description   = %q{A way to provide a filtering interface to ActiveRecord models in rails}
  s.summary       = s.description
  s.homepage      = "https://github.com/adamcooke/seeka"
  s.version       = "1.0.0"
  s.files         = Dir.glob("{lib,vendor}/**/*")
  s.require_paths = ["lib"]
  s.authors       = ["Adam Cooke"]
  s.email         = ["me@adamcooke.io"]
  s.licenses      = ['MIT']
end
