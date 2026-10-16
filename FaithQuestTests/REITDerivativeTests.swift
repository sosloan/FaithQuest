//
//  REITDerivativeTests.swift
//  FaithQuestTests
//
//  Unit tests for REIT multiples and derivative payoffs.
//

import XCTest
@testable import FaithQuest

final class REITDerivativeTests: XCTestCase {

    private func sampleFundamentals() -> REITFundamentals {
        REITFundamentals(
            netIncome: 100,
            realEstateDepreciationAndAmortization: 40,
            gainsOnPropertySales: 15,
            lossesOnPropertySales: 5,
            recurringCapitalExpenditures: 10,
            straightLineRentAdjustment: 4,
            dilutedShares: 50,
            annualDividendsPaid: 80,
            sharePrice: 26,
            portfolioNOI: 117,
            grossAssetValue: 2_000,
            totalLiabilities: 800,
            totalDebt: 700,
            cash: 50
        )!
    }

    // MARK: - REIT Fundamentals

    func testFFOAndAFFOBuildUp() {
        // Given
        let fundamentals = sampleFundamentals()

        // Then
        // FFO = 100 + 40 + 5 - 15 = 130
        // AFFO = 130 - 10 - 4 = 116
        XCTAssertEqual(fundamentals.fundsFromOperations, 130, accuracy: 1e-12)
        XCTAssertEqual(fundamentals.adjustedFundsFromOperations, 116, accuracy: 1e-12)
        XCTAssertEqual(fundamentals.fundsFromOperationsPerShare, 2.60, accuracy: 1e-12)
        XCTAssertEqual(fundamentals.adjustedFundsFromOperationsPerShare, 2.32, accuracy: 1e-12)
    }

    func testFFOEqualsNetIncomeWhenThereAreNoAdjustments() {
        // Given
        let fundamentals = REITFundamentals(
            netIncome: 42,
            realEstateDepreciationAndAmortization: 0,
            gainsOnPropertySales: 0,
            lossesOnPropertySales: 0,
            recurringCapitalExpenditures: 0,
            straightLineRentAdjustment: 0,
            dilutedShares: 10,
            annualDividendsPaid: 10,
            sharePrice: 20,
            portfolioNOI: 30,
            grossAssetValue: 100,
            totalLiabilities: 40,
            totalDebt: 30,
            cash: 5
        )!

        // Then
        XCTAssertEqual(fundamentals.fundsFromOperations, fundamentals.netIncome, accuracy: 1e-12)
        XCTAssertEqual(fundamentals.adjustedFundsFromOperations, fundamentals.fundsFromOperations, accuracy: 1e-12)
    }

    func testGainsReduceFFOAndLossesIncreaseIt() {
        // Given
        let withGain = REITFundamentals(
            netIncome: 100,
            realEstateDepreciationAndAmortization: 0,
            gainsOnPropertySales: 20,
            lossesOnPropertySales: 0,
            recurringCapitalExpenditures: 0,
            straightLineRentAdjustment: 0,
            dilutedShares: 10,
            annualDividendsPaid: 1,
            sharePrice: 10,
            portfolioNOI: 10,
            grossAssetValue: 100,
            totalLiabilities: 0,
            totalDebt: 0,
            cash: 0
        )!
        let withLoss = REITFundamentals(
            netIncome: 100,
            realEstateDepreciationAndAmortization: 0,
            gainsOnPropertySales: 0,
            lossesOnPropertySales: 20,
            recurringCapitalExpenditures: 0,
            straightLineRentAdjustment: 0,
            dilutedShares: 10,
            annualDividendsPaid: 1,
            sharePrice: 10,
            portfolioNOI: 10,
            grossAssetValue: 100,
            totalLiabilities: 0,
            totalDebt: 0,
            cash: 0
        )!

        // Then
        XCTAssertEqual(withGain.fundsFromOperations, 80, accuracy: 1e-12)
        XCTAssertEqual(withLoss.fundsFromOperations, 120, accuracy: 1e-12)
    }

