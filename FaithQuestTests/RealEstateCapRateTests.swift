//
//  RealEstateCapRateTests.swift
//  FaithQuestTests
//
//  Unit tests for cap-rate mathematics and direct real-estate investing.
//

import XCTest
@testable import FaithQuest

final class RealEstateCapRateTests: XCTestCase {

    // MARK: - Cap Rate Identities

    func testCapRateFromNOIAndValue() {
        // Given
        let netOperatingIncome = 60_000.0
        let propertyValue = 1_000_000.0

        // When
        let capRate = CapRateMath.capRate(
            netOperatingIncome: netOperatingIncome,
            propertyValue: propertyValue
        )

        // Then - 60,000 / 1,000,000 = 6%
        XCTAssertEqual(capRate, 0.06, accuracy: 1e-12)
    }

    func testPropertyValueFromCapRate() {
        // Given
        let netOperatingIncome = 80_000.0
        let capRate = 0.08

        // When
        let value = CapRateMath.propertyValue(netOperatingIncome: netOperatingIncome, capRate: capRate)

        // Then - 80,000 / 0.08 = 1,000,000
        XCTAssertEqual(value, 1_000_000.0, accuracy: 1e-6)
    }

    func testCapRateAndValueAreInverses() {
        // Given
        let netOperatingIncome = 125_000.0
        let capRate = 0.055

        // When
        let value = CapRateMath.propertyValue(netOperatingIncome: netOperatingIncome, capRate: capRate)!
        let recoveredCapRate = CapRateMath.capRate(netOperatingIncome: netOperatingIncome, propertyValue: value)!
        let recoveredNOI = value * recoveredCapRate

        // Then
        XCTAssertEqual(recoveredCapRate, capRate, accuracy: 1e-12)
        XCTAssertEqual(recoveredNOI, netOperatingIncome, accuracy: 1e-6)
    }

    func testCapRateCompressionRaisesValue() {
        // Given - NOI held at 80,000 while the cap rate moves from 8% to 6%
        let netOperatingIncome = 80_000.0
        let startValue = CapRateMath.propertyValue(netOperatingIncome: netOperatingIncome, capRate: 0.08)!
        let endValue = CapRateMath.propertyValue(netOperatingIncome: netOperatingIncome, capRate: 0.06)!

        // When
        let valueChange = CapRateMath.valueChangeFromCapRateMove(startCapRate: 0.08, endCapRate: 0.06)!

        // Then - 0.08 / 0.06 - 1 = 1/3
        XCTAssertEqual(valueChange, (0.08 / 0.06) - 1.0, accuracy: 1e-12)
        XCTAssertEqual((endValue - startValue) / startValue, valueChange, accuracy: 1e-12)
        XCTAssertGreaterThan(endValue, startValue)
    }

    func testCapRateExpansionLowersValue() {
        // Given
        let change = CapRateMath.valueChangeFromCapRateMove(startCapRate: 0.05, endCapRate: 0.07)!

        // Then - 0.05 / 0.07 - 1 is negative
        XCTAssertEqual(change, (0.05 / 0.07) - 1.0, accuracy: 1e-12)
        XCTAssertLessThan(change, 0)
    }

    func testCapRateValueChangeRoundTrip() {
        // Given
        let startCapRate = 0.065
        let endCapRate = 0.05

        // When
        let valueChange = CapRateMath.valueChangeFromCapRateMove(
            startCapRate: startCapRate,
            endCapRate: endCapRate
        )!
        let recovered = CapRateMath.capRateAfterValueChange(
            startCapRate: startCapRate,
            valueChange: valueChange
        )!

        // Then
        XCTAssertEqual(recovered, endCapRate, accuracy: 1e-12)
    }

