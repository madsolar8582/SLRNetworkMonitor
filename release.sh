#!/usr/bin/env bash
# This script builds and packages the project for release
# Lint with https://www.shellcheck.net/ when making changes
set -Eeuo pipefail

if ! carthage_location="$(type -p carthage)" || [[ -z "$carthage_location" ]]; then
  echo -e "\nUnable to find carthage. Is it installed?"
  exit 127
fi

if [[ -d "Carthage/Build" ]]; then
  echo -e "\nRemoving existing Carthage/Build folder"
  rm -rfv "Carthage/Build"
fi

echo -e "\nBuilding the frameworks for distribution"
carthage build --verbose --no-skip-current 

echo -e "\nVerifying builds contain required architectures"
iOSArchitectures=$(lipo -info Carthage/Build/iOS/SLRNetworkMonitor.framework/SLRNetworkMonitor)
macOSArchitectures=$(lipo -info Carthage/Build/Mac/SLRNetworkMonitor.framework/SLRNetworkMonitor)
tvOSArchitectures=$(lipo -info Carthage/Build/tvOS/SLRNetworkMonitor.framework/SLRNetworkMonitor)
watchOSArchitectures=$(lipo -info Carthage/Build/watchOS/SLRNetworkMonitor.framework/SLRNetworkMonitor)

if ! (grep -q "x86_64 arm64" <<< "$iOSArchitectures"); then
  echo -e "\niOS architectures did not validate"
  exit 1
fi

if ! (grep -q "x86_64" <<< "$macOSArchitectures"); then
  echo -e "\niOS architectures did not validate"
  exit 1
fi

if ! (grep -q "x86_64 arm64" <<< "$tvOSArchitectures"); then
  echo -e "\ntvOS architectures did not validate"
  exit 1
fi

if ! (grep -q "1386 armv7k arm64_32" <<< "$watchOSArchitectures"); then
  echo -e "\nwatchOS architectures did not validate"
  exit 1
fi

echo -e "\nVerifying dSYMs contain required UUIDs"
iOSDwarfOutput=$(dwarfdump -u Carthage/Build/iOS/SLRNetworkMonitor.framework.dSYM)
macOSDwarfOutput=$(dwarfdump -u Carthage/Build/Mac/SLRNetworkMonitor.framework.dSYM)
tvOSDwarfOutput=$(dwarfdump -u Carthage/Build/tvOS/SLRNetworkMonitor.framework.dSYM)
watchOSDwarfOutput=$(dwarfdump -u Carthage/Build/watchOS/SLRNetworkMonitor.framework.dSYM)
iOSUUIDs="$(grep -c "UUID:" <<< "$iOSDwarfOutput")"
macOSUUIDs="$(grep -c "UUID:" <<< "$macOSDwarfOutput")"
tvOSUUIDs="$(grep -c "UUID:" <<< "$tvOSDwarfOutput")"
watchOSUUIDs="$(grep -c "UUID:" <<< "$watchOSDwarfOutput")"

if [[ "$iOSUUIDs" -ne 2 ]]; then
  echo -e "\niOS dSYM is missing mappings"
  exit 1
fi

if [[ "$macOSUUIDs" -ne 1 ]]; then
  echo -e "\nmacOS dSYM is missing mappings"
  exit 1
fi

if [[ "$tvOSUUIDs" -ne 2 ]]; then
  echo -e "\ntvOS dSYM is missing mappings"
  exit 1
fi

if [[ "$watchOSUUIDs" -ne 3 ]]; then
  echo -e "\nwatchOS dSYM is missing mappings"
  exit 1
fi

echo -e "\nVerifying bcsymbolmaps are present"
# shellcheck disable=SC2012
iOSSymbolMaps=$(ls Carthage/Build/iOS/*.bcsymbolmap | wc -l)
# shellcheck disable=SC2012
tvOSSymbolMaps=$(ls Carthage/Build/tvOS/*.bcsymbolmap | wc -l)
# shellcheck disable=SC2012
watchOSSymbolMaps=$(ls Carthage/Build/watchOS/*.bcsymbolmap | wc -l)

if [[ "$iOSSymbolMaps" -ne 1 ]]; then
  echo -e "\niOS bitcode symbol maps are missing"
  exit 1
fi

if [[ "$tvOSSymbolMaps" -ne 1 ]]; then
  echo -e "\ntvOS bitcode symbol maps are missing"
  exit 1
fi

if [[ "$watchOSSymbolMaps" -ne 2 ]]; then
  echo -e "\nwatchOS bitcode symbol maps are missing"
  exit 1
fi

echo -e "\nCreating distribution archives"
rootDirectory="$PWD"
cd Carthage/Build/iOS/
echo -e "\nCreating iOS archive"
zip -r -o SLRNetworkMonitor-iOS.zip .
mv SLRNetworkMonitor-iOS.zip "$rootDirectory"
cd "$rootDirectory"

cd Carthage/Build/Mac/
echo -e "\nCreating macOS archive"
zip -r -o SLRNetworkMonitor-macOS.zip .
mv SLRNetworkMonitor-macOS.zip "$rootDirectory"
cd "$rootDirectory"

cd Carthage/Build/tvOS/
echo -e "\nCreating tvOS archive"
zip -r -o SLRNetworkMonitor-tvOS.zip .
mv SLRNetworkMonitor-tvOS.zip "$rootDirectory"
cd "$rootDirectory"

cd Carthage/Build/watchOS/
echo -e "\nCreating watchOS archive"
zip -r -o SLRNetworkMonitor-watchOS.zip .
mv SLRNetworkMonitor-watchOS.zip "$rootDirectory"
cd "$rootDirectory"

echo -e "\nRelease Complete"