    func testPerShareMultiplesDividendYieldAndPayout() {
        // Given
        let fundamentals = sampleFundamentals()

        // Then
        XCTAssertEqual(fundamentals.priceToFundsFromOperations, 10, accuracy: 1e-12)
        XCTAssertEqual(fundamentals.dividendPerShare, 1.60, accuracy: 1e-12)
        XCTAssertEqual(fundamentals.dividendYield, 1.60 / 26.0, accuracy: 1e-12)
        XCTAssertEqual(fundamentals.adjustedFundsPayoutRatio, 80.0 / 116.0, accuracy: 1e-12)
    }

    func testPayoutRatioCanExceedOne() {
        // Given
        let fundamentals = REITFundamentals(
            netIncome: 10,
            realEstateDepreciationAndAmortization: 0,
            gainsOnPropertySales: 0,
            lossesOnPropertySales: 0,
            recurringCapitalExpenditures: 0,
            straightLineRentAdjustment: 0,
            dilutedShares: 10,
            annualDividendsPaid: 15,
            sharePrice: 20,
            portfolioNOI: 10,
            grossAssetValue: 100,
            totalLiabilities: 0,
            totalDebt: 0,
            cash: 0
        )!

        // Then
        XCTAssertEqual(fundamentals.adjustedFundsPayoutRatio, 1.5, accuracy: 1e-12)
    }

    func testNAVPremiumAndImpliedCapRate() {
        // Given
        let fundamentals = sampleFundamentals()

        // Then
        // NAV = 2,000 - 800 = 1,200; NAV/share = 24; premium = (26 - 24) / 24
        // Equity market cap = 1,300; net debt = 650; EV = 1,950; implied cap = 117 / 1,950
        XCTAssertEqual(fundamentals.netAssetValue, 1_200, accuracy: 1e-12)
        XCTAssertEqual(fundamentals.netAssetValuePerShare, 24, accuracy: 1e-12)
        XCTAssertEqual(fundamentals.premiumToNetAssetValue, (26.0 - 24.0) / 24.0, accuracy: 1e-12)
        XCTAssertEqual(fundamentals.equityMarketCapitalization, 1_300, accuracy: 1e-12)
        XCTAssertEqual(fundamentals.netDebt, 650, accuracy: 1e-12)
        XCTAssertEqual(fundamentals.enterpriseValue, 1_950, accuracy: 1e-12)
        XCTAssertEqual(fundamentals.impliedCapRate, 117.0 / 1_950.0, accuracy: 1e-12)
    }

    func testPriceBelowNAVIsADiscount() {
        // Given
        let fundamentals = REITFundamentals(
            netIncome: 10,
            realEstateDepreciationAndAmortization: 0,
            gainsOnPropertySales: 0,
            lossesOnPropertySales: 0,
            recurringCapitalExpenditures: 0,
            straightLineRentAdjustment: 0,
            dilutedShares: 10,
            annualDividendsPaid: 4,
            sharePrice: 18,
            portfolioNOI: 12,
            grossAssetValue: 300,
            totalLiabilities: 50,
            totalDebt: 40,
            cash: 10
        )!

        // Then - NAV/share = 25, so the premium is negative
        XCTAssertEqual(fundamentals.netAssetValuePerShare, 25, accuracy: 1e-12)
        XCTAssertLessThan(fundamentals.premiumToNetAssetValue!, 0)
        XCTAssertEqual(fundamentals.premiumToNetAssetValue, (18.0 - 25.0) / 25.0, accuracy: 1e-12)
    }

    func testPremiumUndefinedWhenNAVIsNotPositive() {
        // Given
        let fundamentals = REITFundamentals(
            netIncome: 1,
            realEstateDepreciationAndAmortization: 0,
            gainsOnPropertySales: 0,
            lossesOnPropertySales: 0,
            recurringCapitalExpenditures: 0,
            straightLineRentAdjustment: 0,
            dilutedShares: 10,
            annualDividendsPaid: 1,
            sharePrice: 5,
            portfolioNOI: 1,
            grossAssetValue: 100,
            totalLiabilities: 100,
            totalDebt: 80,
            cash: 0
        )!

        // Then
        XCTAssertEqual(fundamentals.netAssetValue, 0, accuracy: 1e-12)
        XCTAssertNil(fundamentals.premiumToNetAssetValue)
    }

