//
//  REITDerivatives.swift
//  FaithQuest
//
//  REIT investing multiples and derivative payoffs.
//  Includes cap-rate swaps, total-return swaps, dividend-adjusted equity options,
//  mortgage IO/PO strips, and plain-vanilla interest-rate swaps used by mortgage REITs.
//
//  Rates are decimals. Option pricing uses the Black-Scholes-Merton dividend yield model
//  because listed REITs distribute a large share of taxable income.
//

import Foundation

/// NAREIT-style funds from operations and the ratios used to price REIT equity.
struct REITFundamentals: Equatable {
    let netIncome: Double
    let realEstateDepreciationAndAmortization: Double
    let gainsOnPropertySales: Double
    let lossesOnPropertySales: Double
    let recurringCapitalExpenditures: Double
    let straightLineRentAdjustment: Double
    let dilutedShares: Double
    let annualDividendsPaid: Double
    let sharePrice: Double
    let portfolioNOI: Double
    let grossAssetValue: Double
    let totalLiabilities: Double
    let totalDebt: Double
    let cash: Double

    init?(netIncome: Double,
          realEstateDepreciationAndAmortization: Double,
          gainsOnPropertySales: Double,
          lossesOnPropertySales: Double,
          recurringCapitalExpenditures: Double,
          straightLineRentAdjustment: Double,
          dilutedShares: Double,
          annualDividendsPaid: Double,
          sharePrice: Double,
          portfolioNOI: Double,
          grossAssetValue: Double,
          totalLiabilities: Double,
          totalDebt: Double,
          cash: Double) {
        let values = [
            netIncome, realEstateDepreciationAndAmortization, gainsOnPropertySales,
            lossesOnPropertySales, recurringCapitalExpenditures, straightLineRentAdjustment,
            dilutedShares, annualDividendsPaid, sharePrice, portfolioNOI,
            grossAssetValue, totalLiabilities, totalDebt, cash
        ]
        guard values.allSatisfy(\.isFinite),
              realEstateDepreciationAndAmortization >= 0,
              gainsOnPropertySales >= 0,
              lossesOnPropertySales >= 0,
              recurringCapitalExpenditures >= 0,
              dilutedShares > 0,
              annualDividendsPaid >= 0,
              sharePrice > 0,
              grossAssetValue >= 0,
              totalLiabilities >= 0,
              totalDebt >= 0,
              cash >= 0 else {
            return nil
        }
        self.netIncome = netIncome
        self.realEstateDepreciationAndAmortization = realEstateDepreciationAndAmortization
        self.gainsOnPropertySales = gainsOnPropertySales
        self.lossesOnPropertySales = lossesOnPropertySales
        self.recurringCapitalExpenditures = recurringCapitalExpenditures
        self.straightLineRentAdjustment = straightLineRentAdjustment
        self.dilutedShares = dilutedShares
        self.annualDividendsPaid = annualDividendsPaid
        self.sharePrice = sharePrice
        self.portfolioNOI = portfolioNOI
        self.grossAssetValue = grossAssetValue
        self.totalLiabilities = totalLiabilities
        self.totalDebt = totalDebt
        self.cash = cash
    }

    /// Net income + real estate depreciation and amortization + losses - gains.
    var fundsFromOperations: Double {
        netIncome
            + realEstateDepreciationAndAmortization
            + lossesOnPropertySales
            - gainsOnPropertySales
    }

    /// FFO minus recurring capital expenditures and the straight-line rent adjustment.
    var adjustedFundsFromOperations: Double {
        fundsFromOperations - recurringCapitalExpenditures - straightLineRentAdjustment
    }

    var fundsFromOperationsPerShare: Double {
        fundsFromOperations / dilutedShares
    }

    var adjustedFundsFromOperationsPerShare: Double {
        adjustedFundsFromOperations / dilutedShares
    }

    var priceToFundsFromOperations: Double? {
        let perShare = fundsFromOperationsPerShare
        guard perShare > 0 else { return nil }
        return sharePrice / perShare
    }

    var dividendPerShare: Double {
        annualDividendsPaid / dilutedShares
    }

    var dividendYield: Double {
        dividendPerShare / sharePrice
    }

    var adjustedFundsPayoutRatio: Double? {
        let affo = adjustedFundsFromOperations
        guard affo > 0 else { return nil }
        return annualDividendsPaid / affo
    }

    var netAssetValue: Double {
        grossAssetValue - totalLiabilities
    }

    var netAssetValuePerShare: Double {
        netAssetValue / dilutedShares
    }

