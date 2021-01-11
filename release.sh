#!/usr/bin/env bash
# This script builds and packages the project for release
# Lint with https://www.shellcheck.net/ when making changes
set -Eeuo pipefail

if [[ -d "build" ]]; then
  echo -e "\nRemoving existing build folder"
  rm -rfv "build"
fi

echo -e "\nBuilding the frameworks for distribution"

echo -e "\nBuilding iOS Device"
xcodebuild clean archive -project SLRNetworkMonitor.xcodeproj -scheme SLRNetworkMonitor-iOS -configuration Release -destination generic/platform=iOS -sdk iphoneos -archivePath build/archives/ios.xcarchive SKIP_INSTALL=NO BUILD_LIBRARY_FOR_DISTRIBUTION=YES
echo -e "\nBuilding iOS Simulator"
xcodebuild clean archive -project SLRNetworkMonitor.xcodeproj -scheme SLRNetworkMonitor-iOS -configuration Release -destination generic/platform=iOS\ Simulator -sdk iphonesimulator -archivePath build/archives/ios-sim.xcarchive SKIP_INSTALL=NO BUILD_LIBRARY_FOR_DISTRIBUTION=YES
echo -e "\nBuilding Mac Catalyst"
xcodebuild clean archive -project SLRNetworkMonitor.xcodeproj -scheme SLRNetworkMonitor-iOS -configuration Release -destination 'platform=macOS,variant=Mac Catalyst' -archivePath build/archives/ios-cat.xcarchive SKIP_INSTALL=NO BUILD_LIBRARY_FOR_DISTRIBUTION=YES
echo -e "\nBuilding macOS"
xcodebuild clean archive -project SLRNetworkMonitor.xcodeproj -scheme SLRNetworkMonitor-macOS -configuration Release -archivePath build/archives/mac.xcarchive SKIP_INSTALL=NO BUILD_LIBRARY_FOR_DISTRIBUTION=YES
echo -e "\nBuilding tvOS Device"
xcodebuild clean archive -project SLRNetworkMonitor.xcodeproj -scheme SLRNetworkMonitor-tvOS -configuration Release -destination generic/platform=tvOS -archivePath build/archives/tvos.xcarchive SKIP_INSTALL=NO BUILD_LIBRARY_FOR_DISTRIBUTION=YES
echo -e "\nBuilding tvOS Simulator"
xcodebuild clean archive -project SLRNetworkMonitor.xcodeproj -scheme SLRNetworkMonitor-tvOS -configuration Release -destination generic/platform=tvOS\ Simulator -archivePath build/archives/tvos-sim.xcarchive SKIP_INSTALL=NO BUILD_LIBRARY_FOR_DISTRIBUTION=YES
echo -e "\nBuilding watchOS Device"
xcodebuild clean archive -project SLRNetworkMonitor.xcodeproj -scheme SLRNetworkMonitor-watchOS -configuration Release -destination generic/platform=watchOS -archivePath build/archives/watchos.xcarchive SKIP_INSTALL=NO BUILD_LIBRARY_FOR_DISTRIBUTION=YES
echo -e "\nBuilding watchOS Simulator"
xcodebuild clean archive -project SLRNetworkMonitor.xcodeproj -scheme SLRNetworkMonitor-watchOS -configuration Release -destination generic/platform=watchOS\ Simulator -archivePath build/archives/watchos-sim.xcarchive SKIP_INSTALL=NO BUILD_LIBRARY_FOR_DISTRIBUTION=YES

iOSBCMaps=()
tvBCMaps=()
watchBCMaps=()

echo -e "\nFinding iOS Bitcode Symbol Maps"
while IFS= read -d '' -r filename; do
    iOSBCMaps+=("$filename")
done < <(find "$(pwd -P)"/build/archives -path "*ios*" -name "*.bcsymbolmap" -print0)

echo -e "\nFinding tvOS Bitcode Symbol Maps"
while IFS= read -d '' -r filename; do
    tvBCMaps+=("$filename")
done < <(find "$(pwd -P)"/build/archives -path "*tv*" -name "*.bcsymbolmap" -print0)

echo -e "\nFinding watchOS Bitcode Symbol Maps"
while IFS= read -d '' -r filename; do
    watchBCMaps+=("$filename")
done < <(find "$(pwd -P)"/build/archives -path "*watch*" -name "*.bcsymbolmap" -print0)

