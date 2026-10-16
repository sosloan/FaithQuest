//
//  RealEstateInvesting.swift
//  FaithQuest
//
//  Cap-rate mathematics and direct-property investing metrics.
//  Pure functions: the same inputs always describe the same investment world.
//
//  Rates are decimals (0.06 is 6%). Money amounts share one currency unit.
//  NOI excludes debt service, capital reserves, depreciation, and income taxes.
//

import Foundation

private func isFiniteNumber(_ value: Double) -> Bool {
    value.isFinite
}

/// Direct capitalization and cap-rate identities.
enum CapRateMath {

    /// Going-in or trailing cap rate: NOI / property value.
    /// Negative NOI is preserved so a distressed asset can show a negative cap rate.
    static func capRate(netOperatingIncome: Double, propertyValue: Double) -> Double? {
        guard isFiniteNumber(netOperatingIncome), isFiniteNumber(propertyValue), propertyValue > 0 else {
            return nil
        }
        let rate = netOperatingIncome / propertyValue
        return rate.isFinite ? rate : nil
    }

    /// Direct capitalization: value = NOI / cap rate. Both inputs must be positive.
    static func propertyValue(netOperatingIncome: Double, capRate: Double) -> Double? {
        guard isFiniteNumber(netOperatingIncome), netOperatingIncome >= 0,
              isFiniteNumber(capRate), capRate > 0 else {
            return nil
        }
        let value = netOperatingIncome / capRate
        return value.isFinite ? value : nil
    }

    /// Holding NOI fixed, (V2 - V1) / V1 = (startCap / endCap) - 1.
    /// Compression (end cap below start cap) is a positive value change.
    static func valueChangeFromCapRateMove(startCapRate: Double, endCapRate: Double) -> Double? {
        guard isFiniteNumber(startCapRate), startCapRate > 0,
              isFiniteNumber(endCapRate), endCapRate > 0 else {
            return nil
        }
        let change = (startCapRate / endCapRate) - 1.0
        return change.isFinite ? change : nil
    }

    /// Cap rate that produces `valueChange` when NOI is held fixed.
    static func capRateAfterValueChange(startCapRate: Double, valueChange: Double) -> Double? {
        guard isFiniteNumber(startCapRate), startCapRate > 0,
              isFiniteNumber(valueChange), valueChange > -1.0 else {
            return nil
        }
        let endCapRate = startCapRate / (1.0 + valueChange)
        return endCapRate.isFinite && endCapRate > 0 ? endCapRate : nil
    }

    /// Partial of value with respect to cap rate, holding NOI fixed: -NOI / cap^2.
    static func valueSensitivityToCapRate(netOperatingIncome: Double, capRate: Double) -> Double? {
        guard isFiniteNumber(netOperatingIncome), netOperatingIncome >= 0,
              isFiniteNumber(capRate), capRate > 0 else {
            return nil
        }
        let sensitivity = -netOperatingIncome / (capRate * capRate)
        return sensitivity.isFinite ? sensitivity : nil
    }

    /// Cap rate minus a benchmark yield (Treasury, SOFR, or cost of capital).
    static func spread(capRate: Double, benchmarkYield: Double) -> Double? {
        guard isFiniteNumber(capRate), isFiniteNumber(benchmarkYield) else { return nil }
        return capRate - benchmarkYield
    }

    /// Portfolio cap rate is aggregate NOI over aggregate value, not the mean of cap rates.
    static func portfolioCapRate(netOperatingIncomes: [Double], propertyValues: [Double]) -> Double? {
        guard netOperatingIncomes.count == propertyValues.count, !netOperatingIncomes.isEmpty else {
            return nil
        }
        var totalNOI = 0.0
        var totalValue = 0.0
        for (noi, value) in zip(netOperatingIncomes, propertyValues) {
            guard isFiniteNumber(noi), isFiniteNumber(value), value > 0 else { return nil }
            totalNOI += noi
            totalValue += value
        }
        guard totalValue > 0 else { return nil }
        let rate = totalNOI / totalValue
        return rate.isFinite ? rate : nil
    }
}