    func testValueSensitivityMatchesCentralDifference() {
        // Given
        let netOperatingIncome = 80_000.0
        let capRate = 0.08
        let step = 0.0001

        // When
        let analytic = CapRateMath.valueSensitivityToCapRate(
            netOperatingIncome: netOperatingIncome,
            capRate: capRate
        )!
        let up = CapRateMath.propertyValue(netOperatingIncome: netOperatingIncome, capRate: capRate + step)!
        let down = CapRateMath.propertyValue(netOperatingIncome: netOperatingIncome, capRate: capRate - step)!
        let numeric = (up - down) / (2.0 * step)

        // Then - dV/dc = -NOI / cap^2 = -80,000 / 0.0064
        XCTAssertEqual(analytic, -80_000.0 / (0.08 * 0.08), accuracy: 1e-6)
        XCTAssertEqual(numeric, analytic, accuracy: abs(analytic) * 1e-5)
        XCTAssertLessThan(analytic, 0)
    }

    func testSpreadOverBenchmark() {
        // Given - 6.5% cap rate against a 4.0% Treasury
        let spread = CapRateMath.spread(capRate: 0.065, benchmarkYield: 0.040)

        // Then
        XCTAssertEqual(spread, 0.025, accuracy: 1e-12)
    }

    func testPortfolioCapRateIsValueWeightedNotASimpleAverage() {
        // Given
        let incomes = [50_000.0, 80_000.0]
        let values = [800_000.0, 1_000_000.0]

        // When
        let portfolioCapRate = CapRateMath.portfolioCapRate(
            netOperatingIncomes: incomes,
            propertyValues: values
        )!
        let simpleAverage = ((50_000.0 / 800_000.0) + (80_000.0 / 1_000_000.0)) / 2.0

        // Then - 130,000 / 1,800,000 = 7.222..., not the unweighted mean of 6.25% and 8%
        XCTAssertEqual(portfolioCapRate, 130_000.0 / 1_800_000.0, accuracy: 1e-12)
        XCTAssertNotEqual(portfolioCapRate, simpleAverage, accuracy: 1e-6)
    }

    func testNegativeNOIKeepsANegativeCapRateButCannotBeCapitalized() {
        // Given
        let capRate = CapRateMath.capRate(netOperatingIncome: -10_000, propertyValue: 500_000)
        let value = CapRateMath.propertyValue(netOperatingIncome: -10_000, capRate: 0.06)

        // Then
        XCTAssertEqual(capRate, -0.02, accuracy: 1e-12)
        XCTAssertNil(value)
    }

    // MARK: - NOI Build-Up

    func testNOIBuildUpExcludesDebtService() {
        // Given
        let statement = OperatingStatement(
            potentialGrossIncome: 120_000,
            vacancyRate: 0.05,
            otherIncome: 2_000,
            operatingExpenses: 40_000
        )!

        // When
        let debtService = 20_000.0
        let capitalReserve = 5_000.0
        let cashFlow = statement.netOperatingIncome - debtService - capitalReserve

        // Then
        // Vacancy loss = 6,000; EGI = 116,000; NOI = 76,000
        XCTAssertEqual(statement.vacancyLoss, 6_000, accuracy: 1e-9)
        XCTAssertEqual(statement.effectiveGrossIncome, 116_000, accuracy: 1e-9)
        XCTAssertEqual(statement.netOperatingIncome, 76_000, accuracy: 1e-9)
        XCTAssertEqual(statement.operatingExpenseRatio, 40_000.0 / 116_000.0, accuracy: 1e-12)
        XCTAssertEqual(cashFlow, 51_000, accuracy: 1e-9)
        XCTAssertGreaterThan(statement.netOperatingIncome, cashFlow)
    }

    func testFullOccupancyAndNoExpensesLeavesNOIEqualToIncome() {
        // Given
        let statement = OperatingStatement(
            potentialGrossIncome: 50_000,
            vacancyRate: 0,
            operatingExpenses: 0
        )!

        // Then
        XCTAssertEqual(statement.netOperatingIncome, 50_000, accuracy: 1e-9)
        XCTAssertEqual(statement.operatingExpenseRatio, 0, accuracy: 1e-12)
    }