    func testPriceToFFOUndefinedWhenFFOIsNotPositive() {
        // Given
        let fundamentals = REITFundamentals(
            netIncome: 5,
            realEstateDepreciationAndAmortization: 0,
            gainsOnPropertySales: 5,
            lossesOnPropertySales: 0,
            recurringCapitalExpenditures: 0,
            straightLineRentAdjustment: 0,
            dilutedShares: 10,
            annualDividendsPaid: 0,
            sharePrice: 12,
            portfolioNOI: 8,
            grossAssetValue: 100,
            totalLiabilities: 20,
            totalDebt: 20,
            cash: 0
        )!

        // Then
        XCTAssertEqual(fundamentals.fundsFromOperations, 0, accuracy: 1e-12)
        XCTAssertNil(fundamentals.priceToFundsFromOperations)
        XCTAssertNil(fundamentals.adjustedFundsPayoutRatio)
    }

    // MARK: - Cap Rate Swap and Total Return Swap

    func testCapRateSwapSettlement() {
        // Given
        let swap = CapRateSwap(notional: 10_000_000, fixedCapRate: 0.055, yearFraction: 0.5)!

        // When
        let settlement = swap.fixedPayerSettlement(floatingCapRate: 0.062)!

        // Then - 10,000,000 * 0.007 * 0.5 = 35,000
        XCTAssertEqual(settlement, 35_000, accuracy: 1e-8)
    }

    func testCapRateSwapIsZeroWhenRatesMatchAndOddInTheSpread() {
        // Given
        let swap = CapRateSwap(notional: 2_000_000, fixedCapRate: 0.06, yearFraction: 1)!

        // Then
        XCTAssertEqual(swap.fixedPayerSettlement(floatingCapRate: 0.06), 0, accuracy: 1e-12)
        let above = swap.fixedPayerSettlement(floatingCapRate: 0.07)!
        let below = swap.fixedPayerSettlement(floatingCapRate: 0.05)!
        XCTAssertEqual(above, -below, accuracy: 1e-9)
        XCTAssertGreaterThan(above, 0)
    }

    func testShortCapRateSwapFlipsTheSettlement() {
        // Given
        let long = CapRateSwap(notional: 1_000_000, fixedCapRate: 0.05, yearFraction: 1)!
        let short = CapRateSwap(notional: -1_000_000, fixedCapRate: 0.05, yearFraction: 1)!

        // Then
        XCTAssertEqual(
            long.fixedPayerSettlement(floatingCapRate: 0.07)!,
            -short.fixedPayerSettlement(floatingCapRate: 0.07)!,
            accuracy: 1e-9
        )
    }

    func testTotalReturnComponents() {
        // Given
        let income = PropertyTotalReturn.incomeReturn(netOperatingIncome: 55_000, startValue: 1_000_000)!
        let capital = PropertyTotalReturn.capitalReturn(startValue: 1_000_000, endValue: 1_040_000)!
        let total = PropertyTotalReturn.totalReturn(incomeReturn: income, capitalReturn: capital)!

        // Then
        XCTAssertEqual(income, 0.055, accuracy: 1e-12)
        XCTAssertEqual(capital, 0.04, accuracy: 1e-12)
        XCTAssertEqual(total, 0.095, accuracy: 1e-12)
    }

    func testCapitalReturnMatchesCapRateCompression() {
        // Given - unchanged NOI, cap rate moves from 8% to 6%
        let startCapRate = 0.08
        let endCapRate = 0.06
        let startValue = 1_000_000.0
        let endValue = startValue * startCapRate / endCapRate

        // When
        let fromValues = PropertyTotalReturn.capitalReturn(startValue: startValue, endValue: endValue)!
        let fromCaps = PropertyTotalReturn.capitalReturnFromCapRates(
            startCapRate: startCapRate,
            endCapRate: endCapRate
        )!

        // Then
        XCTAssertEqual(fromValues, fromCaps, accuracy: 1e-12)
        XCTAssertEqual(fromCaps, (0.08 / 0.06) - 1.0, accuracy: 1e-12)
    }