/// Stabilized operating statement used to build NOI.
struct OperatingStatement: Equatable {
    let potentialGrossIncome: Double
    let vacancyRate: Double
    let otherIncome: Double
    let operatingExpenses: Double

    init?(potentialGrossIncome: Double,
          vacancyRate: Double,
          otherIncome: Double = 0,
          operatingExpenses: Double) {
        guard isFiniteNumber(potentialGrossIncome), potentialGrossIncome >= 0,
              isFiniteNumber(vacancyRate), (0.0...1.0).contains(vacancyRate),
              isFiniteNumber(otherIncome), otherIncome >= 0,
              isFiniteNumber(operatingExpenses), operatingExpenses >= 0 else {
            return nil
        }
        self.potentialGrossIncome = potentialGrossIncome
        self.vacancyRate = vacancyRate
        self.otherIncome = otherIncome
        self.operatingExpenses = operatingExpenses
    }

    var vacancyLoss: Double {
        potentialGrossIncome * vacancyRate
    }

    /// Potential gross income, minus vacancy, plus other income.
    var effectiveGrossIncome: Double {
        potentialGrossIncome - vacancyLoss + otherIncome
    }

    /// NOI excludes debt service, capital reserves, depreciation, and income taxes.
    var netOperatingIncome: Double {
        effectiveGrossIncome - operatingExpenses
    }

    var operatingExpenseRatio: Double? {
        let income = effectiveGrossIncome
        guard income > 0 else { return nil }
        return operatingExpenses / income
    }
}

/// Fixed-rate mortgage used for debt service, amortization, and DSCR.
struct MortgageTerms: Equatable {
    let principal: Double
    let annualInterestRate: Double
    let amortizingYears: Int
    let paymentsPerYear: Int

    init?(principal: Double,
          annualInterestRate: Double,
          amortizingYears: Int,
          paymentsPerYear: Int) {
        guard isFiniteNumber(principal), principal >= 0,
              isFiniteNumber(annualInterestRate), annualInterestRate >= 0,
              amortizingYears > 0, paymentsPerYear > 0 else {
            return nil
        }
        let (count, overflow) = amortizingYears.multipliedReportingOverflow(by: paymentsPerYear)
        guard !overflow, count > 0 else { return nil }
        self.principal = principal
        self.annualInterestRate = annualInterestRate
        self.amortizingYears = amortizingYears
        self.paymentsPerYear = paymentsPerYear
    }

    var numberOfPayments: Int {
        amortizingYears * paymentsPerYear
    }

    var periodicRate: Double {
        annualInterestRate / Double(paymentsPerYear)
    }

    /// Level payment. A zero-rate loan divides principal evenly across periods.
    func periodicPayment() -> Double {
        let periods = Double(numberOfPayments)
        if principal == 0 { return 0 }
        let rate = periodicRate
        if rate == 0 { return principal / periods }
        let growth = pow(1.0 + rate, periods)
        return principal * rate * growth / (growth - 1.0)
    }

    func annualDebtService() -> Double {
        periodicPayment() * Double(paymentsPerYear)
    }

    /// Interest-only debt service. Principal is not amortized.
    static func interestOnlyAnnualDebtService(loanAmount: Double, annualInterestRate: Double) -> Double? {
        guard isFiniteNumber(loanAmount), loanAmount >= 0,
              isFiniteNumber(annualInterestRate), annualInterestRate >= 0 else {
            return nil
        }
        return loanAmount * annualInterestRate
    }

    /// Remaining principal after `paymentsMade` level payments. Zero at maturity.
    func remainingBalance(afterPayments paymentsMade: Int) -> Double? {
        guard paymentsMade >= 0, paymentsMade <= numberOfPayments else { return nil }
        if principal == 0 || paymentsMade == numberOfPayments { return 0 }
        if paymentsMade == 0 { return principal }
        let periods = Double(numberOfPayments)
        let paid = Double(paymentsMade)
        let rate = periodicRate
        let balance: Double
        if rate == 0 {
            balance = principal * (periods - paid) / periods
        } else {
            let growthToMaturity = pow(1.0 + rate, periods)
            let growthPaid = pow(1.0 + rate, paid)
            balance = principal * (growthToMaturity - growthPaid) / (growthToMaturity - 1.0)
        }
        return balance.isFinite ? balance : nil
    }
}