    func testOperatingExpenseRatioIsUndefinedWhenEffectiveIncomeIsZero() {
        // Given - 100% vacancy and no other income
        let statement = OperatingStatement(
            potentialGrossIncome: 40_000,
            vacancyRate: 1,
            operatingExpenses: 0
        )!

        // Then
        XCTAssertEqual(statement.effectiveGrossIncome, 0, accuracy: 1e-12)
        XCTAssertNil(statement.operatingExpenseRatio)
    }

    // MARK: - Acquisition and Debt Metrics

    func testGoingInCapRateCashOnCashAndDSCR() {
        // Given
        let investment = PropertyInvestment(
            purchasePrice: 1_000_000,
            closingCosts: 30_000,
            loanAmount: 750_000,
            netOperatingIncome: 70_000,
            annualDebtService: 54_000,
            annualCapitalReserve: 5_000
        )!

        // Then
        // Equity = 1,000,000 + 30,000 - 750,000 = 280,000
        // BTCF = 70,000 - 54,000 - 5,000 = 11,000
        XCTAssertEqual(investment.equityInvested, 280_000, accuracy: 1e-9)
        XCTAssertEqual(investment.loanToValue, 0.75, accuracy: 1e-12)
        XCTAssertEqual(investment.goingInCapRate, 0.07, accuracy: 1e-12)
        XCTAssertEqual(investment.cashFlowBeforeTax, 11_000, accuracy: 1e-9)
        XCTAssertEqual(investment.cashOnCashReturn, 11_000.0 / 280_000.0, accuracy: 1e-12)
        XCTAssertEqual(investment.debtServiceCoverageRatio, 70_000.0 / 54_000.0, accuracy: 1e-12)
    }

    func testUnleveredCashOnCashEqualsCapRate() {
        // Given - no debt, no closing costs, no reserves
        let investment = PropertyInvestment(
            purchasePrice: 1_000_000,
            closingCosts: 0,
            loanAmount: 0,
            netOperatingIncome: 65_000,
            annualDebtService: 0,
            annualCapitalReserve: 0
        )!

        // Then
        XCTAssertEqual(investment.cashOnCashReturn!, investment.goingInCapRate!, accuracy: 1e-12)
        XCTAssertNil(investment.debtServiceCoverageRatio)
    }

    func testClosingCostsMakeCashOnCashLowerThanCapRate() {
        // Given
        let investment = PropertyInvestment(
            purchasePrice: 1_000_000,
            closingCosts: 25_000,
            loanAmount: 0,
            netOperatingIncome: 60_000,
            annualDebtService: 0,
            annualCapitalReserve: 0
        )!

        // Then - cash in is larger than price, so cash-on-cash is below the cap rate
        XCTAssertLessThan(investment.cashOnCashReturn!, investment.goingInCapRate!)
        XCTAssertEqual(investment.cashOnCashReturn, 60_000.0 / 1_025_000.0, accuracy: 1e-12)
    }

    func testNegativeCashFlowAndCoverageBelowOne() {
        // Given
        let investment = PropertyInvestment(
            purchasePrice: 500_000,
            closingCosts: 0,
            loanAmount: 400_000,
            netOperatingIncome: 20_000,
            annualDebtService: 28_000,
            annualCapitalReserve: 2_000
        )!

        // Then
        XCTAssertEqual(investment.cashFlowBeforeTax, -10_000, accuracy: 1e-9)
        XCTAssertLessThan(investment.cashOnCashReturn!, 0)
        XCTAssertLessThan(investment.debtServiceCoverageRatio!, 1)
    }

