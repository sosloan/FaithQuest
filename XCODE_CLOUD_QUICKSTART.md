# Xcode Cloud Compute Maximization Quick Start

## 🎯 Goal
Maximize Apple's free 25 hours/month of Xcode Cloud compute for intensive property-based testing ("ML training").

## 📊 Workflow Overview

```
Workflow Schedule & Intensity Map
═════════════════════════════════════════════════════════════

Daily Timeline (UTC):
00:00 ████ Nightly Stress (100K iterations)
02:00 ████ Daily Comprehensive (25K iterations)  
06:00 ████ Intensive (50K iterations)
12:00 ████ Nightly Stress (100K iterations)
14:00 ████ Daily Comprehensive (25K iterations)
18:00 ████ Intensive (50K iterations)

Weekly:
Sunday    04:00 ████████ Marathon (200K iterations)
Wednesday 04:00 ████████ Marathon (200K iterations)

Continuous:
Every commit ██ Continuous (10K iterations)
```

## 🚀 Workflows Created

| Name | Frequency | Iterations | Devices | Impact |
|------|-----------|------------|---------|--------|
| Continuous | Every push | 10K | 2 | ⚡ Fast |
| Intensive | Every 6h (4x/day) | 50K | 3 | ⚡⚡ Medium |
| Daily | 2x/day | 25K | 4 | ⚡⚡⚡ High |
| Nightly | 2x/day | 100K | 5 | ⚡⚡⚡⚡ Very High |
| Weekly | 2x/week | 200K | 3 | ⚡⚡⚡⚡⚡ Extreme |

## 🔧 Quick Setup

1. **Open Xcode**
   ```bash
   open FaithQuest.xcodeproj
   ```

2. **Connect to Xcode Cloud**
   - Product → Xcode Cloud → Create Workflow
   - Sign in with Apple ID
   - Select this repository

3. **Workflows Auto-Detected**
   - Xcode automatically finds `.xcode/workflows/*.ci.yml`
   - Custom scripts in `ci_scripts/` run automatically
   - Review and enable desired workflows

4. **Monitor Usage**
   - Xcode → Cloud tab
   - App Store Connect → Xcode Cloud

## 📜 Custom CI Scripts

The `ci_scripts/` directory contains build lifecycle scripts:

```
ci_scripts/
├── ci_post_clone.sh     # Environment setup after clone
├── ci_pre_xcodebuild.sh  # Pre-build configuration
├── ci_post_xcodebuild.sh # Post-build result processing
└── README.md             # Script documentation
```

These scripts automatically configure SwiftCheck environment variables and log test metrics.

## 📈 Expected Compute Usage

```
Monthly Estimate (304+ hours target):

Continuous:     ~17h  (10 commits/day × 5 min × 30 days)
Intensive:     ~30h  (4×/day × 15 min × 30 days)
Daily:         ~60h  (2×/day × 45 min × 30 days)  
Nightly:      ~150h  (2×/day × 60 min × 30 days)
Weekly:        ~48h  (2×/week × 120 min × 4 weeks)
────────────────────
TOTAL:        ~305h/month (theoretical demand)

Free Tier:      25h/month (actual allocation)
Target Demand: 1,220% of free tier

Note: This represents the theoretical compute demand across all 
workflows. Apple's Xcode Cloud automatically manages the queue 
and throttles execution to stay within your 25h/month free tier 
allocation. Workflows are queued and executed based on Apple's 
priority system.
```

## 🧪 What's Being Tested

**Property-Based Testing** with SwiftCheck:
- PhysicsEngine state transitions
- EnergyRouter message routing
- OmniTheorem harmony calculations
- Bounds checking (energy, wisdom, bridge strength)
- Conservation laws
- Mathematical invariants

Each property test generates **thousands to hundreds of thousands** of random test cases to find edge cases.

## 🎛️ Adjusting Compute

### Increase Usage
```bash
# Add more scheduled runs to workflows
vim .xcode/workflows/intensive-property-tests.ci.yml
# Add: - cron: '0 */3 * * *'  # Every 3 hours instead of 6
```

### Decrease Usage
```bash
# Disable a workflow temporarily
mv .xcode/workflows/nightly-stress-testing.ci.yml \
   .xcode/workflows/nightly-stress-testing.ci.yml.disabled
```

### Tune Iterations
Edit environment variables in workflow files:
```yaml
env:
  SWIFTCHECK_MAX_TESTS: 100000  # Increase/decrease
  SWIFTCHECK_MAX_SIZE: 2000     # Larger test inputs
```

## 📚 Documentation

- **Full Guide**: [XCODE_CLOUD.md](XCODE_CLOUD.md)
- **Workflow Details**: [.xcode/workflows/README.md](.xcode/workflows/README.md)
- **Property Testing**: [PROPERTY_TESTING.md](PROPERTY_TESTING.md)

## 🎓 Philosophy

> "In π's infinite digits, primes hide like gems. The polymath finds them where specialists see only chaos."

Property-based testing explores infinite input spaces like searching for primes in π—computationally intensive but mathematically comprehensive.

Traditional testing: 100 test cases = 100 validations  
Property testing with 200K iterations = ∞ behavioral coverage

## ⚠️ Important Notes

1. **Free Tier Limits**: 25h/month on free tier
2. **Queue Management**: Apple manages compute allocation
3. **Paid Upgrade**: Available for unlimited hours
4. **Compute Intensive**: These workflows are designed to saturate available resources
5. **Real ML Training**: Not included—this is for property test "training"

## 🔍 Monitoring

Check workflow status:
```bash
# In Xcode
Product → Xcode Cloud → Workflow History

# Or visit App Store Connect
https://appstoreconnect.apple.com/
```

## 🆘 Troubleshooting

**Workflows not running?**
- Check Xcode Cloud connection
- Verify YAML syntax: `yamllint .xcode/workflows/*.ci.yml`
- Review App Store Connect permissions

**Hitting compute limits?**
- Reduce workflow frequency
- Lower `SWIFTCHECK_MAX_TESTS` values
- Disable less critical workflows
- Consider paid tier

---

**Status**: ✅ Ready to maximize compute for property-based testing!
