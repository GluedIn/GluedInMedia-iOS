//
//  IAPManager.swift
//  GluedIn
//
//  Created by Ashish on 23/11/25.
//

import Foundation
import StoreKit
import GluedInCoreSDK

final class IAPManager: NSObject {

    static let shared = IAPManager()

    private override init() {}

    // MARK: - Public (Consumable / Non-consumable)

    func fetchPrices(
        for productIDs: [String],
        completion: @escaping ([SkuPriceInfo]) -> Void,
        onError: ((Error?) -> Void)? = nil
    ) {
        let ids = Array(Set(productIDs.compactMap { $0.isEmpty ? nil : $0 }))
        guard !ids.isEmpty else { completion([]); return }

        if #available(iOS 15.0, *) {
            fetchPricesSK2(ids, completion: completion, onError: onError)
        } else {
            fetchPricesSK1(ids, completion: completion, onError: onError)
        }
    }

    // MARK: - Public (Auto-renewable Subscriptions)

    func fetchSubscriptionInfos(
        for productIDs: [String],
        completion: @escaping ([SubscriptionSkuInfo]) -> Void,
        onError: ((Error?) -> Void)? = nil
    ) {
        let ids = Array(Set(productIDs.compactMap { $0.isEmpty ? nil : $0 }))
        guard !ids.isEmpty else { completion([]); return }

        if #available(iOS 15.0, *) {
            fetchSubscriptionsSK2(ids, completion: completion, onError: onError)
        } else {
            fetchSubscriptionsSK1(ids, completion: completion, onError: onError)
        }
    }
}

// MARK: - StoreKit 1 (iOS 12+)
extension IAPManager: SKProductsRequestDelegate {

    private struct SK1RequestContext {
        enum Kind { case iap, subscription }
        let kind: Kind
        let completionIAP: (([SkuPriceInfo]) -> Void)?
        let completionSub: (([SubscriptionSkuInfo]) -> Void)?
        let onError: ((Error?) -> Void)?
    }

    private static var contexts: [ObjectIdentifier: SK1RequestContext] = [:]

    private func fetchPricesSK1(
        _ ids: [String],
        completion: @escaping ([SkuPriceInfo]) -> Void,
        onError: ((Error?) -> Void)?
    ) {
        let req = SKProductsRequest(productIdentifiers: Set(ids))
        let key = ObjectIdentifier(req)
        Self.contexts[key] = SK1RequestContext(kind: .iap, completionIAP: completion, completionSub: nil, onError: onError)
        req.delegate = self
        req.start()
    }

    private func fetchSubscriptionsSK1(
        _ ids: [String],
        completion: @escaping ([SubscriptionSkuInfo]) -> Void,
        onError: ((Error?) -> Void)?
    ) {
        let req = SKProductsRequest(productIdentifiers: Set(ids))
        let key = ObjectIdentifier(req)
        Self.contexts[key] = SK1RequestContext(kind: .subscription, completionIAP: nil, completionSub: completion, onError: onError)
        req.delegate = self
        req.start()
    }

    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        let key = ObjectIdentifier(request)
        guard let ctx = Self.contexts[key] else { return }
        Self.contexts[key] = nil

        let formatter = NumberFormatter()
        formatter.numberStyle = .currency

        switch ctx.kind {
        case .iap:
            var result: [SkuPriceInfo] = []
            for product in response.products {
                formatter.locale = product.priceLocale
                let localizedPrice = formatter.string(from: product.price) ?? ""
                let symbol = formatter.currencySymbol ?? ""
                let amount = product.price.doubleValue

                result.append(
                    SkuPriceInfo(
                        skuId: product.productIdentifier,
                        currencySymbol: symbol,
                        amount: amount,
                        localizedPrice: localizedPrice
                    )
                )
            }
            ctx.completionIAP?(result)

        case .subscription:
            var result: [SubscriptionSkuInfo] = []
            for product in response.products {
                formatter.locale = product.priceLocale
                let localizedPrice = formatter.string(from: product.price) ?? ""
                let symbol = formatter.currencySymbol ?? ""
                let amount = product.price.doubleValue

                // ✅ Duration from StoreKit1
                let (value, unit, text) = Self.subscriptionPeriodInfo(from: product.subscriptionPeriod)

                result.append(
                    SubscriptionSkuInfo(
                        skuId: product.productIdentifier,
                        currencySymbol: symbol,
                        amount: amount,
                        localizedPrice: localizedPrice,
                        periodValue: value,
                        periodUnit: unit,
                        periodText: text
                    )
                )
            }
            ctx.completionSub?(result)
        }
    }

    func request(_ request: SKRequest, didFailWithError error: Error) {
        let key = ObjectIdentifier(request)
        let ctx = Self.contexts[key]
        Self.contexts[key] = nil
        ctx?.onError?(error)
    }

    private static func subscriptionPeriodInfo(
        from period: SKProductSubscriptionPeriod?
    ) -> (Int, String, String) {
        
        guard let p = period else { return (0, "UNKNOWN", "") }

        let units = p.numberOfUnits
        
        func localized(key: String, fallback: String) -> String {
            return Global.shared.getLocalisedValue(
                localisedKey: key,
                defaultString: fallback
            )
        }

        switch p.unit {
            
        case .year:
            let unitText = units == 1
                ? localized(key: "gluedin_subscription_year", fallback: "Year")
                : localized(key: "gluedin_subscription_years", fallback: "Years")
            
            return (units, "YEAR", "\(units) \(unitText)")

        case .day:
            let unitText = units == 1
                ? localized(key: "gluedin_subscription_day", fallback: "Day")
                : localized(key: "gluedin_subscription_days", fallback: "Days")
            
            return (units, "DAY", "\(units) \(unitText)")

        case .week:
            let days = units * 7
            let unitText = days == 1
                ? localized(key: "gluedin_subscription_day", fallback: "Day")
                : localized(key: "gluedin_subscription_days", fallback: "Days")
            
            return (days, "DAY", "\(days) \(unitText)")

        case .month:
            // ⚠️ Approximation: 30 days per month
            let days = units * 30
            let unitText = days == 1
                ? localized(key: "gluedin_subscription_day", fallback: "Day")
                : localized(key: "gluedin_subscription_days", fallback: "Days")
            
            return (days, "DAY", "\(days) \(unitText)")

        @unknown default:
            return (0, "UNKNOWN", "")
        }
    }
}