    func testCashOnCashUndefinedWhenNoEquityIsInvested() {
        // Given - 100% financing and no closing costs
        let investment = PropertyInvestment(
            purchasePrice: 400_000,
            closingCosts: 0,
            loanAmount: 400_000,
            netOperatingIncome: 30_000,
            annualDebtService: 24_000,
            annualCapitalReserve: 0
        )!

        // Then
        XCTAssertEqual(investment.equityInvested, 0, accuracy: 1e-12)
        XCTAssertNil(investment.cashOnCashReturn)
        XCTAssertEqual(investment.loanToValue, 1, accuracy: 1e-12)
    }

    func testLoanToValueCanExceedOne() {
        // Given
        let investment = PropertyInvestment(
            purchasePrice: 400_000,
            closingCosts: 10_000,
            loanAmount: 420_000,
            netOperatingIncome: 30_000,
            annualDebtService: 24_000,
            annualCapitalReserve: 0
        )!

        // Then
        XCTAssertEqual(investment.loanToValue, 1.05, accuracy: 1e-12)
        XCTAssertLessThan(investment.equityInvested, 0)
        XCTAssertNil(investment.cashOnCashReturn)
    }

    func testGrossRentMultiplierAndBreakEvenOccupancy() {
        // Given
        let multiplier = PropertyInvestment.grossRentMultiplier(
            purchasePrice: 1_000_000,
            potentialGrossIncome: 100_000
        )
        let occupancy = PropertyInvestment.breakEvenOccupancy(
            potentialGrossIncome: 120_000,
            otherIncome: 0,
            operatingExpenses: 40_000,
            debtService: 54_000
        )

        // Then
        XCTAssertEqual(multiplier, 10, accuracy: 1e-12)
        XCTAssertEqual(occupancy, 94_000.0 / 120_000.0, accuracy: 1e-12)
    }

    func testBreakEvenOccupancyFallsWhenOtherIncomeRises() {
        // Given
        let withoutOtherIncome = PropertyInvestment.breakEvenOccupancy(
            potentialGrossIncome: 100_000,
            otherIncome: 0,
            operatingExpenses: 30_000,
            debtService: 40_000
        )!
        let withOtherIncome = PropertyInvestment.breakEvenOccupancy(
            potentialGrossIncome: 100_000,
            otherIncome: 10_000,
            operatingExpenses: 30_000,
            debtService: 40_000
        )!

        // Then
        XCTAssertEqual(withOtherIncome, 0.60, accuracy: 1e-12)
        XCTAssertLessThan(withOtherIncome, withoutOtherIncome)
    }

    // MARK: - Mortgage Mathematics

    func testFullyAmortizingMortgagePayment() {
        // Given - $800,000, 6%, 30-year, monthly
        let mortgage = MortgageTerms(
            principal: 800_000,
            annualInterestRate: 0.06,
            amortizingYears: 30,
            paymentsPerYear: 12
        )!

        // When
        let payment = mortgage.periodicPayment()
        let monthlyRate = 0.06 / 12.0
        let periods = 360.0
        let growth = pow(1.0 + monthlyRate, periods)
        let expected = 800_000.0 * monthlyRate * growth / (growth - 1.0)

        // Then
        XCTAssertEqual(payment, expected, accuracy: 1e-8)
        XCTAssertEqual(payment, 4_796.404201222055, accuracy: 1e-6)
        XCTAssertEqual(mortgage.annualDebtService(), payment * 12.0, accuracy: 1e-6)
    }

    func testZeroRateMortgageDividesPrincipalEvenly() {
        // Given
        let mortgage = MortgageTerms(
            principal: 120_000,
            annualInterestRate: 0,
            amortizingYears: 10,
            paymentsPerYear: 12
        )!

        // Then
        XCTAssertEqual(mortgage.periodicPayment(), 1_000, accuracy: 1e-12)
        XCTAssertEqual(mortgage.annualDebtService(), 12_000, accuracy: 1e-12)
        XCTAssertEqual(mortgage.remainingBalance(afterPayments: 0), 120_000, accuracy: 1e-9)
        XCTAssertEqual(mortgage.remainingBalance(afterPayments: 60), 60_000, accuracy: 1e-9)
        XCTAssertEqual(mortgage.remainingBalance(afterPayments: 120), 0, accuracy: 1e-9)
    }

