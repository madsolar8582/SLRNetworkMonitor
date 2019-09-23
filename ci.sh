#!/usr/bin/env bash
# Lint with https://www.shellcheck.net/ when making changes
set -Eeuxo pipefail

echo -e "Runing iOS Tests\n"
env NSUnbufferedIO=YES xcodebuild clean test -project SLRNetworkMonitor.xcodeproj -scheme SLRNetworkMonitor-iOS -configuration Debug -destination 'platform=iOS Simulator,OS=latest,name=iPhone 11' -testPlan SLRNetworkMonitor-iOS

echo -e "Running macOS Tests\n"
env NSUnbufferedIO=YES xcodebuild clean test -project SLRNetworkMonitor.xcodeproj -scheme SLRNetworkMonitor-macOS -configuration Debug -testPlan SLRNetworkMonitor-macOS

echo -e "Running tvOS Tests\n"
env NSUnbufferedIO=YES xcodebuild clean test -project SLRNetworkMonitor.xcodeproj -scheme SLRNetworkMonitor-tvOS -configuration Debug -destination 'platform=tvOS Simulator,OS=latest,name=Apple TV 4K' -testPlan SLRNetworkMonitor-tvOS