/// Acquisition metrics for a single stabilized year.
struct PropertyInvestment: Equatable {
    let purchasePrice: Double
    let closingCosts: Double
    let loanAmount: Double
    let netOperatingIncome: Double
    let annualDebtService: Double
    let annualCapitalReserve: Double

    init?(purchasePrice: Double,
          closingCosts: Double,
          loanAmount: Double,
          netOperatingIncome: Double,
          annualDebtService: Double,
          annualCapitalReserve: Double) {
        guard isFiniteNumber(purchasePrice), purchasePrice > 0,
              isFiniteNumber(closingCosts), closingCosts >= 0,
              isFiniteNumber(loanAmount), loanAmount >= 0,
              isFiniteNumber(netOperatingIncome),
              isFiniteNumber(annualDebtService), annualDebtService >= 0,
              isFiniteNumber(annualCapitalReserve), annualCapitalReserve >= 0 else {
            return nil
        }
        self.purchasePrice = purchasePrice
        self.closingCosts = closingCosts
        self.loanAmount = loanAmount
        self.netOperatingIncome = netOperatingIncome
        self.annualDebtService = annualDebtService
        self.annualCapitalReserve = annualCapitalReserve
    }

    /// Cash required at close: price plus closing costs, minus the loan.
    var equityInvested: Double {
        purchasePrice + closingCosts - loanAmount
    }

    var loanToValue: Double {
        loanAmount / purchasePrice
    }

    var goingInCapRate: Double? {
        CapRateMath.capRate(netOperatingIncome: netOperatingIncome, propertyValue: purchasePrice)
    }

    /// NOI minus debt service minus capital reserves. Debt service is not part of NOI.
    var cashFlowBeforeTax: Double {
        netOperatingIncome - annualDebtService - annualCapitalReserve
    }

    var cashOnCashReturn: Double? {
        guard equityInvested > 0 else { return nil }
        return cashFlowBeforeTax / equityInvested
    }

    var debtServiceCoverageRatio: Double? {
        guard annualDebtService > 0 else { return nil }
        return netOperatingIncome / annualDebtService
    }

    static func grossRentMultiplier(purchasePrice: Double, potentialGrossIncome: Double) -> Double? {
        guard isFiniteNumber(purchasePrice), purchasePrice > 0,
              isFiniteNumber(potentialGrossIncome), potentialGrossIncome > 0 else {
            return nil
        }
        return purchasePrice / potentialGrossIncome
    }

    /// Occupancy at which potential gross income covers operating expenses, debt service, and other income.
    static func breakEvenOccupancy(potentialGrossIncome: Double,
                                    otherIncome: Double,
                                    operatingExpenses: Double,
                                    debtService: Double) -> Double? {
        guard isFiniteNumber(potentialGrossIncome), potentialGrossIncome > 0,
              isFiniteNumber(otherIncome),
              isFiniteNumber(operatingExpenses),
              isFiniteNumber(debtService) else {
            return nil
        }
        let occupancy = (operatingExpenses + debtService - otherIncome) / potentialGrossIncome
        return occupancy.isFinite ? occupancy : nil
    }
}

/// Terminal sale capitalized at an exit cap rate.
struct SaleReversion: Equatable {
    let exitNetOperatingIncome: Double
    let exitCapRate: Double
    let sellingCostRate: Double
    let remainingLoanBalance: Double

    init?(exitNetOperatingIncome: Double,
          exitCapRate: Double,
          sellingCostRate: Double,
          remainingLoanBalance: Double) {
        guard isFiniteNumber(exitNetOperatingIncome), exitNetOperatingIncome >= 0,
              isFiniteNumber(exitCapRate), exitCapRate > 0,
              isFiniteNumber(sellingCostRate), (0.0...1.0).contains(sellingCostRate),
              isFiniteNumber(remainingLoanBalance), remainingLoanBalance >= 0 else {
            return nil
        }
        self.exitNetOperatingIncome = exitNetOperatingIncome
        self.exitCapRate = exitCapRate
        self.sellingCostRate = sellingCostRate
        self.remainingLoanBalance = remainingLoanBalance
    }