// MARK: - StoreKit 2 (iOS 15+)
@available(iOS 15.0, *)
extension IAPManager {

    private func fetchPricesSK2(
        _ ids: [String],
        completion: @escaping ([SkuPriceInfo]) -> Void,
        onError: ((Error?) -> Void)?
    ) {
        Task {
            do {
                let products = try await Product.products(for: ids)
                let result: [SkuPriceInfo] = products.map { p in
                    let (symbol, amount) = Self.currencyInfo(from: p)
                    return SkuPriceInfo(
                        skuId: p.id,
                        currencySymbol: symbol,
                        amount: amount,
                        localizedPrice: p.displayPrice
                    )
                }

                DispatchQueue.main.async { completion(result) }
            } catch {
                DispatchQueue.main.async { onError?(error) }
            }
        }
    }

    private func fetchSubscriptionsSK2(
        _ ids: [String],
        completion: @escaping ([SubscriptionSkuInfo]) -> Void,
        onError: ((Error?) -> Void)?
    ) {
        Task {
            do {
                let products = try await Product.products(for: ids)
                let subs = products.compactMap { $0.subscription == nil ? nil : $0 }

                let result: [SubscriptionSkuInfo] = subs.map { p in
                    let (symbol, amount) = Self.currencyInfo(from: p)

                    let (value, unit, text) = Self.subscriptionPeriodInfo(from: p.subscription?.subscriptionPeriod)

                    return SubscriptionSkuInfo(
                        skuId: p.id,
                        currencySymbol: symbol,
                        amount: amount,
                        localizedPrice: p.displayPrice,
                        periodValue: value,
                        periodUnit: unit,
                        periodText: text
                    )
                }

                DispatchQueue.main.async { completion(result) }
            } catch {
                DispatchQueue.main.async { onError?(error) }
            }
        }
    }

    private static func currencyInfo(from product: Product) -> (String, Double) {
        // displayPrice is already localized, but we also extract numeric+symbol
        let nf = NumberFormatter()
        nf.numberStyle = .currency
        nf.locale = product.priceFormatStyle.locale

        let amount = NSDecimalNumber(decimal: product.price).doubleValue
        let symbol = nf.currencySymbol ?? ""
        return (symbol, amount)
    }
    
    private static func subscriptionPeriodInfo(
        from period: Product.SubscriptionPeriod?
    ) -> (Int, String, String) {
        
        guard let p = period else { return (0, "UNKNOWN", "") }

        let value = p.value
        
        func localized(key: String, fallback: String) -> String {
            return Global.shared.getLocalisedValue(
                localisedKey: key,
                defaultString: fallback
            )
        }
        
        switch p.unit {
            
        case .year:
            let unitText = value == 1
                ? localized(key: "gluedin_subscription_year", fallback: "Year")
                : localized(key: "gluedin_subscription_years", fallback: "Years")
            
            return (value, "YEAR", "\(value) \(unitText)")

        case .day:
            let unitText = value == 1
                ? localized(key: "gluedin_subscription_day", fallback: "Day")
                : localized(key: "gluedin_subscription_days", fallback: "Days")
            
            return (value, "DAY", "\(value) \(unitText)")

        case .week:
            let days = value * 7
            let unitText = days == 1
                ? localized(key: "gluedin_subscription_day", fallback: "Day")
                : localized(key: "gluedin_subscription_days", fallback: "Days")
            
            return (days, "DAY", "\(days) \(unitText)")

        case .month:
            // ⚠️ Approximation: 30 days per month
            let days = value * 30
            let unitText = days == 1
                ? localized(key: "gluedin_subscription_day", fallback: "Day")
                : localized(key: "gluedin_subscription_days", fallback: "Days")
            
            return (days, "DAY", "\(days) \(unitText)")

        @unknown default:
            return (0, "UNKNOWN", "")
        }
    }
}

@available(iOS 15.0, *)
enum SK2Verifier {
    static func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .verified(let safe):
            return safe
        case .unverified:
            throw NSError(
                domain: "StoreKit2",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Unverified transaction"]
            )
        }
    }
}
