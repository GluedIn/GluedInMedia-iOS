//
//  Alert.swift
//  MediaSampleApp
//
//  Created by Abhishek Mishra on 10/09/25.
//

import Foundation
import ToastViewSwift


class Alert {
    class func showToast(message: String?) -> () {
        let toast = Toast.text(message ?? "")
        toast.show()
    }
}
