import UIKit
import ToastViewSwift

class ToastManager {
    
    static let shared = ToastManager()

    private init() {}

    /// Displays a toast message
    /// - Parameter text: Message to show in the toast
    func showToast(text: String) {
        let toast = Toast.text(text)
        toast.show()
    }
}