    func testTotalReturnSwapPayoff() {
        // Given
        let swap = REITTotalReturnSwap(notional: 1_000_000, fundingRate: 0.05, yearFraction: 1)!
        let assetReturn = PropertyTotalReturn.totalReturn(incomeReturn: 0.055, capitalReturn: 0.04)!

        // Then - receiver earns 9.5% and pays 5%
        XCTAssertEqual(swap.receiverPayoff(assetTotalReturn: assetReturn), 45_000, accuracy: 1e-8)
        XCTAssertEqual(swap.receiverPayoff(assetTotalReturn: 0.05), 0, accuracy: 1e-8)
    }

    func testTotalReturnSwapFundingAccruesWithTheYearFraction() {
        // Given
        let swap = REITTotalReturnSwap(notional: 1_000_000, fundingRate: 0.04, yearFraction: 0.25)!

        // Then - funding leg is 1%, so a 1% asset return is flat
        XCTAssertEqual(swap.receiverPayoff(assetTotalReturn: 0.01), 0, accuracy: 1e-8)
        XCTAssertEqual(swap.receiverPayoff(assetTotalReturn: 0), -10_000, accuracy: 1e-8)
    }

    // MARK: - REIT Equity Options

    func testBlackScholesCallKnownValueWithoutDividend() {
        // Given - S = K = 100, r = 5%, q = 0, sigma = 20%, T = 1
        let option = REITOption(
            spot: 100,
            strike: 100,
            timeToExpiry: 1,
            riskFreeRate: 0.05,
            dividendYield: 0,
            volatility: 0.20
        )!

        // Then
        XCTAssertEqual(option.price(right: .call), 10.450583572185565, accuracy: 1e-4)
        XCTAssertEqual(option.price(right: .put), 5.573526022256971, accuracy: 1e-4)
        XCTAssertEqual(option.delta(right: .call), 0.6368306511756191, accuracy: 1e-4)
        XCTAssertEqual(option.delta(right: .put), -0.3631693488243809, accuracy: 1e-4)
    }

    func testREITCallWithDividendYield() {
        // Given - same terms as the zero-yield case, plus a 3% REIT dividend yield
        let option = REITOption(
            spot: 100,
            strike: 100,
            timeToExpiry: 1,
            riskFreeRate: 0.05,
            dividendYield: 0.03,
            volatility: 0.20
        )!

        // Then
        XCTAssertEqual(option.price(right: .call), 8.652528553942709, accuracy: 1e-4)
        XCTAssertEqual(option.price(right: .put), 6.7309176491633025, accuracy: 1e-4)
        XCTAssertEqual(option.delta(right: .call), 0.5621399977897841, accuracy: 1e-4)
        XCTAssertEqual(option.delta(right: .put), -0.408305535758724, accuracy: 1e-4)
    }

    func testPutCallParity() {
        // Given
        let option = REITOption(
            spot: 50,
            strike: 55,
            timeToExpiry: 0.75,
            riskFreeRate: 0.04,
            dividendYield: 0.045,
            volatility: 0.25
        )!
        let call = option.price(right: .call)!
        let put = option.price(right: .put)!
        let parity = option.spot * exp(-option.dividendYield * option.timeToExpiry)
            - option.strike * exp(-option.riskFreeRate * option.timeToExpiry)

        // Then - call - put = S e^{-qT} - K e^{-rT}
        XCTAssertEqual(call - put, parity, accuracy: 1e-6)
        XCTAssertEqual(call, 2.316101481902402, accuracy: 1e-4)
        XCTAssertEqual(put, 7.349946940993203, accuracy: 1e-4)
    }

