Pod::Spec.new do |s|
  s.name                      = 'SLRNetworkMonitor'
  s.version                   = '2.0.0'
  s.summary                   = 'Network status monitor for macOS, iOS, and tvOS.'
  s.description               = 'A Network status monitor for macOS, iOS, and tvOS that leverages Network.framework instead of SCNetworkReachability.'
  s.homepage                  = 'https://madsolar8582.github.io/SLRNetworkMonitor/'
  s.license                   = { :type => 'LGPLv3', :file => 'LICENSE.md' }
  s.author                    = 'Madison Solarana'
  s.ios.deployment_target     = '12.0'
  s.macos.deployment_target   = '14.0'
  s.tvos.deployment_target    = '12.0'
  s.watchos.deployment_target = '6.0'
  s.ios.frameworks            = 'Network', 'Foundation', 'CoreTelephony' 
  s.macos.frameworks          = 'Network', 'Foundation'
  s.tvos.frameworks           = 'Network', 'Foundation'
  s.watchos.frameworks        = 'Network', 'Foundation'  
  s.ios.libraries             = 'resolv' 
  s.macos.libraries           = 'resolv'
  s.tvos.libraries            = 'resolv'
  s.source                    = { git: 'https://github.com/madsolar8582/SLRNetworkMonitor.git', tag: s.version.to_s }
  s.source_files              = 'Source/**/*.{h,m}'
  s.requires_arc              = true
end
