#!/usr/bin/env bash
# This script is meant to run the project's tests on Travis CI
# Lint with https://www.shellcheck.net/ when making changes
set -Eeuxo pipefail

echo -e "Runing iOS Tests\n"
# Parallel test arm64 & arm64e
xcodebuild clean test -project SLRNetworkMonitor.xcodeproj -scheme SLRNetworkMonitor-iOS -configuration Debug -destination 'platform=iOS Simulator,OS=latest,name=iPhone X' -destination 'platform=iOS Simulator,OS=latest,name=iPhone Xs' -enableThreadSanitizer YES -enableUndefinedBehaviorSanitizer YES
xcodebuild clean test -project SLRNetworkMonitor.xcodeproj -scheme SLRNetworkMonitor-iOS -configuration Debug -destination 'platform=iOS Simulator,OS=latest,name=iPhone X' -destination 'platform=iOS Simulator,OS=latest,name=iPhone Xs' -enableAddressSanitizer YES

# Disable macOS tests until Travis CI has a Mojave image
#echo -e "Running macOS Tests\n"
#xcodebuild clean test -project SLRNetworkMonitor.xcodeproj -scheme SLRNetworkMonitor-macOS -configuration Debug -enableThreadSanitizer YES -enableUndefinedBehaviorSanitizer YES
#xcodebuild clean test -project SLRNetworkMonitor.xcodeproj -scheme SLRNetworkMonitor-macOS -configuration Debug -enableAddressSanitizer YES

echo -e "Running tvOS Tests\n"
xcodebuild clean test -project SLRNetworkMonitor.xcodeproj -scheme SLRNetworkMonitor-tvOS -configuration Debug -destination 'platform=tvOS Simulator,OS=latest,name=Apple TV 4K' -enableThreadSanitizer YES -enableUndefinedBehaviorSanitizer YES
xcodebuild clean test -project SLRNetworkMonitor.xcodeproj -scheme SLRNetworkMonitor-tvOS -configuration Debug -destination 'platform=tvOS Simulator,OS=latest,name=Apple TV 4K' -enableAddressSanitizer YES
