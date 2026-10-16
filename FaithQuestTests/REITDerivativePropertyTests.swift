//
//  REITDerivativePropertyTests.swift
//  FaithQuestTests
//
//  Property tests for REIT multiples, cap-rate swaps, total-return swaps,
//  dividend-adjusted options, mortgage strips, and interest-rate swaps.
//

import XCTest
import SwiftCheck
@testable import FaithQuest

final class REITDerivativePropertyTests: XCTestCase {

    /// SwiftCheck's `<?>` operator binds tighter than comparison, so labels go through this helper.
    private func labeled(_ condition: Bool, _ message: String) -> Property {
        condition <?> message
    }

    private func unitInterval(_ value: Double) -> Double {
        guard value.isFinite else { return 0.5 }
        let normalized = abs(value).truncatingRemainder(dividingBy: 1.0)
        if normalized < 0.001 { return 0.001 }
        return min(normalized, 0.999)
    }

    private func positiveMoney(_ value: Double) -> Double {
        guard value.isFinite else { return 100 }
        let normalized = abs(value).truncatingRemainder(dividingBy: 1_000_000.0)
        return normalized < 1 ? 1 : normalized
    }

    private func sampleFundamentals(netIncome: Double,
                                     depreciation: Double,
                                     gains: Double,
                                     losses: Double,
                                     shares: Double,
                                     price: Double,
                                     portfolioNOI: Double) -> REITFundamentals? {
        REITFundamentals(
            netIncome: netIncome,
            realEstateDepreciationAndAmortization: depreciation,
            gainsOnPropertySales: gains,
            lossesOnPropertySales: losses,
            recurringCapitalExpenditures: 0,
            straightLineRentAdjustment: 0,
            dilutedShares: shares,
            annualDividendsPaid: 0,
            sharePrice: price,
            portfolioNOI: portfolioNOI,
            grossAssetValue: price * shares + 100,
            totalLiabilities: 50,
            totalDebt: 40,
            cash: 10
        )
    }

    func testFFOAdjustments() {
        property("FFO adds depreciation and losses and subtracts gains") <- forAll { (incomeRaw: Double, depreciationRaw: Double, gainRaw: Double, lossRaw: Double) in
            let income = self.unitInterval(incomeRaw) * 200 - 50
            let depreciation = self.positiveMoney(depreciationRaw) * 0.01
            let gains = self.positiveMoney(gainRaw) * 0.01
            let losses = self.positiveMoney(lossRaw) * 0.01
            guard let fundamentals = self.sampleFundamentals(
                netIncome: income,
                depreciation: depreciation,
                gains: gains,
                losses: losses,
                shares: 10,
                price: 20,
                portfolioNOI: 30
            ) else {
                return self.labeled(false, "Fundamentals should be valid")
            }
            let expected = income + depreciation + losses - gains
            return self.labeled(abs(fundamentals.fundsFromOperations - expected) < 1e-8, "FFO identity")
        }
    }

    func testImpliedCapRateIsNOIOverEnterpriseValue() {
        property("Implied cap rate times enterprise value recovers portfolio NOI") <- forAll { (noiRaw: Double, priceRaw: Double, sharesRaw: Double) in
            let noi = self.positiveMoney(noiRaw)
            let price = self.positiveMoney(priceRaw) + 1
            let shares = self.unitInterval(sharesRaw) * 100 + 1
            guard let fundamentals = self.sampleFundamentals(
                netIncome: 10,
                depreciation: 1,
                gains: 0,
                losses: 0,
                shares: shares,
                price: price,
                portfolioNOI: noi
            ), let implied = fundamentals.impliedCapRate else {
                return self.labeled(false, "Implied cap rate should be defined")
            }
            return self.labeled(abs(implied * fundamentals.enterpriseValue - noi) < 1e-6, "Implied cap-rate identity")
        }
    }

    func testPremiumIsZeroWhenPriceEqualsNAV() {
        property("Premium to NAV is zero when the share price equals NAV per share") <- forAll { (sharesRaw: Double, navRaw: Double) in
            let shares = self.unitInterval(sharesRaw) * 50 + 1
            let navPerShare = self.positiveMoney(navRaw) * 0.01 + 1
            let liabilities = 20.0
            let grossAssets = navPerShare * shares + liabilities
            guard let fundamentals = REITFundamentals(
                netIncome: 1,
                realEstateDepreciationAndAmortization: 0,
                gainsOnPropertySales: 0,
                lossesOnPropertySales: 0,
                recurringCapitalExpenditures: 0,
                straightLineRentAdjustment: 0,
                dilutedShares: shares,
                annualDividendsPaid: 0,
                sharePrice: navPerShare,
                portfolioNOI: 1,
                grossAssetValue: grossAssets,
                totalLiabilities: liabilities,
                totalDebt: 10,
                cash: 0
            ), let premium = fundamentals.premiumToNetAssetValue else {
                return self.labeled(false, "Premium should be defined")
            }
            return self.labeled(abs(premium) < 1e-8, "Price equal to NAV has no premium")
        }
    }

