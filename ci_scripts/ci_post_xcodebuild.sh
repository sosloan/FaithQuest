#!/bin/bash
# ci_post_xcodebuild.sh
# This script runs after each xcodebuild command in Xcode Cloud.
# It processes test results and logs for property-based testing.

set -e

echo "=== FaithQuest CI Post-Xcodebuild Script ==="
echo "Date: $(date)"
echo "Working Directory: $(pwd)"

# Display build result information
echo ""
echo "=== Build Result Information ==="
echo "CI_XCODEBUILD_ACTION: ${CI_XCODEBUILD_ACTION:-not set}"
echo "CI_XCODEBUILD_EXIT_CODE: ${CI_XCODEBUILD_EXIT_CODE:-not set}"
echo "CI_RESULT_BUNDLE_PATH: ${CI_RESULT_BUNDLE_PATH:-not set}"

# Process test results if available
if [ "${CI_XCODEBUILD_ACTION}" = "test" ]; then
    echo ""
    echo "=== Processing Test Results ==="
    
    # Check if result bundle exists
    if [ -n "$CI_RESULT_BUNDLE_PATH" ] && [ -d "$CI_RESULT_BUNDLE_PATH" ]; then
        echo "Result bundle found at: $CI_RESULT_BUNDLE_PATH"
        
        # Extract test summary if xcresulttool is available
        # Limit output to avoid overwhelming logs - configurable via CI_RESULT_LINES (default: 50)
        if command -v xcresulttool &> /dev/null; then
            RESULT_LINES=${CI_RESULT_LINES:-50}
            echo ""
            echo "Test Summary (first ${RESULT_LINES} lines):"
            xcresulttool get --path "$CI_RESULT_BUNDLE_PATH" --format json 2>/dev/null | head -"${RESULT_LINES}" || echo "Unable to parse result bundle"
        fi
    else
        echo "No result bundle found or path not set"
    fi
    
    # Log property test configuration used
    echo ""
    echo "=== Property Test Configuration Used ==="
    echo "SWIFTCHECK_MAX_TESTS: ${SWIFTCHECK_MAX_TESTS:-10000}"
    echo "SWIFTCHECK_MAX_SIZE: ${SWIFTCHECK_MAX_SIZE:-500}"
    echo "SWIFTCHECK_MAX_DISCARD_RATIO: ${SWIFTCHECK_MAX_DISCARD_RATIO:-5}"
    
    # Calculate and log test metrics
    ITERATIONS=${SWIFTCHECK_MAX_TESTS:-10000}
    echo ""
    echo "Approximate test iterations completed: $ITERATIONS per property"
fi

# Process archive results
if [ "${CI_XCODEBUILD_ACTION}" = "archive" ]; then
    echo ""
    echo "=== Processing Archive Results ==="
    
    if [ -n "$CI_ARCHIVE_PATH" ] && [ -d "$CI_ARCHIVE_PATH" ]; then
        echo "Archive created at: $CI_ARCHIVE_PATH"
        
        # List archive contents
        echo ""
        echo "Archive Contents:"
        ls -la "$CI_ARCHIVE_PATH" 2>/dev/null || echo "Unable to list archive contents"
    else
        echo "No archive path found or path not set"
    fi
fi

# Report final status
echo ""
echo "=== Build Status ==="
if [ "${CI_XCODEBUILD_EXIT_CODE}" = "0" ]; then
    echo "✅ Build/Test completed successfully"
else
    echo "❌ Build/Test failed with exit code: ${CI_XCODEBUILD_EXIT_CODE:-unknown}"
fi

# Log end time for duration calculation
echo ""
echo "End Time: $(date)"
echo "=== Post-Xcodebuild Script Completed ==="
