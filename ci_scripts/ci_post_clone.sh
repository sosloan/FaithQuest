#!/bin/bash
# ci_post_clone.sh
# This script runs after Xcode Cloud clones the repository.
# It sets up the environment for property-based testing.

set -e

echo "=== FaithQuest CI Post Clone Script ==="
echo "Date: $(date)"
echo "Working Directory: $(pwd)"
echo "Xcode Version: $(xcodebuild -version | head -1)"

# Display CI environment information
echo ""
echo "=== Environment Information ==="
echo "CI: ${CI:-not set}"
echo "CI_WORKFLOW: ${CI_WORKFLOW:-not set}"
echo "CI_XCODE_PROJECT: ${CI_XCODE_PROJECT:-not set}"
echo "CI_PRODUCT: ${CI_PRODUCT:-not set}"
echo "CI_BRANCH: ${CI_BRANCH:-not set}"
echo "CI_COMMIT: ${CI_COMMIT:-not set}"
echo "CI_BUILD_NUMBER: ${CI_BUILD_NUMBER:-not set}"

# Configure SwiftCheck property test environment variables if not already set
echo ""
echo "=== Configuring Property Test Environment ==="

if [ -z "$SWIFTCHECK_MAX_TESTS" ]; then
    export SWIFTCHECK_MAX_TESTS=10000
    echo "Setting default SWIFTCHECK_MAX_TESTS: $SWIFTCHECK_MAX_TESTS"
else
    echo "Using configured SWIFTCHECK_MAX_TESTS: $SWIFTCHECK_MAX_TESTS"
fi

if [ -z "$SWIFTCHECK_MAX_SIZE" ]; then
    export SWIFTCHECK_MAX_SIZE=500
    echo "Setting default SWIFTCHECK_MAX_SIZE: $SWIFTCHECK_MAX_SIZE"
else
    echo "Using configured SWIFTCHECK_MAX_SIZE: $SWIFTCHECK_MAX_SIZE"
fi

if [ -z "$SWIFTCHECK_MAX_DISCARD_RATIO" ]; then
    export SWIFTCHECK_MAX_DISCARD_RATIO=5
    echo "Setting default SWIFTCHECK_MAX_DISCARD_RATIO: $SWIFTCHECK_MAX_DISCARD_RATIO"
else
    echo "Using configured SWIFTCHECK_MAX_DISCARD_RATIO: $SWIFTCHECK_MAX_DISCARD_RATIO"
fi

# Resolve Swift Package Manager dependencies
echo ""
echo "=== Resolving Swift Package Dependencies ==="
if [ -f "Package.swift" ]; then
    swift package resolve
    echo "Swift Package dependencies resolved successfully"
else
    echo "No Package.swift found, skipping SPM resolution"
fi

# Check for required simulators
echo ""
echo "=== Checking Available Simulators ==="
xcrun simctl list devices available | grep -E "(iPhone|iPad)" | head -10

echo ""
echo "=== Post Clone Script Completed Successfully ==="