    func testDividendYieldLowersCallAndRaisesPut() {
        // Given
        func priced(yield: Double) -> REITOption {
            REITOption(
                spot: 100,
                strike: 100,
                timeToExpiry: 1,
                riskFreeRate: 0.05,
                dividendYield: yield,
                volatility: 0.20
            )!
        }
        let lowYield = priced(yield: 0)
        let reitYield = priced(yield: 0.04)

        // Then
        XCTAssertGreaterThan(lowYield.price(right: .call)!, reitYield.price(right: .call)!)
        XCTAssertLessThan(lowYield.price(right: .put)!, reitYield.price(right: .put)!)
    }

    func testHigherVolatilityRaisesBothPremiums() {
        // Given
        func priced(volatility: Double) -> REITOption {
            REITOption(
                spot: 100,
                strike: 105,
                timeToExpiry: 0.5,
                riskFreeRate: 0.03,
                dividendYield: 0.04,
                volatility: volatility
            )!
        }
        let calm = priced(volatility: 0.15)
        let stressed = priced(volatility: 0.35)

        // Then - European call and put vegas are equal and positive here
        XCTAssertGreaterThan(stressed.price(right: .call)!, calm.price(right: .call)!)
        XCTAssertGreaterThan(stressed.price(right: .put)!, calm.price(right: .put)!)
        let calmVegaGap = calm.price(right: .call)! - calm.price(right: .put)!
        let stressedVegaGap = stressed.price(right: .call)! - stressed.price(right: .put)!
        XCTAssertEqual(calmVegaGap, stressedVegaGap, accuracy: 1e-6)
    }

    func testEuropeanCallCanTradeBelowUndiscountedIntrinsicWhenYieldIsHigh() {
        // Given - a high REIT yield pulls the European call below S - K
        let option = REITOption(
            spot: 100,
            strike: 80,
            timeToExpiry: 1,
            riskFreeRate: 0.01,
            dividendYield: 0.12,
            volatility: 0.15
        )!
        let call = option.price(right: .call)!

        // Then
        XCTAssertLessThan(call, option.intrinsicValue(right: .call))
        XCTAssertGreaterThanOrEqual(call, option.discountedForwardIntrinsic(right: .call) - 1e-8)
    }

    func testExpiryIsIntrinsicAndZeroVolatilityIsTheForwardBound() {
        // Given
        let expired = REITOption(
            spot: 90,
            strike: 100,
            timeToExpiry: 0,
            riskFreeRate: 0.05,
            dividendYield: 0.04,
            volatility: 0.20
        )!
        let certain = REITOption(
            spot: 100,
            strike: 90,
            timeToExpiry: 1,
            riskFreeRate: 0.05,
            dividendYield: 0.04,
            volatility: 0
        )!

        // Then
        XCTAssertEqual(expired.price(right: .call), 0, accuracy: 1e-12)
        XCTAssertEqual(expired.price(right: .put), 10, accuracy: 1e-12)
        XCTAssertNil(expired.delta(right: .call))
        let forwardCall = 100 * exp(-0.04) - 90 * exp(-0.05)
        XCTAssertEqual(certain.price(right: .call), forwardCall, accuracy: 1e-10)
        XCTAssertEqual(certain.price(right: .put), 0, accuracy: 1e-10)
    }

    func testCallPriceStaysAboveTheDiscountedForwardBound() {
        // Given
        let option = REITOption(
            spot: 100,
            strike: 100,
            timeToExpiry: 1,
            riskFreeRate: 0.05,
            dividendYield: 0.03,
            volatility: 0.20
        )!

        // Then
        XCTAssertGreaterThanOrEqual(
            option.price(right: .call)!,
            option.discountedForwardIntrinsic(right: .call) - 1e-8
        )
        XCTAssertGreaterThanOrEqual(
            option.price(right: .put)!,
            option.discountedForwardIntrinsic(right: .put) - 1e-8
        )
    }

    // MARK: - Mortgage Strips and Interest Rate Swaps

