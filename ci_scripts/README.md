# Xcode Cloud CI Scripts

This directory contains custom scripts that run at various stages of the Xcode Cloud build lifecycle.

## Scripts

### `ci_post_clone.sh`
**Runs**: After Xcode Cloud clones the repository

**Purpose**:
- Sets up environment variables for property-based testing
- Resolves Swift Package Manager dependencies
- Displays CI environment information for debugging
- Configures SwiftCheck defaults if not specified by workflow

### `ci_pre_xcodebuild.sh`
**Runs**: Before each xcodebuild command

**Purpose**:
- Logs build action and configuration
- Prepares test environment for property-based testing
- Reports system resources (memory, CPU cores)
- Estimates test duration based on iteration count
- Creates derived data directory if needed

### `ci_post_xcodebuild.sh`
**Runs**: After each xcodebuild command

**Purpose**:
- Processes and reports test results
- Logs property test configuration used
- Reports archive status for production builds
- Provides build success/failure summary

## Environment Variables

The scripts use and configure the following environment variables:

| Variable | Default | Description |
|----------|---------|-------------|
| `SWIFTCHECK_MAX_TESTS` | 10000 | Number of test cases to generate per property |
| `SWIFTCHECK_MAX_SIZE` | 500 | Maximum size of generated test inputs |
| `SWIFTCHECK_MAX_DISCARD_RATIO` | 5 | Ratio of discarded to successful tests |

These can be overridden in the workflow `.ci.yml` files.

## Xcode Cloud Environment Variables

The scripts have access to Xcode Cloud's built-in environment variables:

| Variable | Description |
|----------|-------------|
| `CI` | Set to "TRUE" in Xcode Cloud |
| `CI_WORKFLOW` | Name of the current workflow |
| `CI_BRANCH` | Branch being built |
| `CI_COMMIT` | Commit SHA |
| `CI_BUILD_NUMBER` | Build number |
| `CI_XCODEBUILD_ACTION` | Current action (build, test, archive) |
| `CI_DERIVED_DATA_PATH` | Path to derived data |
| `CI_RESULT_BUNDLE_PATH` | Path to test result bundle |

## Script Execution Order

```
1. Repository cloned by Xcode Cloud
2. ci_post_clone.sh
3. ci_pre_xcodebuild.sh (before each xcodebuild)
4. xcodebuild <action>
5. ci_post_xcodebuild.sh (after each xcodebuild)
```

## Debugging

To debug script issues:

1. Check the Xcode Cloud build logs for script output
2. Look for the `===` delimited sections
3. Verify environment variables are set correctly
4. Check exit codes for failed commands

## Adding New Scripts

Xcode Cloud supports additional scripts:
- `ci_post_clone.sh` - After clone
- `ci_pre_xcodebuild.sh` - Before each xcodebuild
- `ci_post_xcodebuild.sh` - After each xcodebuild

All scripts must be:
1. Named exactly as shown above
2. Located in the `ci_scripts` directory
3. Marked as executable (`chmod +x`)
4. Use `#!/bin/bash` shebang

## References

- [Xcode Cloud Custom Scripts](https://developer.apple.com/documentation/xcode/writing-custom-build-scripts)
- [Xcode Cloud Environment Variables](https://developer.apple.com/documentation/xcode/environment-variable-reference)
- [Property Testing Guide](../PROPERTY_TESTING.md)
