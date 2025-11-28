# Xcode Cloud Workflows

This directory contains Xcode Cloud workflow configurations for automated building, testing, and compute maximization.

## Workflow Files

All workflows follow Xcode Cloud's `.ci.yml` format and are automatically detected by Xcode Cloud when connected to the repository.

### File Naming Convention
- `<workflow-name>.ci.yml` - Standard workflow files
- Files must end with `.ci.yml` to be recognized

### Workflow Structure

Each workflow defines:
- **Triggers**: When the workflow runs (branches, PRs, schedules, tags)
- **Actions**: What to execute (build, test, archive, analyze)
- **Environment**: Xcode version, runtime, devices
- **Configuration**: Test repetitions, environment variables

## Quick Reference

| Workflow | Purpose | Trigger | Compute Impact |
|----------|---------|---------|----------------|
| `continuous-property-testing.ci.yml` | Fast CI feedback | Every push | Low |
| `intensive-property-tests.ci.yml` | Regular stress testing | Every 6 hours | Medium |
| `daily-comprehensive-testing.ci.yml` | Daily validation | 2x daily | High |
| `nightly-stress-testing.ci.yml` | Marathon testing | 2x daily | Very High |
| `weekly-marathon-testing.ci.yml` | Ultra-intensive | 2x weekly | Extreme |
| `build-and-archive.ci.yml` | Production builds | Main/tags | Low |

## Environment Variables

Configure property test intensity:

```yaml
env:
  SWIFTCHECK_MAX_TESTS: 50000          # Test iterations
  SWIFTCHECK_MAX_SIZE: 1000            # Input size
  SWIFTCHECK_MAX_DISCARD_RATIO: 10    # Discard ratio
```

## Modifying Workflows

### Add a New Workflow
```bash
# Create new workflow file
touch .xcode/workflows/my-workflow.ci.yml
# Edit with your configuration
# Commit and push - Xcode Cloud auto-detects it
```

### Disable a Workflow
```bash
# Rename to exclude .ci.yml extension
mv workflow.ci.yml workflow.ci.yml.disabled
```

### Test Workflow Locally
Workflows run on Xcode Cloud infrastructure, but you can validate syntax:
```bash
# Build locally
xcodebuild build -project FaithQuest.xcodeproj -scheme FaithQuest

# Test locally with similar environment
SWIFTCHECK_MAX_TESTS=1000 xcodebuild test -project FaithQuest.xcodeproj -scheme FaithQuest
```

## Compute Optimization

To maximize monthly compute hours:

1. **Schedule Density**: Multiple cron schedules throughout day/week
2. **Test Iterations**: High `SWIFTCHECK_MAX_TESTS` values
3. **Test Repetitions**: Multiple runs per configuration
4. **Device Matrix**: Test across various simulators
5. **Parallel Actions**: Multiple actions per workflow

See [XCODE_CLOUD.md](../XCODE_CLOUD.md) for complete compute strategy.

## Property-Based Testing

These workflows focus on property-based tests that:
- Generate random test cases (QuickCheck-style)
- Verify behavioral invariants
- Find edge cases through exploration
- Provide comprehensive coverage

Example property test:
```swift
property("Energy stays in bounds") <- forAll { (energy: Double) in
    let normalized = normalize(energy)
    return normalized >= 0.0 && normalized <= 1.0
}
```

## Custom Build Scripts

The `ci_scripts/` directory contains scripts that run at each build stage:

| Script | Purpose |
|--------|---------|
| `ci_post_clone.sh` | Environment setup, SPM resolution |
| `ci_pre_xcodebuild.sh` | Pre-build logging and configuration |
| `ci_post_xcodebuild.sh` | Result processing and metrics |

See [ci_scripts/README.md](../../ci_scripts/README.md) for details.

## References

- [Xcode Cloud User Guide](https://developer.apple.com/documentation/xcode/xcode-cloud)
- [Workflow Configuration Schema](https://developer.apple.com/documentation/xcode/xcode-cloud-workflow-reference)
- [Custom Build Scripts](https://developer.apple.com/documentation/xcode/writing-custom-build-scripts)
- [Main Documentation](../../XCODE_CLOUD.md)

---

> "In π's infinite digits, primes hide like gems. The polymath finds them where specialists see only chaos."
