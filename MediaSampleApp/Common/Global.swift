//
//  Global.swift
//  MediaSampleApp
//
//  Created by Abhishek Mishra on 10/09/25.
//

import Foundation


/// A singleton class providing global utility methods.
class Global {
    
    /// The shared singleton instance.
    static let shared = Global()
    
    /// Formats a raw price string into a clean display format with proper symbol.
    /// Supports inputs like: "SGD 5", "USD 12.50", "INR 199", "$ 5", "€9.99".
    func formatPrice(from raw: String?) -> String? {
        guard let raw = raw, !raw.isEmpty else { return nil }

        let (codeOrSymbol, amountString) = parseCurrencyAndAmount(from: raw)
        guard let amountString = amountString else { return nil }

        let symbol: String
        if let code = codeOrSymbol, code.count == 3 { // currency code like SGD, USD, INR
            symbol = symbolForCurrencyCode(code)
        } else {
            // Already a symbol like $, €, ₹, £ — keep as-is
            symbol = codeOrSymbol ?? ""
        }

        let cleanedAmount = normalizeAmountString(amountString)
        return symbol.isEmpty ? cleanedAmount : "\(symbol) \(cleanedAmount)"
    }
    
    /// Extracts a currency code or symbol and the numeric amount from a raw price string.
    private func parseCurrencyAndAmount(from raw: String) -> (codeOrSymbol: String?, amount: String?) {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)

        // Case 1: Starts with a 3-letter currency code (e.g., SGD 5, USD12.5)
        if let match = trimmed.range(of: "^[A-Za-z]{3}", options: .regularExpression) {
            let code = String(trimmed[match]).uppercased()
            if let numRange = trimmed.range(of: "[0-9]+(?:[.,][0-9]{1,2})?", options: .regularExpression) {
                let num = String(trimmed[numRange])
                return (code, num)
            }
            return (code, nil)
        }

        // Case 2: Starts with a common symbol ($, €, ₹, £)
        if let symRange = trimmed.range(of: "^[\u{0024}\u{20AC}\u{20B9}\u{00A3}]", options: .regularExpression) {
            let sym = String(trimmed[symRange])
            if let numRange = trimmed.range(of: "[0-9]+(?:[.,][0-9]{1,2})?", options: .regularExpression) {
                let num = String(trimmed[numRange])
                return (sym, num)
            }
            return (sym, nil)
        }

        // Fallback: find any number
        if let numRange = trimmed.range(of: "[0-9]+(?:[.,][0-9]{1,2})?", options: .regularExpression) {
            let num = String(trimmed[numRange])
            return (nil, num)
        }

        return (nil, nil)
    }
    
    /// Maps ISO 4217 code to a currency symbol. Includes SGD → S$ special handling.
    private func symbolForCurrencyCode(_ code: String) -> String {
        let map: [String: String] = [
            "USD": "$", "CAD": "$", "AUD": "$", "NZD": "$", "HKD": "$",
            "SGD": "S$", // Singapore Dollar special case
            "EUR": "€", "INR": "₹", "GBP": "£", "JPY": "¥", "CNY": "¥", "KRW": "₩",
            "AED": "د.إ", "SAR": "﷼", "RUB": "₽", "TRY": "₺", "THB": "฿"
        ]
        if let s = map[code] { return s }

        // Fallback to NumberFormatter for uncommon codes
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = code
        f.locale = Locale(identifier: "en_US_POSIX")
        return f.currencySymbol ?? code
    }
    
    /// Formats amount string to always show two decimals, e.g. "1" -> "1.00", "12.5" -> "12.50"
    private func normalizeAmountString(_ s: String) -> String {
        var str = s.replacingOccurrences(of: ",", with: ".")
        if let value = Double(str) {
            let nf = NumberFormatter()
            nf.numberStyle = .decimal
            nf.decimalSeparator = "."
            nf.minimumFractionDigits = 2   // force 2 decimals
            nf.maximumFractionDigits = 2
            if let out = nf.string(from: NSNumber(value: value)) {
                str = out
            }
        }
        return str
    }
    
}

struct VariantVM {
    let id: String
    let title: String
    let price: String
    let available: Bool
    let imageURL: URL?
}

struct ProductVM {
    let id: String
    let title: String
    let handle: String
    let description: String
    let imageURL: URL?
    let minPrice: String
    let maxPrice: String
    let variants: [VariantVM]
    let variantName: String?
}
