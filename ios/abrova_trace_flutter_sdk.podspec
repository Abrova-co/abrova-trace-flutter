Pod::Spec.new do |s|
  s.name             = 'abrova_trace_flutter_sdk'
  s.version          = '0.2.8'
  s.summary          = 'AbrovaTrace Flutter plugin with real native crash capture'
  s.description      = <<-DESC
AbrovaTrace error tracking and APM SDK for Flutter. Native iOS crashes
are captured by the standalone AbrovaTrace pod (which uses PLCrashReporter
under the hood). This package only contains the Flutter MethodChannel
bridge from Dart to the native SDK.
  DESC

  s.homepage         = 'https://abrova.ir/cloud/abrova-trace'
  s.license          = { :type => 'MIT', :file => '../LICENSE' }
  s.author           = { 'AbrovaTrace' => 'support@abrova.ir' }
  s.source           = { :path => '.' }

  s.platform               = :ios, '12.0'
  s.ios.deployment_target  = '12.0'
  s.swift_version          = '5.5'
  s.static_framework       = true

  # Flutter plugin bridge only. The native crash reporter + all other
  # SDK classes come from the standalone AbrovaTrace pod below.
  s.source_files = 'abrova_trace_flutter_sdk/Sources/abrova_trace_flutter_sdk/**/*.swift'
  s.public_header_files = 'Classes/**/*.h'

  s.dependency 'Flutter'
  s.dependency 'AbrovaTrace', '~> 0.2.5'

  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386'
  }
end