    var grossExitValue: Double? {
        CapRateMath.propertyValue(netOperatingIncome: exitNetOperatingIncome, capRate: exitCapRate)
    }

    var sellingCosts: Double? {
        guard let grossExitValue else { return nil }
        return grossExitValue * sellingCostRate
    }

    /// Can be negative when the remaining loan exceeds net sale proceeds.
    var netSaleProceeds: Double? {
        guard let grossExitValue, let sellingCosts else { return nil }
        let proceeds = grossExitValue - sellingCosts - remainingLoanBalance
        return proceeds.isFinite ? proceeds : nil
    }
}

/// Net present value, IRR, and equity multiple.
enum InvestmentReturn {

    static func netPresentValue(cashFlows: [Double], rate: Double) -> Double? {
        guard isFiniteNumber(rate), rate > -1.0, cashFlows.allSatisfy(isFiniteNumber) else { return nil }
        var total = 0.0
        for (time, cashFlow) in cashFlows.enumerated() {
            total += cashFlow / pow(1.0 + rate, Double(time))
        }
        return total.isFinite ? total : nil
    }

    /// Newton-Raphson IRR for a conventional cash-flow series. Returns nil if it does not converge.
    static func internalRateOfReturn(cashFlows: [Double], guess: Double = 0.10) -> Double? {
        guard cashFlows.count >= 2, cashFlows.allSatisfy(isFiniteNumber) else { return nil }
        let hasPositive = cashFlows.contains { $0 > 0 }
        let hasNegative = cashFlows.contains { $0 < 0 }
        guard hasPositive, hasNegative else { return nil }

        let guesses = [guess, 0.10, 0.0, 0.25, 0.50, -0.20, 1.0]
        for startingGuess in guesses where startingGuess.isFinite && startingGuess > -0.99 {
            if let rate = solveIRR(cashFlows: cashFlows, guess: startingGuess) {
                return rate
            }
        }
        return nil
    }

    static func equityMultiple(equityInvested: Double, distributions: [Double]) -> Double? {
        guard isFiniteNumber(equityInvested), equityInvested > 0, distributions.allSatisfy(isFiniteNumber) else {
            return nil
        }
        let multiple = distributions.reduce(0.0, +) / equityInvested
        return multiple.isFinite ? multiple : nil
    }

    /// NOI in a 1-based operating year. Year 1 returns `yearOneNOI` unchanged.
    static func projectedNOI(yearOneNOI: Double, annualGrowthRate: Double, year: Int) -> Double? {
        guard isFiniteNumber(yearOneNOI),
              isFiniteNumber(annualGrowthRate), annualGrowthRate > -1.0,
              year >= 1 else {
            return nil
        }
        let projected = yearOneNOI * pow(1.0 + annualGrowthRate, Double(year - 1))
        return projected.isFinite ? projected : nil
    }

    private static func solveIRR(cashFlows: [Double], guess: Double) -> Double? {
        var rate = guess
        let scale = cashFlows.reduce(0.0) { $0 + abs($1) }
        guard scale > 0 else { return nil }

        for _ in 0..<80 {
            var value = 0.0
            var derivative = 0.0
            for (time, cashFlow) in cashFlows.enumerated() {
                let period = Double(time)
                let discount = pow(1.0 + rate, period)
                value += cashFlow / discount
                if time > 0 {
                    derivative -= period * cashFlow / pow(1.0 + rate, period + 1.0)
                }
            }
            guard value.isFinite, derivative.isFinite, abs(derivative) > 1e-12 else { return nil }
            let next = rate - value / derivative
            guard next.isFinite, next > -0.999999 else { return nil }
            if abs(next - rate) < 1e-12 {
                guard let presentValue = netPresentValue(cashFlows: cashFlows, rate: next),
                      abs(presentValue) <= 1e-6 * scale else {
                    return nil
                }
                return next
            }
            rate = next
        }
        return nil
    }
}

