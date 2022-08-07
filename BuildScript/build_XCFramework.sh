#!/bin/bash
set -e

if [ -n "$RW_MULTIPLATFORM_BUILD_IN_PROGRESS" ]; then
exit 0
fi
export RW_MULTIPLATFORM_BUILD_IN_PROGRESS=1

ADAPTER_WORKSPACE="${PROJECT_DIR}/${PROJECT_NAME}.xcworkspace"




#Remove framework if exists.
if [ -d "${PROJECT_DIR}/ReleaseCandidates/${PROJECT_NAME}" ]; then
  rm -rf "${PROJECT_DIR}/ReleaseCandidates/${PROJECT_NAME}"
fi



createFramework() {

xcrun xcodebuild -workspace "${ADAPTER_WORKSPACE}" \
    -scheme "${PROJECT_NAME}" \
    -configuration "${CONFIGURATION}" \
    -sdk "$1" \
    ONLY_ACTIVE_ARCH=NO \
    BUILD_LIBRARY_FOR_DISTRIBUTION=YES\
    ARCHS="$2" \
    BUILD_DIR="${BUILD_DIR}" \
    OBJROOT="${OBJROOT}\DependentBuilds" \
    BUILD_ROOT="${BUILD_ROOT}" \
    SYMROOT="${SYMROOT}" $ACTION


}


  createFramework "iphoneos" "armv7 arm64"
  createFramework "iphonesimulator" "x86_64 i386" 




#Create dynamic framework using the frameworks generated above.
xcodebuild -create-xcframework \
-framework "${BUILD_DIR}/${CONFIGURATION}-iphoneos/${PROJECT_NAME}.framework" \
-framework "${BUILD_DIR}/${CONFIGURATION}-iphonesimulator/${PROJECT_NAME}.framework" \
-output "${PROJECT_DIR}/ReleaseCandidates/${PROJECT_NAME}/${PROJECT_NAME}.xcframework"
