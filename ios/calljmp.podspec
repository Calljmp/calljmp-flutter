Pod::Spec.new do |s|
  s.name             = 'calljmp'
  s.version          = '0.0.1-preview'
  s.summary          = 'Calljmp SDK for Flutter'
  s.description      = <<-DESC
Calljmp SDK for Flutter. Provides seamless integration for call management in Flutter apps, supporting iOS 14.0 and above.
                       DESC
  s.homepage         = 'http://calljmp.com'
  s.license          = { :type => 'MIT', :file => '../LICENSE' }
  s.author           = { 'Calljmp' => 'info@calljmp.com' }
  s.source           = { :git => 'https://github.com/Calljmp/calljmp-flutter.git', :tag => s.version.to_s }

  s.source_files = 'Classes/**/*'
  s.public_header_files = 'Classes/**/*.h'

  s.dependency 'Flutter'
  s.platform = :ios, '14.0'
  s.frameworks = 'DeviceCheck'

  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
end
