Pod::Spec.new do |s|
  s.name = 'SunburstDiagram'
  s.version = '1.5.0'
  s.license = 'MIT'
  s.summary = 'Easily render diagrams in SwiftUI'
  s.homepage = 'https://github.com/lludo/SwiftSunburstDiagram'
  s.authors = { 'Ludovic Landry' => '@ludoviclandry' }
  s.source = { :git => 'https://github.com/lludo/SwiftSunburstDiagram.git', :tag => s.version }
  s.documentation_url = 'https://github.com/lludo/SwiftSunburstDiagram/wiki'

  s.ios.deployment_target = '26.0'
  s.tvos.deployment_target = '26.0'
  s.osx.deployment_target = '26.0'
  s.watchos.deployment_target = '26.0'

  s.swift_version = '6.2'

  s.source_files = 'Sources/**/*.swift'

  s.frameworks = 'SwiftUI'
end