    /// (price - NAV) / NAV. Nil when NAV per share is not positive.
    var premiumToNetAssetValue: Double? {
        let nav = netAssetValuePerShare
        guard nav > 0 else { return nil }
        return (sharePrice - nav) / nav
    }

    var equityMarketCapitalization: Double {
        sharePrice * dilutedShares
    }

    var netDebt: Double {
        totalDebt - cash
    }

    var enterpriseValue: Double {
        equityMarketCapitalization + netDebt
    }

    /// Portfolio NOI / enterprise value. This is the cap rate implied by the REIT's market price.
    var impliedCapRate: Double? {
        CapRateMath.capRate(netOperatingIncome: portfolioNOI, propertyValue: enterpriseValue)
    }
}

/// Single-period cap-rate swap on a property-value notional.
struct CapRateSwap: Equatable {
    let notional: Double
    let fixedCapRate: Double
    let yearFraction: Double

    init?(notional: Double, fixedCapRate: Double, yearFraction: Double) {
        guard notional.isFinite, notional != 0,
              fixedCapRate.isFinite, fixedCapRate >= 0,
              yearFraction.isFinite, yearFraction > 0 else {
            return nil
        }
        self.notional = notional
        self.fixedCapRate = fixedCapRate
        self.yearFraction = yearFraction
    }

    /// Settlement to the fixed payer (floating receiver).
    /// Positive when the realized cap rate is above the fixed rate.
    func fixedPayerSettlement(floatingCapRate: Double) -> Double? {
        guard floatingCapRate.isFinite else { return nil }
        let settlement = notional * (floatingCapRate - fixedCapRate) * yearFraction
        return settlement.isFinite ? settlement : nil
    }
}

/// Property and REIT index return decomposition.
enum PropertyTotalReturn {

    static func incomeReturn(netOperatingIncome: Double, startValue: Double) -> Double? {
        CapRateMath.capRate(netOperatingIncome: netOperatingIncome, propertyValue: startValue)
    }

    static func capitalReturn(startValue: Double, endValue: Double) -> Double? {
        guard startValue.isFinite, startValue > 0, endValue.isFinite, endValue >= 0 else { return nil }
        let change = (endValue - startValue) / startValue
        return change.isFinite ? change : nil
    }

    static func totalReturn(incomeReturn: Double, capitalReturn: Double) -> Double? {
        guard incomeReturn.isFinite, capitalReturn.isFinite else { return nil }
        let total = incomeReturn + capitalReturn
        return total.isFinite ? total : nil
    }

    /// Capital return when NOI is unchanged and value is recapitalized from `startCapRate` to `endCapRate`.
    static func capitalReturnFromCapRates(startCapRate: Double, endCapRate: Double) -> Double? {
        CapRateMath.valueChangeFromCapRateMove(startCapRate: startCapRate, endCapRate: endCapRate)
    }
}

/// Total-return swap: the receiver gets asset total return and pays a funding rate.
struct REITTotalReturnSwap: Equatable {
    let notional: Double
    let fundingRate: Double
    let yearFraction: Double

    init?(notional: Double, fundingRate: Double, yearFraction: Double) {
        guard notional.isFinite, notional != 0,
              fundingRate.isFinite,
              yearFraction.isFinite, yearFraction > 0 else {
            return nil
        }
        self.notional = notional
        self.fundingRate = fundingRate
        self.yearFraction = yearFraction
    }

    func receiverPayoff(assetTotalReturn: Double) -> Double? {
        guard assetTotalReturn.isFinite else { return nil }
        let payoff = notional * (assetTotalReturn - fundingRate * yearFraction)
        return payoff.isFinite ? payoff : nil
    }
}

/// Abramowitz and Stegun normal CDF. Max absolute erf error is about 1.5e-7.
enum NormalDistribution {
    static func erf(_ value: Double) -> Double {
        let sign: Double = value < 0 ? -1.0 : 1.0
        let magnitude = abs(value)
        let t = 1.0 / (1.0 + 0.3275911 * magnitude)
        let a1 = 0.254829592
        let a2 = -0.284496736
        let a3 = 1.421413741
        let a4 = -1.453152027
        let a5 = 1.061405429
        let polynomial = ((((a5 * t + a4) * t + a3) * t + a2) * t + a1) * t
        let result = 1.0 - polynomial * exp(-magnitude * magnitude)
        return sign * result
    }

    static func cumulative(_ value: Double) -> Double {
        0.5 * (1.0 + erf(value / sqrt(2.0)))
    }
}