    func testIOAndPOSumToTheMortgageAndPriceAtPar() {
        // Given - two annual payments, coupon equals the discount rate
        let terms = MortgageTerms(
            principal: 1_000,
            annualInterestRate: 0.10,
            amortizingYears: 2,
            paymentsPerYear: 1
        )!
        let strip = MortgageDerivativeStrip(terms: terms, annualDiscountRate: 0.10)!
        let values = strip.presentValues()!
        let payment = terms.periodicPayment()

        // Then
        // Interest = 100 then 52.380952; principal = 476.190476 then 523.809524
        let firstDiscount = 1.0 / 1.10
        let secondDiscount = 1.0 / 1.21
        let expectedInterestOnly = 100.0 * firstDiscount + (1_000.0 - (payment - 100.0)) * 0.10 * secondDiscount
        XCTAssertEqual(values.interestOnly + values.principalOnly, values.mortgage, accuracy: 1e-9)
        XCTAssertEqual(values.mortgage, 1_000, accuracy: 1e-8)
        XCTAssertEqual(values.interestOnly, expectedInterestOnly, accuracy: 1e-6)
    }

    func testZeroCouponMortgageHasAWorthlessInterestStrip() {
        // Given
        let terms = MortgageTerms(
            principal: 1_200,
            annualInterestRate: 0,
            amortizingYears: 2,
            paymentsPerYear: 1
        )!
        let strip = MortgageDerivativeStrip(terms: terms, annualDiscountRate: 0.10)!
        let values = strip.presentValues()!

        // Then - each principal payment is 600
        XCTAssertEqual(values.interestOnly, 0, accuracy: 1e-12)
        XCTAssertEqual(values.principalOnly, 600 / 1.10 + 600 / 1.21, accuracy: 1e-8)
        XCTAssertEqual(values.mortgage, values.principalOnly, accuracy: 1e-12)
    }

    func testUndiscountedStripEqualsTotalPayments() {
        // Given
        let terms = MortgageTerms(
            principal: 1_000,
            annualInterestRate: 0.10,
            amortizingYears: 2,
            paymentsPerYear: 1
        )!
        let strip = MortgageDerivativeStrip(terms: terms, annualDiscountRate: 0)!
        let values = strip.presentValues()!

        // Then
        XCTAssertEqual(values.mortgage, terms.periodicPayment() * 2.0, accuracy: 1e-8)
        XCTAssertGreaterThan(values.mortgage, terms.principal)
    }

    func testParSwapRateAndZeroValue() {
        // Given
        let curve = DiscountCurve(
            paymentDiscountFactors: [0.97, 0.94, 0.90],
            yearFractions: [1, 1, 1]
        )!
        let parRate = curve.parSwapRate()!
        let swap = InterestRateSwap(notional: 1_000_000, fixedRate: parRate, curve: curve)!

        // Then - (1 - 0.90) / 2.81
        XCTAssertEqual(parRate, 0.10 / 2.81, accuracy: 1e-12)
        XCTAssertEqual(swap.fixedReceiverValue(), 0, accuracy: 1e-8)
        XCTAssertEqual(swap.fixedReceiverValueFromForwards(), swap.fixedReceiverValue()!, accuracy: 1e-8)
    }

    func testSwapValueMatchesTheAnnuityFormula() {
        // Given
        let curve = DiscountCurve(
            paymentDiscountFactors: [0.97, 0.94, 0.90],
            yearFractions: [1, 1, 1]
        )!
        let swap = InterestRateSwap(notional: 1_000_000, fixedRate: 0.04, curve: curve)!

        // Then
        XCTAssertEqual(swap.fixedReceiverValue(), 12_400, accuracy: 1e-6)
        XCTAssertEqual(curve.forwardRates()![0], (1.0 / 0.97) - 1.0, accuracy: 1e-12)
        XCTAssertEqual(curve.forwardRates()![1], (0.97 / 0.94) - 1.0, accuracy: 1e-12)
        XCTAssertEqual(curve.forwardRates()![2], (0.94 / 0.90) - 1.0, accuracy: 1e-12)
    }

    func testFixedReceiverLosesWhenTheFixedRateIsBelowForwards() {
        // Given
        let curve = DiscountCurve(paymentDiscountFactors: [0.97], yearFractions: [1])!
        let rich = InterestRateSwap(notional: 1_000_000, fixedRate: 0.05, curve: curve)!
        let cheap = InterestRateSwap(notional: 1_000_000, fixedRate: 0.01, curve: curve)!

        // Then
        XCTAssertGreaterThan(rich.fixedReceiverValue()!, 0)
        XCTAssertLessThan(cheap.fixedReceiverValue()!, 0)
    }

