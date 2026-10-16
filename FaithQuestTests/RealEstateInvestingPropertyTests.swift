//
//  RealEstateInvestingPropertyTests.swift
//  FaithQuestTests
//
//  Property tests for cap-rate mathematics and direct-property investing.
//  "In π's infinite digits, primes hide like gems. The polymath finds them where specialists see only chaos."
//

import XCTest
import SwiftCheck
@testable import FaithQuest

final class RealEstateInvestingPropertyTests: XCTestCase {

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
        guard value.isFinite else { return 100_000 }
        let normalized = abs(value).truncatingRemainder(dividingBy: 1_000_000.0)
        return normalized < 1 ? 1 : normalized
    }

    private func boundedInt(_ value: Int, modulus: Int, shift: Int) -> Int {
        let safeModulus = max(modulus, 1)
        let wrapped = value % safeModulus
        return (wrapped + safeModulus) % safeModulus + shift
    }

    func testCapRateAndValueAreInverses() {
        property("Direct capitalization inverts the cap rate for positive NOI") <- forAll { (noiRaw: Double, capRaw: Double) in
            let noi = self.positiveMoney(noiRaw)
            let capRate = self.unitInterval(capRaw) * 0.20 + 0.01
            guard let value = CapRateMath.propertyValue(netOperatingIncome: noi, capRate: capRate),
                  let recovered = CapRateMath.capRate(netOperatingIncome: noi, propertyValue: value) else {
                return self.labeled(false, "Capitalization should be defined")
            }
            return self.labeled(abs(recovered - capRate) < 1e-9, "Recovered cap rate") ^&&^
                self.labeled(abs(value * capRate - noi) < 1e-6, "NOI identity")
        }
    }

    func testValueFallsAsCapRateRises() {
        property("Holding NOI fixed, a higher cap rate produces a lower value") <- forAll { (noiRaw: Double, capRaw: Double, otherRaw: Double) in
            let noi = self.positiveMoney(noiRaw)
            let first = self.unitInterval(capRaw) * 0.15 + 0.02
            let second = self.unitInterval(otherRaw) * 0.15 + 0.02
            let low = min(first, second)
            let high = max(first, second)
            guard high - low > 0.001 else { return Discard() }
            guard let lowValue = CapRateMath.propertyValue(netOperatingIncome: noi, capRate: low),
                  let highValue = CapRateMath.propertyValue(netOperatingIncome: noi, capRate: high) else {
                return self.labeled(false, "Values should be defined")
            }
            return self.labeled(lowValue > highValue, "Value should fall as the cap rate rises")
        }
    }

    func testValueRisesWithNOI() {
        property("Holding the cap rate fixed, more NOI produces more value") <- forAll { (noiRaw: Double, otherRaw: Double, capRaw: Double) in
            let first = self.positiveMoney(noiRaw)
            let second = self.positiveMoney(otherRaw)
            let low = min(first, second)
            let high = max(first, second)
            guard high - low > 1 else { return Discard() }
            let capRate = self.unitInterval(capRaw) * 0.15 + 0.02
            guard let lowValue = CapRateMath.propertyValue(netOperatingIncome: low, capRate: capRate),
                  let highValue = CapRateMath.propertyValue(netOperatingIncome: high, capRate: capRate) else {
                return self.labeled(false, "Values should be defined")
            }
            return self.labeled(highValue > lowValue, "Value should rise with NOI")
        }
    }

    func testCapRateCompressionIdentity() {
        property("Value change from a cap-rate move equals the ratio of the two values") <- forAll { (noiRaw: Double, startRaw: Double, endRaw: Double) in
            let noi = self.positiveMoney(noiRaw)
            let startCap = self.unitInterval(startRaw) * 0.15 + 0.02
            let endCap = self.unitInterval(endRaw) * 0.15 + 0.02
            guard let startValue = CapRateMath.propertyValue(netOperatingIncome: noi, capRate: startCap),
                  let endValue = CapRateMath.propertyValue(netOperatingIncome: noi, capRate: endCap),
                  let change = CapRateMath.valueChangeFromCapRateMove(startCapRate: startCap, endCapRate: endCap) else {
                return self.labeled(false, "Cap-rate move should be defined")
            }
            return self.labeled(abs((endValue - startValue) / startValue - change) < 1e-9, "Compression identity")
        }
    }

    func testCapRateMoveRoundTrips() {
        property("A cap-rate move and its inverse recover the ending cap rate") <- forAll { (startRaw: Double, endRaw: Double) in
            let startCap = self.unitInterval(startRaw) * 0.15 + 0.02
            let endCap = self.unitInterval(endRaw) * 0.15 + 0.02
            guard let change = CapRateMath.valueChangeFromCapRateMove(startCapRate: startCap, endCapRate: endCap),
                  let recovered = CapRateMath.capRateAfterValueChange(startCapRate: startCap, valueChange: change) else {
                return self.labeled(false, "Round trip should be defined")
            }
            return self.labeled(abs(recovered - endCap) < 1e-9, "Ending cap rate should round-trip")
        }
    }

    func testValueSensitivityIsNegativeAndCloseToTheFiniteDifference() {
        property("Analytic cap-rate sensitivity matches a central difference") <- forAll { (noiRaw: Double, capRaw: Double) in
            let noi = self.positiveMoney(noiRaw)
            let capRate = self.unitInterval(capRaw) * 0.10 + 0.03
            let step = 0.0001
            guard let analytic = CapRateMath.valueSensitivityToCapRate(netOperatingIncome: noi, capRate: capRate),
                  let up = CapRateMath.propertyValue(netOperatingIncome: noi, capRate: capRate + step),
                  let down = CapRateMath.propertyValue(netOperatingIncome: noi, capRate: capRate - step) else {
                return self.labeled(false, "Sensitivity should be defined")
            }
            let numeric = (up - down) / (2.0 * step)
            let tolerance = max(1.0, abs(analytic) * 1e-4)
            return self.labeled(analytic < 0, "Sensitivity is negative") ^&&^
                self.labeled(abs(numeric - analytic) < tolerance, "Finite difference")
        }
    }

    func testNOIBuildUpIdentity() {
        property("NOI equals potential income after vacancy and other income, minus expenses") <- forAll { (incomeRaw: Double, vacancyRaw: Double, otherRaw: Double, expenseRaw: Double) in
            let income = self.positiveMoney(incomeRaw)
            let vacancy = self.unitInterval(vacancyRaw)
            let other = self.positiveMoney(otherRaw) * 0.1
            let expenses = self.positiveMoney(expenseRaw) * 0.5
            guard let statement = OperatingStatement(
                potentialGrossIncome: income,
                vacancyRate: vacancy,
                otherIncome: other,
                operatingExpenses: expenses
            ) else {
                return self.labeled(false, "Statement should be valid")
            }
            let expected = income * (1.0 - vacancy) + other - expenses
            return self.labeled(abs(statement.netOperatingIncome - expected) < 1e-6, "NOI build-up")
        }
    }

    func testExpenseRatioMultipliesBackToExpenses() {
        property("Operating expense ratio times effective income recovers expenses") <- forAll { (incomeRaw: Double, expenseRaw: Double) in
            let income = self.positiveMoney(incomeRaw) + 100
            let expenses = self.unitInterval(expenseRaw) * income
            guard let statement = OperatingStatement(
                potentialGrossIncome: income,
                vacancyRate: 0,
                operatingExpenses: expenses
            ), let ratio = statement.operatingExpenseRatio else {
                return self.labeled(false, "Ratio should be defined")
            }
            return self.labeled(abs(ratio * statement.effectiveGrossIncome - expenses) < 1e-6, "Expense ratio identity")
        }
    }

    func testPortfolioCapRateIsAggregateNOIOverAggregateValue() {
        property("Portfolio cap rate is total NOI over total value") <- forAll { (noiRaw: Double, valueRaw: Double, otherNOI: Double, otherValue: Double) in
            let firstNOI = self.positiveMoney(noiRaw)
            let secondNOI = self.positiveMoney(otherNOI)
            let firstValue = self.positiveMoney(valueRaw) + 1_000
            let secondValue = self.positiveMoney(otherValue) + 1_000
            guard let capRate = CapRateMath.portfolioCapRate(
                netOperatingIncomes: [firstNOI, secondNOI],
                propertyValues: [firstValue, secondValue]
            ) else {
                return self.labeled(false, "Portfolio cap rate should be defined")
            }
            let expected = (firstNOI + secondNOI) / (firstValue + secondValue)
            return self.labeled(abs(capRate - expected) < 1e-9, "Aggregate cap rate")
        }
    }

    func testLoanToValueAndCashOnCashIdentities() {
        property("LTV and cash-on-cash recover loan amount and before-tax cash flow") <- forAll { (priceRaw: Double, loanRaw: Double, noiRaw: Double, debtRaw: Double) in
            let price = self.positiveMoney(priceRaw) + 10_000
            let loan = self.unitInterval(loanRaw) * price * 0.8
            let noi = self.positiveMoney(noiRaw)
            let debtService = self.unitInterval(debtRaw) * noi
            guard let investment = PropertyInvestment(
                purchasePrice: price,
                closingCosts: 0,
                loanAmount: loan,
                netOperatingIncome: noi,
                annualDebtService: debtService,
                annualCapitalReserve: 0
            ) else {
                return self.labeled(false, "Investment should be valid")
            }
            let loanRecovered = abs(investment.loanToValue * price - loan) < 1e-6
            guard let cashOnCash = investment.cashOnCashReturn else {
                return self.labeled(false, "Equity should be positive")
            }
            let cashFlowRecovered = abs(cashOnCash * investment.equityInvested - investment.cashFlowBeforeTax) < 1e-6
            return self.labeled(loanRecovered, "LTV identity") ^&&^
                self.labeled(cashFlowRecovered, "Cash-on-cash identity")
        }
    }

    func testUnleveredCashOnCashMatchesCapRate() {
        property("With no debt, closing costs, or reserves, cash-on-cash equals the cap rate") <- forAll { (priceRaw: Double, noiRaw: Double) in
            let price = self.positiveMoney(priceRaw) + 1_000
            let noi = self.unitInterval(noiRaw) * price
            guard let investment = PropertyInvestment(
                purchasePrice: price,
                closingCosts: 0,
                loanAmount: 0,
                netOperatingIncome: noi,
                annualDebtService: 0,
                annualCapitalReserve: 0
            ), let cashOnCash = investment.cashOnCashReturn, let capRate = investment.goingInCapRate else {
                return self.labeled(false, "Unlevered investment should be defined")
            }
            return self.labeled(abs(cashOnCash - capRate) < 1e-9, "Unlevered cash-on-cash is the cap rate")
        }
    }

    func testDebtServiceCoverageRecoversNOI() {
        property("DSCR times debt service recovers NOI") <- forAll { (noiRaw: Double, debtRaw: Double) in
            let noi = self.positiveMoney(noiRaw)
            let debtService = self.positiveMoney(debtRaw) + 1
            guard let investment = PropertyInvestment(
                purchasePrice: 1_000_000,
                closingCosts: 0,
                loanAmount: 100_000,
                netOperatingIncome: noi,
                annualDebtService: debtService,
                annualCapitalReserve: 0
            ), let coverage = investment.debtServiceCoverageRatio else {
                return self.labeled(false, "Coverage should be defined")
            }
            return self.labeled(abs(coverage * debtService - noi) < 1e-6, "DSCR identity")
        }
    }

    func testGrossRentMultiplierRecoversPrice() {
        property("Gross rent multiplier times potential income recovers price") <- forAll { (priceRaw: Double, incomeRaw: Double) in
            let price = self.positiveMoney(priceRaw) + 1
            let income = self.positiveMoney(incomeRaw) + 1
            guard let multiplier = PropertyInvestment.grossRentMultiplier(
                purchasePrice: price,
                potentialGrossIncome: income
            ) else {
                return self.labeled(false, "Multiplier should be defined")
            }
            return self.labeled(abs(multiplier * income - price) < 1e-6, "GRM identity")
        }
    }

    func testMortgageBalanceStartsAtPrincipalAndEndsAtZero() {
        property("Amortization starts at principal and ends at zero") <- forAll { (principalRaw: Double, rateRaw: Double, yearsRaw: Int, frequencyRaw: Int) in
            let principal = self.positiveMoney(principalRaw)
            let rate = self.unitInterval(rateRaw) * 0.12
            let years = self.boundedInt(yearsRaw, modulus: 10, shift: 1)
            let frequencies = [1, 4, 12]
            let frequency = frequencies[self.boundedInt(frequencyRaw, modulus: frequencies.count, shift: 0)]
            guard let mortgage = MortgageTerms(
                principal: principal,
                annualInterestRate: rate,
                amortizingYears: years,
                paymentsPerYear: frequency
            ) else {
                return self.labeled(false, "Mortgage should be valid")
            }
            guard let start = mortgage.remainingBalance(afterPayments: 0),
                  let end = mortgage.remainingBalance(afterPayments: mortgage.numberOfPayments) else {
                return self.labeled(false, "Balances should be defined")
            }
            return self.labeled(abs(start - principal) < 1e-6, "Opening balance") ^&&^
                self.labeled(abs(end) < 1e-4, "Maturity balance")
        }
    }

    func testAmortizingPaymentExceedsInterestOnlyDebtService() {
        property("A positive-rate amortizing payment exceeds interest-only debt service") <- forAll { (principalRaw: Double, rateRaw: Double) in
            let principal = self.positiveMoney(principalRaw) + 100
            let rate = self.unitInterval(rateRaw) * 0.10 + 0.01
            guard let mortgage = MortgageTerms(
                principal: principal,
                annualInterestRate: rate,
                amortizingYears: 15,
                paymentsPerYear: 12
            ), let interestOnly = MortgageTerms.interestOnlyAnnualDebtService(
                loanAmount: principal,
                annualInterestRate: rate
            ) else {
                return self.labeled(false, "Debt service should be defined")
            }
            return self.labeled(mortgage.annualDebtService() > interestOnly, "Amortization costs more than interest only")
        }
    }

    func testZeroRateBalanceDeclinesLinearly() {
        property("A zero-rate loan pays principal down in equal steps") <- forAll { (principalRaw: Double, yearsRaw: Int) in
            let principal = self.positiveMoney(principalRaw)
            let years = self.boundedInt(yearsRaw, modulus: 20, shift: 1)
            guard let mortgage = MortgageTerms(
                principal: principal,
                annualInterestRate: 0,
                amortizingYears: years,
                paymentsPerYear: 1
            ), let midpoint = mortgage.remainingBalance(afterPayments: years / 2) else {
                return self.labeled(false, "Zero-rate mortgage should be valid")
            }
            let expected = principal * Double(years - years / 2) / Double(years)
            return self.labeled(abs(mortgage.periodicPayment() * Double(years) - principal) < 1e-6, "Payments sum to principal") ^&&^
                self.labeled(abs(midpoint - expected) < 1e-6, "Linear balance")
        }
    }

    func testSaleProceedsIdentity() {
        property("Net sale proceeds equal capitalized NOI after selling costs and the loan") <- forAll { (noiRaw: Double, capRaw: Double, costRaw: Double, loanRaw: Double) in
            let noi = self.positiveMoney(noiRaw)
            let capRate = self.unitInterval(capRaw) * 0.12 + 0.03
            let sellingCostRate = self.unitInterval(costRaw) * 0.10
            let loan = self.positiveMoney(loanRaw)
            guard let sale = SaleReversion(
                exitNetOperatingIncome: noi,
                exitCapRate: capRate,
                sellingCostRate: sellingCostRate,
                remainingLoanBalance: loan
            ), let proceeds = sale.netSaleProceeds else {
                return self.labeled(false, "Sale should be defined")
            }
            let expected = noi / capRate * (1.0 - sellingCostRate) - loan
            return self.labeled(abs(proceeds - expected) < 1e-4, "Sale proceeds identity")
        }
    }

    func testEquityMultipleScalesDistributions() {
        property("Doubling every distribution doubles the equity multiple") <- forAll { (equityRaw: Double, firstRaw: Double, secondRaw: Double) in
            let equity = self.positiveMoney(equityRaw) + 1
            let first = self.positiveMoney(firstRaw)
            let second = self.positiveMoney(secondRaw)
            guard let once = InvestmentReturn.equityMultiple(equityInvested: equity, distributions: [first, second]),
                  let twice = InvestmentReturn.equityMultiple(equityInvested: equity, distributions: [first * 2, second * 2]) else {
                return self.labeled(false, "Equity multiple should be defined")
            }
            return self.labeled(abs(twice - once * 2) < 1e-8, "Equity multiple is linear in distributions")
        }
    }

    func testOnePeriodIRRSolvesTheGrowthRate() {
        property("A one-period IRR equals the growth of the terminal cash flow") <- forAll { (equityRaw: Double, growthRaw: Double) in
            let equity = self.positiveMoney(equityRaw) + 1
            let growth = self.unitInterval(growthRaw) * 0.40 - 0.10
            guard abs(growth) > 0.001 else { return Discard() }
            let terminal = equity * (1.0 + growth)
            guard let rate = InvestmentReturn.internalRateOfReturn(cashFlows: [-equity, terminal]),
                  let presentValue = InvestmentReturn.netPresentValue(cashFlows: [-equity, terminal], rate: rate) else {
                return self.labeled(false, "IRR should converge")
            }
            return self.labeled(abs(rate - growth) < 1e-8, "One-period IRR") ^&&^
                self.labeled(abs(presentValue) < 1e-4, "NPV at the IRR is zero")
        }
    }
}
