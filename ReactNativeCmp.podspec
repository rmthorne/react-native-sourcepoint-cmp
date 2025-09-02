require "json"

package = JSON.parse(File.read(File.join(__dir__, "package.json")))

# Fallback for min_ios_version_supported if not available
def min_ios_version_supported
  return "13.4"
end

puts "Min iOS version: #{min_ios_version_supported} (from .podspec)"

Pod::Spec.new do |s|
  s.name         = "ReactNativeCmp"
  s.version      = package["version"]
  s.summary      = package["description"]
  s.homepage     = package["homepage"]
  s.license      = package["license"]
  s.authors      = package["author"]

  s.static_framework = true

  s.platforms    = { :ios => min_ios_version_supported }
  s.source       = { :git => "https://github.com/SourcePointUSA/react-native-sourcepoint-cmp.git", :tag => "#{s.version}" }

  s.dependency "ConsentViewController", "7.12.1"
  s.source_files = "ios/**/*.{h,m,mm,cpp,swift}"
  s.private_header_files = "ios/**/*.h"

  # Check if new architecture is enabled
  new_arch_enabled = ENV['RCT_NEW_ARCH_ENABLED'] == '1'
  
  if new_arch_enabled
    s.pod_target_xcconfig = {
      'DEFINES_MODULE' => 'YES',
      'SWIFT_OBJC_INTERFACE_HEADER_NAME' => 'ReactNativeCmp-Swift.h',
      # This ensures that it loads as a TurboModule in new architecture
      'OTHER_CFLAGS' => '$(inherited) -DRCT_NEW_ARCH_ENABLED=1'
    }
  else
    s.pod_target_xcconfig = {
      'DEFINES_MODULE' => 'YES',
      'SWIFT_OBJC_INTERFACE_HEADER_NAME' => 'ReactNativeCmp-Swift.h',
      # This ensures that it loads as a legacy bridge module
      'OTHER_CFLAGS' => '$(inherited) -DRCT_NEW_ARCH_ENABLED=0'
    }
  end

  # Install dependencies based on architecture
  if new_arch_enabled
    install_modules_dependencies(s)
  else
    # For legacy architecture, ensure React/Core is available
    s.dependency "React-Core"
  end
end