    func testCapRateSwapIsLinearAndOdd() {
        property("Cap-rate swap settlement scales with notional and flips with the spread") <- forAll { (notionalRaw: Double, fixedRaw: Double, floatingRaw: Double, yearRaw: Double) in
            let notional = self.positiveMoney(notionalRaw) + 1
            let fixed = self.unitInterval(fixedRaw) * 0.12
            let floating = self.unitInterval(floatingRaw) * 0.12
            let yearFraction = self.unitInterval(yearRaw) + 0.05
            guard let swap = CapRateSwap(notional: notional, fixedCapRate: fixed, yearFraction: yearFraction),
                  let doubled = CapRateSwap(notional: notional * 2, fixedCapRate: fixed, yearFraction: yearFraction),
                  let settlement = swap.fixedPayerSettlement(floatingCapRate: floating),
                  let doubledSettlement = doubled.fixedPayerSettlement(floatingCapRate: floating),
                  let opposite = swap.fixedPayerSettlement(floatingCapRate: fixed - (floating - fixed)) else {
                return self.labeled(false, "Swap should be defined")
            }
            let expected = notional * (floating - fixed) * yearFraction
            return self.labeled(abs(settlement - expected) < 1e-6, "Settlement formula") ^&&^
                self.labeled(abs(doubledSettlement - settlement * 2) < 1e-5, "Notional linearity") ^&&^
                self.labeled(abs(opposite + settlement) < 1e-5, "Odd in the spread")
        }
    }

    func testTotalReturnSwapIsFlatWhenAssetReturnMatchesFunding() {
        property("Total-return receiver payoff is zero when asset return equals funding accrual") <- forAll { (notionalRaw: Double, fundingRaw: Double, yearRaw: Double) in
            let notional = self.positiveMoney(notionalRaw) + 1
            let funding = self.unitInterval(fundingRaw) * 0.10
            let yearFraction = self.unitInterval(yearRaw) + 0.05
            guard let swap = REITTotalReturnSwap(
                notional: notional,
                fundingRate: funding,
                yearFraction: yearFraction
            ), let payoff = swap.receiverPayoff(assetTotalReturn: funding * yearFraction) else {
                return self.labeled(false, "Swap should be defined")
            }
            return self.labeled(abs(payoff) < 1e-6, "Funding match is a flat swap")
        }
    }

    func testCapitalReturnAgreesWithCapRateCompression() {
        property("Unchanged NOI makes capital return equal the cap-rate value change") <- forAll { (valueRaw: Double, startRaw: Double, endRaw: Double) in
            let startValue = self.positiveMoney(valueRaw) + 1_000
            let startCap = self.unitInterval(startRaw) * 0.10 + 0.03
            let endCap = self.unitInterval(endRaw) * 0.10 + 0.03
            let endValue = startValue * startCap / endCap
            guard let fromValues = PropertyTotalReturn.capitalReturn(startValue: startValue, endValue: endValue),
                  let fromCaps = PropertyTotalReturn.capitalReturnFromCapRates(
                    startCapRate: startCap,
                    endCapRate: endCap
                  ) else {
                return self.labeled(false, "Capital return should be defined")
            }
            return self.labeled(abs(fromValues - fromCaps) < 1e-8, "Cap-rate compression is the capital return")
        }
    }

    func testIncomePlusCapitalIsTotalReturn() {
        property("Total return is income return plus capital return") <- forAll { (incomeRaw: Double, capitalRaw: Double) in
            let income = self.unitInterval(incomeRaw) * 0.12
            let capital = self.unitInterval(capitalRaw) * 0.30 - 0.10
            guard let total = PropertyTotalReturn.totalReturn(incomeReturn: income, capitalReturn: capital) else {
                return self.labeled(false, "Total return should be defined")
            }
            return self.labeled(abs(total - (income + capital)) < 1e-12, "Return additivity")
        }
    }

