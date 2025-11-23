# Xcode Cloud Configuration for ML Training (Property-Based Testing)

## Overview

This repository is configured with **Xcode Cloud workflows** designed to maximize the monthly compute allowance for intensive property-based testing. The property tests use [SwiftCheck](https://github.com/typelift/SwiftCheck) to generate thousands of random test cases, providing comprehensive behavioral coverage.

## Why "ML Training"?

In the context of FaithQuest, "ML training" refers to the intensive computational work of:
- Running property-based tests with **100,000+ iterations**
- Testing behavioral invariants across infinite input spaces
- Discovering edge cases through randomized testing
- Validating mathematical properties (harmony, energy conservation, etc.)

Property-based testing is computationally intensive—similar to machine learning training—as it explores vast search spaces to find counterexamples to stated properties.

## Workflows

### 1. Continuous Property Testing (`continuous-property-testing.ci.yml`)
**Triggers**: All branches, pull requests  
**Frequency**: On every push  
**Iterations**: 10,000 per test  
**Devices**: iPhone 15 Pro, iPad Pro 12.9"  
**Purpose**: Fast feedback on code changes

### 2. Intensive Property Tests (`intensive-property-tests.ci.yml`)
**Triggers**: Every 6 hours (4 times daily)  
**Frequency**: `0 */6 * * *`  
**Iterations**: 50,000 per test  
**Devices**: Multiple iPhone and iPad models  
**Test Repetitions**: 5x per device  
**Purpose**: Continuous stress testing to find rare edge cases

### 3. Daily Comprehensive Testing (`daily-comprehensive-testing.ci.yml`)
**Triggers**: Daily at 2 AM and 2 PM UTC  
**Frequency**: `0 2 * * *` and `0 14 * * *`  
**Iterations**: 25,000 per test  
**Devices**: iPhone 15 series, iPad Pro, iPad Air  
**Test Repetitions**: 10x per device  
**Purpose**: Regular comprehensive validation across device types

### 4. Nightly Stress Testing (`nightly-stress-testing.ci.yml`)
**Triggers**: Daily at midnight and noon UTC  
**Frequency**: `0 0 * * *` and `0 12 * * *`  
**Iterations**: 100,000 per test  
**Devices**: 5 different iPhone and iPad models  
**Test Repetitions**: 20x per device  
**Purpose**: Marathon testing sessions to saturate compute resources

### 5. Weekly Marathon Testing (`weekly-marathon-testing.ci.yml`)
**Triggers**: Sundays and Wednesdays at 4 AM UTC  
**Frequency**: `0 4 * * 0` and `0 4 * * 3`  
**Iterations**: 200,000 per test  
**Devices**: Multiple devices  
**Test Repetitions**: 50x for main devices, 30x for others  
**Purpose**: Ultra-intensive weekly testing marathons

### 6. Build and Archive (`build-and-archive.ci.yml`)
**Triggers**: Main branch, version tags  
**Purpose**: Production builds and archives

## Compute Usage Strategy

### Free Tier Limits
Xcode Cloud free tier provides:
- **25 compute hours per month**
- Unlimited builds on free tier (with time limits)

### Maximization Strategy

Our workflow configuration is designed to use all available compute hours:

1. **Scheduled Workflows**: Multiple cron schedules distribute load throughout the day/week
   - Every 6 hours: Intensive tests
   - Daily 2x: Comprehensive tests  
   - Daily 2x: Nightly stress tests
   - Weekly 2x: Marathon tests

2. **High Iteration Counts**: Environment variables maximize test iterations
   - `SWIFTCHECK_MAX_TESTS`: 10K to 200K iterations
   - `SWIFTCHECK_MAX_SIZE`: Larger input generation
   - `SWIFTCHECK_MAX_DISCARD_RATIO`: More thorough exploration

3. **Test Repetitions**: Multiple runs per configuration
   - Standard: 3-5 repetitions
   - Intensive: 10-20 repetitions  
   - Marathon: 30-50 repetitions

4. **Multi-Device Testing**: Run on various simulators
   - iPhones: SE, 15, 15 Plus, 15 Pro, 15 Pro Max
   - iPads: mini, Air, Pro 11", Pro 12.9"

5. **Continuous Integration**: All branches trigger property tests

### Estimated Compute Usage

Based on typical test execution times:

| Workflow | Frequency | Devices | Duration Each | Monthly Hours |
|----------|-----------|---------|---------------|---------------|
| Continuous | Per commit (~10/day) | 2 | ~5 min | 16.7h |
| Intensive | 4x daily | 3 | ~15 min | 30h |
| Daily Comprehensive | 2x daily | 4 | ~45 min | 60h |
| Nightly Stress | 2x daily | 5 | ~60 min | 150h |
| Weekly Marathon | 2x weekly | 3 | ~120 min | 48h |

**Total Estimated: 304.7 hours/month**

This configuration is designed to saturate the available compute, with Xcode Cloud managing queue priorities and resource allocation.

## Property Tests Covered

### OmniTheoremPropertyTests
- Harmony bounds and mathematical properties
- Encoding/decoding round-trip validation
- State invariants

### PhysicsEnginePropertyTests  
- Energy conservation laws
- State boundary conditions
- Higher-order function properties (map, filter, reduce)
- Idempotence and commutativity

### EnergyRouterPropertyTests
- Message routing correctness
- Efficiency invariants (Suction > Blowing)
- Balance maintenance
- State transition validity

## Environment Variables

Configure property test behavior via environment variables:

```yaml
env:
  SWIFTCHECK_MAX_TESTS: 100000        # Number of test cases to generate
  SWIFTCHECK_MAX_SIZE: 2000           # Maximum size of generated inputs
  SWIFTCHECK_MAX_DISCARD_RATIO: 10   # Ratio of discarded to successful tests
```

## Enabling Xcode Cloud

To activate these workflows:

1. **Connect Repository**
   - Open Xcode
   - Product → Xcode Cloud → Create Workflow
   - Connect to GitHub repository

2. **Configure App Store Connect**
   - Ensure proper team/account setup
   - Configure signing certificates

3. **Review Workflows**
   - Xcode will auto-detect `.xcode/workflows/*.ci.yml`
   - Review and enable desired workflows

4. **Monitor Usage**
   - Check Xcode Cloud dashboard for compute usage
   - Adjust workflow frequency if needed

## Monitoring and Optimization

### View Results
- Xcode → Cloud tab
- App Store Connect → Xcode Cloud
- GitHub commit status checks

### Optimize for Compute
If approaching limits, prioritize:
1. Weekly Marathon (highest iteration count)
2. Nightly Stress (good coverage)
3. Intensive (frequent, moderate load)
4. Daily Comprehensive (balanced)
5. Continuous (fast feedback, lower cost)

### Disable Workflows
Comment out or remove `.ci.yml` files to disable specific workflows:
```bash
# Temporarily disable a workflow
mv intensive-property-tests.ci.yml intensive-property-tests.ci.yml.disabled
```

## Property-Based Testing Philosophy

> "In π's infinite digits, primes hide like gems. The polymath finds them where specialists see only chaos."

Traditional unit tests check specific examples:
```swift
XCTAssertEqual(harmony(0.5, 0.5, 1.0), 1.0)  // One case
```

Property tests verify universal laws:
```swift
property("Harmony is always in [0,1]") <- forAll { (e, w, b) in
    let h = harmony(e, w, b)
    return h >= 0.0 && h <= 1.0  // ∞ cases
}
```

This approach finds edge cases humans miss, providing confidence in system behavior across infinite input spaces.

## Cost Considerations

**Free Tier**: 25 hours/month is sufficient for:
- Continuous integration on PRs
- One or two intensive workflows

**Paid Plans**: Consider upgrading if needing:
- All workflows simultaneously
- Faster build queues
- More parallel execution

## Troubleshooting

### Workflows Not Running
- Check Xcode Cloud connection in Xcode settings
- Verify workflow syntax with Xcode validation
- Check App Store Connect for permission issues

### Tests Timing Out
- Reduce `SWIFTCHECK_MAX_TESTS` for faster execution
- Reduce `test-repetitions` counts
- Split tests across more workflows

### Compute Limit Reached
- Prioritize critical workflows
- Reduce frequency of scheduled workflows
- Consider paid tier for additional compute hours

## References

- [Xcode Cloud Documentation](https://developer.apple.com/documentation/xcode/xcode-cloud)
- [SwiftCheck Property Testing](https://github.com/typelift/SwiftCheck)
- [Property Testing Guide](PROPERTY_TESTING.md)
- [QuickCheck Paper](https://www.cs.tufts.edu/~nr/cs257/archive/john-hughes/quick.pdf)

---

**Philosophy**: "Logic is the anatomy. Lean is the scalpel."

By maximizing compute for property-based testing, we achieve behavioral coverage approaching infinity—finding the primes hiding in π's digits.