    func testInterestOnlyDebtServiceIsBelowAmortizingDebtService() {
        // Given
        let principal = 800_000.0
        let rate = 0.06
        let interestOnly = MortgageTerms.interestOnlyAnnualDebtService(
            loanAmount: principal,
            annualInterestRate: rate
        )!
        let amortizing = MortgageTerms(
            principal: principal,
            annualInterestRate: rate,
            amortizingYears: 30,
            paymentsPerYear: 12
        )!.annualDebtService()

        // Then
        XCTAssertEqual(interestOnly, 48_000, accuracy: 1e-9)
        XCTAssertGreaterThan(amortizing, interestOnly)
    }

    func testTwoYearAnnualAmortizationSchedule() {
        // Given - $1,000 at 10% with two annual payments
        let mortgage = MortgageTerms(
            principal: 1_000,
            annualInterestRate: 0.10,
            amortizingYears: 2,
            paymentsPerYear: 1
        )!
        let payment = mortgage.periodicPayment()

        // Then - payment = 1,000 * 0.10 * 1.21 / 0.21
        XCTAssertEqual(payment, 121.0 / 0.21, accuracy: 1e-9)
        XCTAssertEqual(mortgage.remainingBalance(afterPayments: 0), 1_000, accuracy: 1e-9)

        let balanceAfterFirst = mortgage.remainingBalance(afterPayments: 1)!
        let firstInterest = 1_000.0 * 0.10
        XCTAssertEqual(balanceAfterFirst, 1_000 - (payment - firstInterest), accuracy: 1e-8)
        XCTAssertEqual(mortgage.remainingBalance(afterPayments: 2), 0, accuracy: 1e-8)
    }

    func testThirtyYearBalanceAtOriginationAndMaturity() {
        // Given
        let mortgage = MortgageTerms(
            principal: 800_000,
            annualInterestRate: 0.06,
            amortizingYears: 30,
            paymentsPerYear: 12
        )!

        // Then
        XCTAssertEqual(mortgage.remainingBalance(afterPayments: 0), 800_000, accuracy: 1e-6)
        XCTAssertEqual(mortgage.remainingBalance(afterPayments: 12), 790_175.9063017861, accuracy: 1e-4)
        XCTAssertEqual(mortgage.remainingBalance(afterPayments: 360), 0, accuracy: 1e-6)
        XCTAssertNil(mortgage.remainingBalance(afterPayments: -1))
        XCTAssertNil(mortgage.remainingBalance(afterPayments: 361))
    }

    // MARK: - Sale, Equity Multiple, and IRR

    func testSaleReversionNetProceeds() {
        // Given
        let sale = SaleReversion(
            exitNetOperatingIncome: 80_000,
            exitCapRate: 0.065,
            sellingCostRate: 0.05,
            remainingLoanBalance: 700_000
        )!

        // Then
        // Value = 80,000 / 0.065; costs = 5%; proceeds = value - costs - 700,000
        let expectedValue = 80_000.0 / 0.065
        XCTAssertEqual(sale.grossExitValue, expectedValue, accuracy: 1e-6)
        XCTAssertEqual(sale.sellingCosts, expectedValue * 0.05, accuracy: 1e-6)
        XCTAssertEqual(sale.netSaleProceeds, expectedValue * 0.95 - 700_000, accuracy: 1e-6)
    }

    func testUnderwaterSaleHasNegativeProceeds() {
        // Given
        let sale = SaleReversion(
            exitNetOperatingIncome: 20_000,
            exitCapRate: 0.10,
            sellingCostRate: 0.05,
            remainingLoanBalance: 250_000
        )!

        // Then - net sale price is 190,000 against a 250,000 loan
        XCTAssertEqual(sale.netSaleProceeds, -60_000, accuracy: 1e-6)
    }