/// Hold-period projection. Exit value capitalizes the exit year's trailing NOI.
struct HoldPeriodAnalysis: Equatable {
    let yearOneNOI: Double
    let noiGrowthRate: Double
    let years: Int
    let annualDebtService: Double
    let annualCapitalReserve: Double
    let exitCapRate: Double
    let sellingCostRate: Double
    let remainingLoanBalance: Double
    let equityInvested: Double

    init?(yearOneNOI: Double,
          noiGrowthRate: Double,
          years: Int,
          annualDebtService: Double,
          annualCapitalReserve: Double,
          exitCapRate: Double,
          sellingCostRate: Double,
          remainingLoanBalance: Double,
          equityInvested: Double) {
        guard isFiniteNumber(yearOneNOI),
              isFiniteNumber(noiGrowthRate), noiGrowthRate > -1.0,
              years > 0,
              isFiniteNumber(annualDebtService), annualDebtService >= 0,
              isFiniteNumber(annualCapitalReserve), annualCapitalReserve >= 0,
              isFiniteNumber(exitCapRate), exitCapRate > 0,
              isFiniteNumber(sellingCostRate), (0.0...1.0).contains(sellingCostRate),
              isFiniteNumber(remainingLoanBalance), remainingLoanBalance >= 0,
              isFiniteNumber(equityInvested), equityInvested > 0 else {
            return nil
        }
        self.yearOneNOI = yearOneNOI
        self.noiGrowthRate = noiGrowthRate
        self.years = years
        self.annualDebtService = annualDebtService
        self.annualCapitalReserve = annualCapitalReserve
        self.exitCapRate = exitCapRate
        self.sellingCostRate = sellingCostRate
        self.remainingLoanBalance = remainingLoanBalance
        self.equityInvested = equityInvested
    }

    func netOperatingIncome(inYear year: Int) -> Double? {
        guard (1...years).contains(year) else { return nil }
        return InvestmentReturn.projectedNOI(
            yearOneNOI: yearOneNOI,
            annualGrowthRate: noiGrowthRate,
            year: year
        )
    }

    func beforeTaxCashFlow(inYear year: Int) -> Double? {
        guard let noi = netOperatingIncome(inYear: year) else { return nil }
        return noi - annualDebtService - annualCapitalReserve
    }

    var trailingExitNOI: Double? {
        netOperatingIncome(inYear: years)
    }

    var netSaleProceeds: Double? {
        guard let trailingExitNOI else { return nil }
        return SaleReversion(
            exitNetOperatingIncome: trailingExitNOI,
            exitCapRate: exitCapRate,
            sellingCostRate: sellingCostRate,
            remainingLoanBalance: remainingLoanBalance
        )?.netSaleProceeds
    }

    func operatingDistributions() -> [Double]? {
        var distributions: [Double] = []
        for year in 1...years {
            guard let cashFlow = beforeTaxCashFlow(inYear: year) else { return nil }
            distributions.append(cashFlow)
        }
        return distributions
    }

    var equityMultiple: Double? {
        guard let operatingDistributions = operatingDistributions(), let netSaleProceeds else { return nil }
        return InvestmentReturn.equityMultiple(
            equityInvested: equityInvested,
            distributions: operatingDistributions + [netSaleProceeds]
        )
    }

    /// Index 0 is cash invested. The final year includes net sale proceeds.
    func investorCashFlows() -> [Double]? {
        guard var distributions = operatingDistributions(), let netSaleProceeds else { return nil }
        guard let last = distributions.indices.last else { return nil }
        distributions[last] += netSaleProceeds
        return [-equityInvested] + distributions
    }

    func internalRateOfReturn() -> Double? {
        guard let cashFlows = investorCashFlows() else { return nil }
        return InvestmentReturn.internalRateOfReturn(cashFlows: cashFlows)
    }
}