    func testPutCallParity() {
        property("Call minus put equals the discounted forward difference") <- forAll { (spotRaw: Double, strikeRaw: Double, rateRaw: Double, yieldRaw: Double, volRaw: Double, timeRaw: Double) in
            let spot = self.positiveMoney(spotRaw) * 0.01 + 10
            let strike = self.positiveMoney(strikeRaw) * 0.01 + 10
            let rate = self.unitInterval(rateRaw) * 0.08
            let dividendYield = self.unitInterval(yieldRaw) * 0.08
            let volatility = self.unitInterval(volRaw) * 0.40 + 0.05
            let time = self.unitInterval(timeRaw) * 2.0 + 0.05
            guard let option = REITOption(
                spot: spot,
                strike: strike,
                timeToExpiry: time,
                riskFreeRate: rate,
                dividendYield: dividendYield,
                volatility: volatility
            ), let call = option.price(right: .call), let put = option.price(right: .put) else {
                return self.labeled(false, "Option should be priced")
            }
            let parity = spot * exp(-dividendYield * time) - strike * exp(-rate * time)
            return self.labeled(abs((call - put) - parity) < 1e-4, "Put-call parity")
        }
    }

    func testOptionPriceRespectsTheForwardLowerBound() {
        property("European REIT option prices stay above the discounted forward intrinsic value") <- forAll { (spotRaw: Double, strikeRaw: Double, volRaw: Double) in
            let spot = self.positiveMoney(spotRaw) * 0.01 + 20
            let strike = self.positiveMoney(strikeRaw) * 0.01 + 20
            let volatility = self.unitInterval(volRaw) * 0.50 + 0.01
            guard let option = REITOption(
                spot: spot,
                strike: strike,
                timeToExpiry: 1,
                riskFreeRate: 0.04,
                dividendYield: 0.035,
                volatility: volatility
            ), let call = option.price(right: .call), let put = option.price(right: .put) else {
                return self.labeled(false, "Option should be priced")
            }
            return self.labeled(call + 1e-6 >= option.discountedForwardIntrinsic(right: .call), "Call bound") ^&&^
                self.labeled(put + 1e-6 >= option.discountedForwardIntrinsic(right: .put), "Put bound") ^&&^
                self.labeled(call >= -1e-8, "Call is non-negative") ^&&^
                self.labeled(put >= -1e-8, "Put is non-negative")
        }
    }

    func testCallDeltaIsBetweenZeroAndTheDividendDiscount() {
        property("REIT call delta lies in (0, e^{-qT}]") <- forAll { (spotRaw: Double, strikeRaw: Double, yieldRaw: Double, volRaw: Double) in
            let spot = self.positiveMoney(spotRaw) * 0.01 + 10
            let strike = self.positiveMoney(strikeRaw) * 0.01 + 10
            let dividendYield = self.unitInterval(yieldRaw) * 0.08
            let volatility = self.unitInterval(volRaw) * 0.40 + 0.05
            let time = 1.0
            guard let option = REITOption(
                spot: spot,
                strike: strike,
                timeToExpiry: time,
                riskFreeRate: 0.03,
                dividendYield: dividendYield,
                volatility: volatility
            ), let delta = option.delta(right: .call) else {
                return self.labeled(false, "Delta should be defined")
            }
            let upper = exp(-dividendYield * time)
            return self.labeled(delta > 0, "Call delta is positive") ^&&^
                self.labeled(delta <= upper + 1e-8, "Call delta is at most the dividend discount")
        }
    }

    func testHigherDividendYieldLowersTheCall() {
        property("A higher REIT dividend yield lowers the European call") <- forAll { (yieldRaw: Double, otherRaw: Double) in
            let first = self.unitInterval(yieldRaw) * 0.08
            let second = self.unitInterval(otherRaw) * 0.08
            let low = min(first, second)
            let high = max(first, second)
            guard high - low > 0.002 else { return Discard() }
            guard let lowYield = REITOption(
                spot: 100,
                strike: 100,
                timeToExpiry: 1,
                riskFreeRate: 0.05,
                dividendYield: low,
                volatility: 0.20
            ), let highYield = REITOption(
                spot: 100,
                strike: 100,
                timeToExpiry: 1,
                riskFreeRate: 0.05,
                dividendYield: high,
                volatility: 0.20
            ), let lowCall = lowYield.price(right: .call), let highCall = highYield.price(right: .call) else {
                return self.labeled(false, "Calls should be priced")
            }
            return self.labeled(lowCall > highCall, "Dividend yield lowers the call")
        }
    }