/// European option on a dividend-paying REIT share.
struct REITOption: Equatable {
    enum Right: Equatable {
        case call
        case put
    }

    let spot: Double
    let strike: Double
    let timeToExpiry: Double
    let riskFreeRate: Double
    let dividendYield: Double
    let volatility: Double

    init?(spot: Double,
          strike: Double,
          timeToExpiry: Double,
          riskFreeRate: Double,
          dividendYield: Double,
          volatility: Double) {
        guard spot.isFinite, spot > 0,
              strike.isFinite, strike > 0,
              timeToExpiry.isFinite, timeToExpiry >= 0,
              riskFreeRate.isFinite,
              dividendYield.isFinite,
              volatility.isFinite, volatility >= 0 else {
            return nil
        }
        self.spot = spot
        self.strike = strike
        self.timeToExpiry = timeToExpiry
        self.riskFreeRate = riskFreeRate
        self.dividendYield = dividendYield
        self.volatility = volatility
    }

    func price(right: Right) -> Double? {
        if timeToExpiry == 0 {
            return intrinsicValue(right: right)
        }
        if volatility == 0 {
            return zeroVolatilityPrice(right: right)
        }
        guard let d1, let d2 else { return nil }
        let discountedSpot = spot * exp(-dividendYield * timeToExpiry)
        let discountedStrike = strike * exp(-riskFreeRate * timeToExpiry)
        let price: Double
        switch right {
        case .call:
            price = discountedSpot * NormalDistribution.cumulative(d1)
                - discountedStrike * NormalDistribution.cumulative(d2)
        case .put:
            price = discountedStrike * NormalDistribution.cumulative(-d2)
                - discountedSpot * NormalDistribution.cumulative(-d1)
        }
        return price.isFinite ? price : nil
    }

    /// Call delta is e^{-qT} N(d1). Put delta is e^{-qT} (N(d1) - 1).
    func delta(right: Right) -> Double? {
        guard timeToExpiry > 0, volatility > 0, let d1 else { return nil }
        let discount = exp(-dividendYield * timeToExpiry)
        switch right {
        case .call:
            return discount * NormalDistribution.cumulative(d1)
        case .put:
            return discount * (NormalDistribution.cumulative(d1) - 1.0)
        }
    }

    func intrinsicValue(right: Right) -> Double {
        switch right {
        case .call:
            return max(spot - strike, 0)
        case .put:
            return max(strike - spot, 0)
        }
    }

    /// Discounted forward intrinsic value. A lower bound for positive volatility.
    func discountedForwardIntrinsic(right: Right) -> Double {
        let forwardDifference = spot * exp(-dividendYield * timeToExpiry)
            - strike * exp(-riskFreeRate * timeToExpiry)
        switch right {
        case .call:
            return max(forwardDifference, 0)
        case .put:
            return max(-forwardDifference, 0)
        }
    }

    private var d1: Double? {
        guard timeToExpiry > 0, volatility > 0 else { return nil }
        let numerator = log(spot / strike)
            + (riskFreeRate - dividendYield + 0.5 * volatility * volatility) * timeToExpiry
        let denominator = volatility * sqrt(timeToExpiry)
        let value = numerator / denominator
        return value.isFinite ? value : nil
    }

    private var d2: Double? {
        guard let d1, timeToExpiry > 0, volatility > 0 else { return nil }
        return d1 - volatility * sqrt(timeToExpiry)
    }

    private func zeroVolatilityPrice(right: Right) -> Double {
        discountedForwardIntrinsic(right: right)
    }
}

/// Interest-only and principal-only strips of a fixed-rate mortgage.
struct MortgageDerivativeStrip: Equatable {
    let terms: MortgageTerms
    /// Nominal annual discount rate, compounded at the mortgage payment frequency.
    let annualDiscountRate: Double

    init?(terms: MortgageTerms, annualDiscountRate: Double) {
        guard annualDiscountRate.isFinite, annualDiscountRate >= 0 else { return nil }
        self.terms = terms
        self.annualDiscountRate = annualDiscountRate
    }

    func presentValues() -> (interestOnly: Double, principalOnly: Double, mortgage: Double)? {
        let payment = terms.periodicPayment()
        guard payment.isFinite else { return nil }
        let coupon = terms.periodicRate
        let discountRate = annualDiscountRate / Double(terms.paymentsPerYear)
        guard discountRate.isFinite else { return nil }

        var interestOnly = 0.0
        var principalOnly = 0.0
        var balance = terms.principal
        for period in 1...terms.numberOfPayments {
            let interest = balance * coupon
            let principalPaid = payment - interest
            let discount = pow(1.0 + discountRate, -Double(period))
            interestOnly += interest * discount
            principalOnly += principalPaid * discount
            balance -= principalPaid
        }
        guard interestOnly.isFinite, principalOnly.isFinite else { return nil }
        return (interestOnly, principalOnly, interestOnly + principalOnly)
    }
}