set +u
iOSBCMapCount=${#iOSBCMaps[@]}
tvBCMapCount=${#tvBCMaps[@]}
watchBCMapCount=${#watchBCMaps[@]}
set -u

iOSDebugSymbols=""
tvDebugSymbols=""
watchDebugSymbols=""

echo -e "\nGenerating iOS Bitcode Symbol Map command"
for ((i=0;i<iOSBCMapCount;i++)); do
  iOSDebugSymbols+=" -debug-symbols ${iOSBCMaps[i]}"
done

echo -e "\nGenerating tvOS Bitcode Symbol Map command"
for ((i=0;i<tvBCMapCount;i++)); do
  tvDebugSymbols+=" -debug-symbols ${tvBCMaps[i]}"
done

echo -e "\nGenerating watchOS Bitcode Symbol Map command"
for ((i=0;i<watchBCMapCount;i++)); do
  watchDebugSymbols+=" -debug-symbols ${watchBCMaps[i]}"
done

echo -e "\nCreating iOS XCFramework"
# shellcheck disable=SC2086
xcodebuild -create-xcframework -framework build/archives/ios.xcarchive/Products/Library/Frameworks/SLRNetworkMonitor.framework \
-debug-symbols "$(pwd -P)"/build/archives/ios.xcarchive/dSYMs/SLRNetworkMonitor.framework.dSYM \
-framework build/archives/ios-sim.xcarchive/Products/Library/Frameworks/SLRNetworkMonitor.framework \
-debug-symbols "$(pwd -P)"/build/archives/ios-sim.xcarchive/dSYMs/SLRNetworkMonitor.framework.dSYM \
-framework build/archives/ios-cat.xcarchive/Products/Library/Frameworks/SLRNetworkMonitor.framework \
-debug-symbols "$(pwd -P)"/build/archives/ios-cat.xcarchive/dSYMs/SLRNetworkMonitor.framework.dSYM \
$iOSDebugSymbols \
-output build/frameworks/iOS/SLRNetworkMonitor.xcframework

echo -e "\nCreating macOS XCFramework"
xcodebuild -create-xcframework -framework build/archives/mac.xcarchive/Products/Library/Frameworks/SLRNetworkMonitor.framework \
-debug-symbols "$(pwd -P)"/build/archives/mac.xcarchive/dSYMs/SLRNetworkMonitor.framework.dSYM \
-output build/frameworks/macOS/SLRNetworkMonitor.xcframework

echo -e "\nCreating tvOS XCFramework"
# shellcheck disable=SC2086
xcodebuild -create-xcframework -framework build/archives/tvos.xcarchive/Products/Library/Frameworks/SLRNetworkMonitor.framework \
-debug-symbols "$(pwd -P)"/build/archives/tvos.xcarchive/dSYMs/SLRNetworkMonitor.framework.dSYM \
-framework build/archives/tvos-sim.xcarchive/Products/Library/Frameworks/SLRNetworkMonitor.framework \
-debug-symbols "$(pwd -P)"/build/archives/tvos-sim.xcarchive/dSYMs/SLRNetworkMonitor.framework.dSYM \
$tvDebugSymbols \
-output build/frameworks/tvOS/SLRNetworkMonitor.xcframework

echo -e "\nCreating watchOS XCFramework"
# shellcheck disable=SC2086
xcodebuild -create-xcframework -framework build/archives/watchos.xcarchive/Products/Library/Frameworks/SLRNetworkMonitor.framework \
-debug-symbols "$(pwd -P)"/build/archives/watchos.xcarchive/dSYMs/SLRNetworkMonitor.framework.dSYM \
-framework build/archives/watchos-sim.xcarchive/Products/Library/Frameworks/SLRNetworkMonitor.framework \
-debug-symbols "$(pwd -P)"/build/archives/watchos-sim.xcarchive/dSYMs/SLRNetworkMonitor.framework.dSYM \
$watchDebugSymbols \
-output build/frameworks/watchOS/SLRNetworkMonitor.xcframework

echo -e "\nCreating distribution archives"
rootDirectory="$PWD"
cd build/frameworks/iOS/
echo -e "\nCreating iOS archive"
zip -r -o SLRNetworkMonitor-iOS.zip .
mv SLRNetworkMonitor-iOS.zip "$rootDirectory"
cd "$rootDirectory"

cd build/frameworks/macOS/
echo -e "\nCreating macOS archive"
zip -r -o SLRNetworkMonitor-macOS.zip .
mv SLRNetworkMonitor-macOS.zip "$rootDirectory"
cd "$rootDirectory"

cd build/frameworks/tvOS/
echo -e "\nCreating tvOS archive"
zip -r -o SLRNetworkMonitor-tvOS.zip .
mv SLRNetworkMonitor-tvOS.zip "$rootDirectory"
cd "$rootDirectory"

cd build/frameworks/watchOS/
echo -e "\nCreating watchOS archive"
zip -r -o SLRNetworkMonitor-watchOS.zip .
mv SLRNetworkMonitor-watchOS.zip "$rootDirectory"
cd "$rootDirectory"

echo -e "\nRelease Complete"
