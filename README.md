# SLRNetworkMonitor

[![License: LGPL v3](https://img.shields.io/badge/License-LGPL%20v3-blue.svg)](https://www.gnu.org/licenses/lgpl-3.0)
![Platforms: iOS | macOS | tvOS | watchOS](https://img.shields.io/badge/platform-iOS%20%7C%20macOS%20%7C%20tvOS%20%7C%20watchOS-lightgrey.svg)

Provides a wrapper around [NWPathMonitor](https://developer.apple.com/documentation/network/nw_path_monitor_t?language=objc) to replace [SCNetworkReachability](https://developer.apple.com/documentation/systemconfiguration/scnetworkreachability?language=objc).

## Table of Contents

- [Getting Started](#getting-started)
  - [Installation](#installation)
    - [Requirements](#requirements)
    - [Binary Installation](#binary-installation)
    - [Source Installation](#source-installation)
    - [Carthage](#carthage)
    - [CocoaPods](#cocoapods)
  - [Usage](#usage)
  - [Documentation](#documentation)
- [Contributing](#contributing)
- [Support](#support)
- [License](#license)
- [Changes](#changes)
- [Versioning](#versioning)
- [Release Management](#release-management)

## Getting Started

These instructions will get you up and running with SLRNetworkMonitor.

### Installation

#### Requirements

| Version | Minimum Xcode Version | Minimum macOS SDK | Minimum iOS SDK | Minimum tvOS SDK | Minimum watchOS SDK |
| ------- | --------------------- | ----------------- | --------------- | ---------------- | ------------------- |
| 2.0.0 -> Current | 11.0 | 10.14 | 12.0 | 12.0 | 6.0 |
| 1.0.0 | 10.0 | 10.14 | 12.0 | 12.0 | N/A |

This library depends on a few system frameworks and libraries. If you have Modules and Link Frameworks Automatically enabled, then there isn't much that needs to be done. However, if you do not, you need to link against the `Network`, `Foundation`, & the `CoreTelephony` (iOS only) frameworks. Additionally, both types of configurations must manually add `libresolv` to the Link Binary With Libraries build phase.

#### Binary Installation

It is recommended to download the latest binary from the [releases page](https://github.com/madsolar8582/SLRNetworkMonitor/releases) and then include it in your project. If you prefer a different integration method, there are options.

⚠️ Note: If you use the binary release, you will have strip the simulator architectures from the framework on iOS and tvOS as App Store Connect disallows unused architectures from being submitted. This is not needed if Carthage or CocoaPods is used. Example [1](https://github.com/realm/realm-cocoa/blob/c0e5f3c14a7cfae384147cf1e429593989a55abf/scripts/strip-frameworks.sh) and Example [2](https://gist.github.com/steipete/bbea370b72bbc77a8040).

#### Source Installation

If you want to build the library from source in your own project, you can either:

1. Add the project as a [submodule](https://git-scm.com/docs/git-submodule).
2. Add the project as a [subtree](https://www.atlassian.com/blog/git/alternatives-to-git-submodule-git-subtree).
3. Copy the source files directly into your project.

The submodule or subtree approach is recommended since you can easily obtain updates.

#### Carthage

If you do not already have [Carthage](https://github.com/Carthage/Carthage) installed, you can install it via [Homebrew](https://brew.sh/):
```bash
brew install carthage
```

Once Carthage is installed, add SLRNetworkMonitor to your `Cartfile`:
```
github "madsolar8582/SLRNetworkMonitor" ~> 2.0.0
```

Finally, run `carthage` and take the resulting `SLRNetworkMonitor.framework` and put it in your project.

#### CocoaPods

If you do not already have [CocoaPods](https://cocoapods.org/) installed, you can install it via [Homebrew](https://brew.sh/) or you can install it via `gem`:
```bash
brew install cocoapods

# OR

sudo gem install cocoapods # Note: sudo is required if you are installing to the system gemset
```

Once CocoaPods is installed, add SLRNetworkMonitor to your `Podfile` or to your `Podspec` as a dependency:
```yaml
# Podfile
pod 'SLRNetworkMonitor', git: 'https://github.com/madsolar8582/SLRNetworkMonitor.git', tag: '2.0.0'

# Podspec
s.dependency 'SLRNetworkMonitor', git: 'https://github.com/madsolar8582/SLRNetworkMonitor.git', tag: '2.0.0'
```

### Usage

To use this library, you need to create an instance of `SLRNetworkMonitor` and then add an observer on the default Notification Center for the `SLRNetworkMonitorNetworkStateDidChangeNotification` notification. 

⚠️ Note: you can control more attributes of the monitor by initializing it using the other initializers.

```obj-c
@import SLRNetworkMonitor;

- (void)someMethod
{
  SLRNetworkMonitor *monitor = [SLRNetworkMonitor monitor];
  self.networkMonitor = monitor;

  [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(handleNetworkStateChange:) name:SLRNetworkMonitorNetworkStateDidChangeNotification object:monitor];
  [monitor startMonitoring];
}
```

⚠️ Note: you can pause network monitoring by calling `-stopMonitoring`.

### Documentation

Additional documentation can be found on [GitHub Pages](https://madsolar8582.github.io/SLRNetworkMonitor/).

## Contributing

Please read [CONTRIBUTING](https://github.com/madsolar8582/SLRNetworkMonitor/blob/master/.github/CONTRIBUTING.md) for details on how to contribute.

## Support

Please read [SUPPORT](https://github.com/madsolar8582/SLRNetworkMonitor/blob/master/.github/SUPPORT.md) for details on how to get help with installation or usage.

## License

This project is licensed under the [LGPL v3](https://github.com/madsolar8582/SLRNetworkMonitor/blob/master/LICENSE.md) license.

## Changes

Please read the [CHANGELOG](https://github.com/madsolar8582/SLRNetworkMonitor/blob/master/CHANGELOG.md) for details on the changes included in each release.

## Versioning

This project uses [Semantic Versioning](https://semver.org/) for versioning. For the versions available, see the [releases page](https://github.com/madsolar8582/SLRNetworkMonitor/releases).

## Release Management

This project releases monthly if there are enough changes to warrant a release. However, if there are critical defects or inadvertent non-passive changes, a one-off release will be created for each impacted release series.

After a major version release, the older release series will stop receiving updates after 60 days and are then considered obsolete (and thus unsupported).