/// Discount factors on swap payment dates. Spot discount factor is 1.
struct DiscountCurve: Equatable {
    let paymentDiscountFactors: [Double]
    let yearFractions: [Double]

    init?(paymentDiscountFactors: [Double], yearFractions: [Double]) {
        guard paymentDiscountFactors.count == yearFractions.count, !paymentDiscountFactors.isEmpty,
              paymentDiscountFactors.allSatisfy({ $0.isFinite && $0 > 0 }),
              yearFractions.allSatisfy({ $0.isFinite && $0 > 0 }) else {
            return nil
        }
        self.paymentDiscountFactors = paymentDiscountFactors
        self.yearFractions = yearFractions
    }

    var annuity: Double? {
        let value = zip(paymentDiscountFactors, yearFractions).reduce(0.0) { partial, pair in
            partial + pair.1 * pair.0
        }
        return value.isFinite && value > 0 ? value : nil
    }

    /// Simply compounded forward rate for each payment interval.
    func forwardRates() -> [Double]? {
        var forwards: [Double] = []
        var previousDiscount = 1.0
        for (discount, yearFraction) in zip(paymentDiscountFactors, yearFractions) {
            let forward = (previousDiscount / discount - 1.0) / yearFraction
            guard forward.isFinite else { return nil }
            forwards.append(forward)
            previousDiscount = discount
        }
        return forwards
    }

    /// Par fixed rate: (1 - DF_last) / annuity.
    func parSwapRate() -> Double? {
        guard let annuity, let last = paymentDiscountFactors.last else { return nil }
        let rate = (1.0 - last) / annuity
        return rate.isFinite ? rate : nil
    }
}

/// Plain-vanilla interest-rate swap. Value is to the receiver of the fixed rate.
struct InterestRateSwap: Equatable {
    let notional: Double
    let fixedRate: Double
    let curve: DiscountCurve

    init?(notional: Double, fixedRate: Double, curve: DiscountCurve) {
        guard notional.isFinite, notional != 0, fixedRate.isFinite else { return nil }
        self.notional = notional
        self.fixedRate = fixedRate
        self.curve = curve
    }

    /// notional * (K * annuity - (1 - DF_last))
    func fixedReceiverValue() -> Double? {
        guard let annuity = curve.annuity, let last = curve.paymentDiscountFactors.last else { return nil }
        let value = notional * (fixedRate * annuity - (1.0 - last))
        return value.isFinite ? value : nil
    }

    /// Same value rebuilt from forward rates. Used to check the closed form.
    func fixedReceiverValueFromForwards() -> Double? {
        guard let forwards = curve.forwardRates() else { return nil }
        var value = 0.0
        for index in forwards.indices {
            let yearFraction = curve.yearFractions[index]
            let discount = curve.paymentDiscountFactors[index]
            value += notional * yearFraction * discount * (fixedRate - forwards[index])
        }
        return value.isFinite ? value : nil
    }
}

/// Gordon growth valuation for a REIT equity claim.
enum REITValuation {
    static func gordonGrowthPrice(nextDividend: Double,
                                   requiredReturn: Double,
                                   growthRate: Double) -> Double? {
        guard nextDividend.isFinite, nextDividend >= 0,
              requiredReturn.isFinite, growthRate.isFinite,
              requiredReturn > growthRate else {
            return nil
        }
        let price = nextDividend / (requiredReturn - growthRate)
        return price.isFinite ? price : nil
    }

    static func gordonImpliedReturn(price: Double, nextDividend: Double, growthRate: Double) -> Double? {
        guard price.isFinite, price > 0,
              nextDividend.isFinite, nextDividend >= 0,
              growthRate.isFinite else {
            return nil
        }
        let requiredReturn = nextDividend / price + growthRate
        return requiredReturn.isFinite ? requiredReturn : nil
    }

    /// Macaulay duration of a growing perpetuity is 1 / (required return - growth).
    static func perpetuityDuration(requiredReturn: Double, growthRate: Double) -> Double? {
        guard requiredReturn.isFinite, growthRate.isFinite, requiredReturn > growthRate else { return nil }
        let duration = 1.0 / (requiredReturn - growthRate)
        return duration.isFinite ? duration : nil
    }
}
