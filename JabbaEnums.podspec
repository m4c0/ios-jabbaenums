Pod::Spec.new do |spec|
  spec.name = 'JabbaEnums'
  spec.version = '0.0.1'
  spec.summary = 'An old iOS library to add "java-like" enums to objective-c (whatever that meant).'
  spec.homepage = 'https://github.com/m4c0/ios-jabbaenums'
  spec.license = { :type => 'GPLv3', :file => 'LICENSE' }
  spec.author = {
    'Eduardo Costa' => 'm4c0@github.com',
  }
  spec.source = { :git => 'https://github.com/m4c0/ios-jabbaenums.git', :tag => "v#{spec.version}" }
  spec.source_files = 'JabbaEnums/*.{h,m}'
  spec.requires_arc = true
  spec.ios.deployment_target = '6.0'
end