    func testEquityMultipleAddsSaleProceedsOnce() {
        // Given
        let multiple = InvestmentReturn.equityMultiple(
            equityInvested: 100,
            distributions: [10, 10, 10, 120]
        )

        // Then
        XCTAssertEqual(multiple, 1.5, accuracy: 1e-12)
    }

    func testOnePeriodIRRIsTenPercent() {
        // Given
        let cashFlows = [-100.0, 110.0]

        // When
        let rate = InvestmentReturn.internalRateOfReturn(cashFlows: cashFlows)!
        let presentValue = InvestmentReturn.netPresentValue(cashFlows: cashFlows, rate: rate)!

        // Then
        XCTAssertEqual(rate, 0.10, accuracy: 1e-10)
        XCTAssertEqual(presentValue, 0, accuracy: 1e-8)
    }

    func testMultiPeriodIRRNetPresentValueIsZero() {
        // Given
        let cashFlows = [-100.0, 30.0, 40.0, 50.0]

        // When
        let rate = InvestmentReturn.internalRateOfReturn(cashFlows: cashFlows)!
        let presentValue = InvestmentReturn.netPresentValue(cashFlows: cashFlows, rate: rate)!

        // Then
        XCTAssertEqual(rate, 0.0889633946933498, accuracy: 1e-8)
        XCTAssertEqual(presentValue, 0, accuracy: 1e-6)
    }

    func testIRRRequiresASignChange() {
        XCTAssertNil(InvestmentReturn.internalRateOfReturn(cashFlows: [100, 110]))
        XCTAssertNil(InvestmentReturn.internalRateOfReturn(cashFlows: [-100, -50]))
        XCTAssertNil(InvestmentReturn.internalRateOfReturn(cashFlows: [-100]))
        XCTAssertNil(InvestmentReturn.netPresentValue(cashFlows: [-100, 110], rate: -1))
    }

    func testProjectedNOICompoundsFromYearOne() {
        // Given
        let yearOne = InvestmentReturn.projectedNOI(yearOneNOI: 100_000, annualGrowthRate: 0.03, year: 1)
        let yearThree = InvestmentReturn.projectedNOI(yearOneNOI: 100_000, annualGrowthRate: 0.03, year: 3)

        // Then
        XCTAssertEqual(yearOne, 100_000, accuracy: 1e-9)
        XCTAssertEqual(yearThree, 100_000 * pow(1.03, 2), accuracy: 1e-8)
        XCTAssertNil(InvestmentReturn.projectedNOI(yearOneNOI: 100_000, annualGrowthRate: 0.03, year: 0))
        XCTAssertNil(InvestmentReturn.projectedNOI(yearOneNOI: 100_000, annualGrowthRate: -1, year: 2))
    }

    func testHoldPeriodEquityMultipleAndIRR() {
        // Given - flat NOI, two operating years, trailing exit cap of 8%
        let analysis = HoldPeriodAnalysis(
            yearOneNOI: 100_000,
            noiGrowthRate: 0,
            years: 2,
            annualDebtService: 40_000,
            annualCapitalReserve: 0,
            exitCapRate: 0.08,
            sellingCostRate: 0,
            remainingLoanBalance: 500_000,
            equityInvested: 300_000
        )!

        // Then
        // BTCF = 60,000. Exit value = 100,000 / 0.08 = 1,250,000.
        // Net proceeds = 750,000. Distributions = 60,000 + 60,000 + 750,000.
        XCTAssertEqual(analysis.beforeTaxCashFlow(inYear: 1), 60_000, accuracy: 1e-8)
        XCTAssertEqual(analysis.beforeTaxCashFlow(inYear: 2), 60_000, accuracy: 1e-8)
        XCTAssertEqual(analysis.netSaleProceeds, 750_000, accuracy: 1e-6)
        XCTAssertEqual(analysis.equityMultiple, 870_000.0 / 300_000.0, accuracy: 1e-10)

        let cashFlows = analysis.investorCashFlows()!
        XCTAssertEqual(cashFlows.count, 3)
        XCTAssertEqual(cashFlows[0], -300_000, accuracy: 1e-8)
        XCTAssertEqual(cashFlows[1], 60_000, accuracy: 1e-8)
        XCTAssertEqual(cashFlows[2], 810_000, accuracy: 1e-6)

        let rate = analysis.internalRateOfReturn()!
        let presentValue = InvestmentReturn.netPresentValue(cashFlows: cashFlows, rate: rate)!
        XCTAssertEqual(presentValue, 0, accuracy: 1e-4)
    }