    // MARK: - Gordon Growth

    func testGordonGrowthPriceImpliedReturnAndDuration() {
        // Given
        let price = REITValuation.gordonGrowthPrice(
            nextDividend: 2,
            requiredReturn: 0.09,
            growthRate: 0.03
        )!
        let implied = REITValuation.gordonImpliedReturn(price: price, nextDividend: 2, growthRate: 0.03)!
        let duration = REITValuation.perpetuityDuration(requiredReturn: 0.09, growthRate: 0.03)!

        // Then - price = 2 / 0.06; duration = 1 / 0.06
        XCTAssertEqual(price, 2.0 / 0.06, accuracy: 1e-12)
        XCTAssertEqual(implied, 0.09, accuracy: 1e-12)
        XCTAssertEqual(duration, price / 2.0, accuracy: 1e-12)
    }

    func testGordonGrowthRejectsARequiredReturnThatDoesNotExceedGrowth() {
        XCTAssertNil(REITValuation.gordonGrowthPrice(nextDividend: 2, requiredReturn: 0.03, growthRate: 0.03))
        XCTAssertNil(REITValuation.gordonGrowthPrice(nextDividend: 2, requiredReturn: 0.02, growthRate: 0.03))
        XCTAssertNil(REITValuation.perpetuityDuration(requiredReturn: 0.04, growthRate: 0.05))
    }

    // MARK: - Edge Cases

    func testDerivativeInputsRejectNonFiniteOrEmptyTerms() {
        XCTAssertNil(CapRateSwap(notional: 0, fixedCapRate: 0.05, yearFraction: 1))
        XCTAssertNil(CapRateSwap(notional: 1, fixedCapRate: -0.01, yearFraction: 1))
        XCTAssertNil(CapRateSwap(notional: 1, fixedCapRate: 0.05, yearFraction: 0))
        XCTAssertNil(REITTotalReturnSwap(notional: .nan, fundingRate: 0.01, yearFraction: 1))
        XCTAssertNil(REITOption(
            spot: 0,
            strike: 100,
            timeToExpiry: 1,
            riskFreeRate: 0.01,
            dividendYield: 0.04,
            volatility: 0.2
        ))
        XCTAssertNil(REITOption(
            spot: 100,
            strike: 100,
            timeToExpiry: 1,
            riskFreeRate: 0.01,
            dividendYield: 0.04,
            volatility: -0.1
        ))
        XCTAssertNil(DiscountCurve(paymentDiscountFactors: [], yearFractions: []))
        XCTAssertNil(DiscountCurve(paymentDiscountFactors: [0.9], yearFractions: [1, 1]))
        XCTAssertNil(DiscountCurve(paymentDiscountFactors: [0], yearFractions: [1]))
        XCTAssertNil(REITFundamentals(
            netIncome: 1,
            realEstateDepreciationAndAmortization: -1,
            gainsOnPropertySales: 0,
            lossesOnPropertySales: 0,
            recurringCapitalExpenditures: 0,
            straightLineRentAdjustment: 0,
            dilutedShares: 1,
            annualDividendsPaid: 0,
            sharePrice: 1,
            portfolioNOI: 1,
            grossAssetValue: 1,
            totalLiabilities: 0,
            totalDebt: 0,
            cash: 0
        ))
    }

    func testCapRateSwapRejectsANonFiniteFloatingRate() {
        let swap = CapRateSwap(notional: 1_000_000, fixedCapRate: 0.05, yearFraction: 1)!
        XCTAssertNil(swap.fixedPayerSettlement(floatingCapRate: .infinity))
        XCTAssertNil(PropertyTotalReturn.capitalReturn(startValue: 0, endValue: 10))
        XCTAssertNil(PropertyTotalReturn.totalReturn(incomeReturn: .nan, capitalReturn: 0.01))
    }
}