    func testInterestAndPrincipalStripsSumToTheMortgage() {
        property("IO and PO present values sum to the mortgage present value") <- forAll { (principalRaw: Double, couponRaw: Double, discountRaw: Double) in
            let principal = self.positiveMoney(principalRaw)
            let coupon = self.unitInterval(couponRaw) * 0.12
            let discount = self.unitInterval(discountRaw) * 0.12
            guard let terms = MortgageTerms(
                principal: principal,
                annualInterestRate: coupon,
                amortizingYears: 5,
                paymentsPerYear: 1
            ), let strip = MortgageDerivativeStrip(terms: terms, annualDiscountRate: discount),
                  let values = strip.presentValues() else {
                return self.labeled(false, "Strip should be valued")
            }
            return self.labeled(abs(values.interestOnly + values.principalOnly - values.mortgage) < 1e-6, "IO + PO") ^&&^
                self.labeled(values.interestOnly >= -1e-8, "IO is non-negative") ^&&^
                self.labeled(values.principalOnly >= -1e-6, "PO is non-negative")
        }
    }

    func testMortgagePricesAtParWhenTheDiscountRateEqualsTheCoupon() {
        property("A mortgage prices at par when the discount rate equals the coupon") <- forAll { (principalRaw: Double, rateRaw: Double) in
            let principal = self.positiveMoney(principalRaw)
            let rate = self.unitInterval(rateRaw) * 0.12
            guard let terms = MortgageTerms(
                principal: principal,
                annualInterestRate: rate,
                amortizingYears: 4,
                paymentsPerYear: 2
            ), let strip = MortgageDerivativeStrip(terms: terms, annualDiscountRate: rate),
                  let values = strip.presentValues() else {
                return self.labeled(false, "Par mortgage should be valued")
            }
            return self.labeled(abs(values.mortgage - principal) < 1e-4, "Par mortgage value")
        }
    }

    func testSwapClosedFormMatchesForwardRates() {
        property("Interest-rate swap value from forwards matches the annuity closed form") <- forAll { (rateRaw: Double, firstRaw: Double, secondRaw: Double) in
            let fixed = self.unitInterval(rateRaw) * 0.08
            let first = 1.0 / (1.0 + self.unitInterval(firstRaw) * 0.05 + 0.005)
            let second = first / (1.0 + self.unitInterval(secondRaw) * 0.05 + 0.005)
            guard let curve = DiscountCurve(
                paymentDiscountFactors: [first, second],
                yearFractions: [1, 1]
            ), let swap = InterestRateSwap(notional: 1_000_000, fixedRate: fixed, curve: curve),
                  let closed = swap.fixedReceiverValue(),
                  let forwards = swap.fixedReceiverValueFromForwards() else {
                return self.labeled(false, "Swap should be valued")
            }
            return self.labeled(abs(closed - forwards) < 1e-6, "Forward and closed-form values agree")
        }
    }

    func testParSwapHasZeroValue() {
        property("A receiver swap struck at the par rate has zero value") <- forAll { (firstRaw: Double, secondRaw: Double, notionalRaw: Double) in
            let first = 1.0 / (1.0 + self.unitInterval(firstRaw) * 0.06 + 0.001)
            let second = first / (1.0 + self.unitInterval(secondRaw) * 0.06 + 0.001)
            let notional = self.positiveMoney(notionalRaw) + 1
            guard let curve = DiscountCurve(
                paymentDiscountFactors: [first, second],
                yearFractions: [0.5, 0.5]
            ), let par = curve.parSwapRate(),
                  let swap = InterestRateSwap(notional: notional, fixedRate: par, curve: curve),
                  let value = swap.fixedReceiverValue() else {
                return self.labeled(false, "Par swap should be valued")
            }
            return self.labeled(abs(value) < 1e-6, "Par swap value is zero")
        }
    }

    func testGordonPriceImpliedReturnRoundTrip() {
        property("Gordon growth price and implied return round-trip") <- forAll { (dividendRaw: Double, returnRaw: Double, growthRaw: Double) in
            let dividend = self.positiveMoney(dividendRaw) * 0.01 + 0.1
            let growth = self.unitInterval(growthRaw) * 0.05
            let required = growth + self.unitInterval(returnRaw) * 0.10 + 0.01
            guard let price = REITValuation.gordonGrowthPrice(
                nextDividend: dividend,
                requiredReturn: required,
                growthRate: growth
            ), let implied = REITValuation.gordonImpliedReturn(
                price: price,
                nextDividend: dividend,
                growthRate: growth
            ), let duration = REITValuation.perpetuityDuration(
                requiredReturn: required,
                growthRate: growth
            ) else {
                return self.labeled(false, "Gordon growth should be defined")
            }
            return self.labeled(abs(implied - required) < 1e-8, "Implied return") ^&&^
                self.labeled(abs(price * (required - growth) - dividend) < 1e-6, "Price identity") ^&&^
                self.labeled(abs(duration - 1.0 / (required - growth)) < 1e-8, "Perpetuity duration")
        }
    }
}
