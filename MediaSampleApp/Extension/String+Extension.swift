//
//  String+Extension.swift
//  GluedIn-Demo
//
//  Created by Ashish Verma on 12/03/25.
//

import Foundation

extension String {
    func localized(comment: String = "") -> String {
        return NSLocalizedString(self, comment: comment)
    }

    func localizedWithDefaultValue(defaultValue: String, comment: String = "") -> String {
        return NSLocalizedString(
            self,
            tableName: nil,
            bundle: Bundle.main,
            value: defaultValue,
            comment: comment
        )
    }
}
