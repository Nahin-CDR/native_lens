Pod::Spec.new do |s|
  s.name             = 'native_lens'
  s.version          = '0.2.1'
  s.summary          = 'NativeLens iOS plugin'
  s.description      = <<-DESC
A Flutter plugin that provides native device diagnostics and platform capability summaries on iOS.
                       DESC
  s.homepage         = 'https://github.com/Nahin-CDR/native_lens'
  s.license          = { :type => 'MIT', :file => '../LICENSE' }
  s.author           = { 'Nahin' => 'nahin@example.com' }
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.public_header_files = 'Classes/**/*.h'
  s.dependency       'Flutter'
  s.platform         = :ios, '13.0'
  s.swift_version    = '5.0'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
end