    func testHigherExitCapRateLowersEquityMultiple() {
        // Given
        func multiple(exitCapRate: Double) -> Double {
            HoldPeriodAnalysis(
                yearOneNOI: 100_000,
                noiGrowthRate: 0,
                years: 2,
                annualDebtService: 40_000,
                annualCapitalReserve: 0,
                exitCapRate: exitCapRate,
                sellingCostRate: 0,
                remainingLoanBalance: 500_000,
                equityInvested: 300_000
            )!.equityMultiple!
        }

        // Then
        XCTAssertGreaterThan(multiple(exitCapRate: 0.06), multiple(exitCapRate: 0.08))
    }

    // MARK: - Edge Cases

    func testInvalidCapRateInputsReturnNil() {
        XCTAssertNil(CapRateMath.capRate(netOperatingIncome: 10, propertyValue: 0))
        XCTAssertNil(CapRateMath.capRate(netOperatingIncome: 10, propertyValue: -5))
        XCTAssertNil(CapRateMath.propertyValue(netOperatingIncome: 10, capRate: 0))
        XCTAssertNil(CapRateMath.propertyValue(netOperatingIncome: 10, capRate: -0.02))
        XCTAssertNil(CapRateMath.valueChangeFromCapRateMove(startCapRate: 0, endCapRate: 0.06))
        XCTAssertNil(CapRateMath.spread(capRate: .nan, benchmarkYield: 0.04))
        XCTAssertNil(CapRateMath.portfolioCapRate(netOperatingIncomes: [1], propertyValues: [1, 2]))
        XCTAssertNil(CapRateMath.capRateAfterValueChange(startCapRate: 0.06, valueChange: -1))
    }

    func testInvalidOperatingStatementAndMortgageInputsReturnNil() {
        XCTAssertNil(OperatingStatement(potentialGrossIncome: -1, vacancyRate: 0, operatingExpenses: 0))
        XCTAssertNil(OperatingStatement(potentialGrossIncome: 1, vacancyRate: 1.1, operatingExpenses: 0))
        XCTAssertNil(OperatingStatement(potentialGrossIncome: 1, vacancyRate: -0.01, operatingExpenses: 0))
        XCTAssertNil(MortgageTerms(principal: -1, annualInterestRate: 0.05, amortizingYears: 30, paymentsPerYear: 12))
        XCTAssertNil(MortgageTerms(principal: 1, annualInterestRate: -0.01, amortizingYears: 30, paymentsPerYear: 12))
        XCTAssertNil(MortgageTerms(principal: 1, annualInterestRate: 0.05, amortizingYears: 0, paymentsPerYear: 12))
        XCTAssertNil(MortgageTerms(principal: 1, annualInterestRate: 0.05, amortizingYears: 30, paymentsPerYear: 0))
        XCTAssertNil(PropertyInvestment.grossRentMultiplier(purchasePrice: 0, potentialGrossIncome: 10))
        XCTAssertNil(PropertyInvestment.breakEvenOccupancy(
            potentialGrossIncome: 0,
            otherIncome: 0,
            operatingExpenses: 1,
            debtService: 1
        ))
    }
}
