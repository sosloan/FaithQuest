#!/bin/bash
# ci_pre_xcodebuild.sh
# This script runs before each xcodebuild command in Xcode Cloud.
# It configures the build environment for property-based testing.

set -e

echo "=== FaithQuest CI Pre-Xcodebuild Script ==="
echo "Date: $(date)"
echo "Working Directory: $(pwd)"

# Display build action information
echo ""
echo "=== Build Action Information ==="
echo "CI_XCODEBUILD_ACTION: ${CI_XCODEBUILD_ACTION:-not set}"
echo "CI_XCODEBUILD_SCHEME: ${CI_XCODEBUILD_SCHEME:-not set}"
echo "CI_DERIVED_DATA_PATH: ${CI_DERIVED_DATA_PATH:-not set}"
echo "CI_RESULT_BUNDLE_PATH: ${CI_RESULT_BUNDLE_PATH:-not set}"

# Configure test environment based on workflow type
echo ""
echo "=== Configuring Test Environment ==="

# Log the SwiftCheck configuration that will be used
echo "Property Test Configuration:"
echo "  - SWIFTCHECK_MAX_TESTS: ${SWIFTCHECK_MAX_TESTS:-10000}"
echo "  - SWIFTCHECK_MAX_SIZE: ${SWIFTCHECK_MAX_SIZE:-500}"
echo "  - SWIFTCHECK_MAX_DISCARD_RATIO: ${SWIFTCHECK_MAX_DISCARD_RATIO:-5}"

# If running tests, configure for property-based testing
if [ "${CI_XCODEBUILD_ACTION}" = "test" ] || [ "${CI_XCODEBUILD_ACTION}" = "build-for-testing" ]; then
    echo ""
    echo "=== Test Action Detected ==="
    echo "Preparing for property-based testing..."
    
    # Log memory and CPU for debugging
    echo ""
    echo "System Resources:"
    sysctl -n hw.memsize | awk '{print "  - Memory: " $1/1024/1024/1024 " GB"}'
    sysctl -n hw.ncpu | awk '{print "  - CPU Cores: " $1}'
    
    # Estimate test duration based on iteration count
    ITERATIONS=${SWIFTCHECK_MAX_TESTS:-10000}
    ESTIMATED_MINUTES=$((ITERATIONS / 5000))
    if [ $ESTIMATED_MINUTES -lt 1 ]; then
        ESTIMATED_MINUTES=1
    fi
    echo ""
    echo "Estimated test duration: ~${ESTIMATED_MINUTES} minutes per test class"
fi

# Archive action preparation
if [ "${CI_XCODEBUILD_ACTION}" = "archive" ]; then
    echo ""
    echo "=== Archive Action Detected ==="
    echo "Preparing for archiving..."
    
    # Log archive configuration
    echo "Archive Configuration:"
    echo "  - CI_ARCHIVE_PATH: ${CI_ARCHIVE_PATH:-not set}"
    echo "  - CI_PRODUCT_PLATFORM: ${CI_PRODUCT_PLATFORM:-not set}"
fi

# Ensure derived data directory exists
if [ -n "$CI_DERIVED_DATA_PATH" ]; then
    mkdir -p "$CI_DERIVED_DATA_PATH"
    echo ""
    echo "Derived data directory prepared: $CI_DERIVED_DATA_PATH"
fi

echo ""
echo "=== Pre-Xcodebuild Script Completed Successfully ==="
