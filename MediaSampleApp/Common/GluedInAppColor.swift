//
//  GluedInAppColor.swift
//  GluedIn
//
//  Created by Amit Choudhary on 24/07/24.
//

import Foundation
import UIKit

// MARK: - This class used to set UIColor globaly thoughout the Application.
class GluedInAppColor {
    class func setNavigationColor() {
        UINavigationBar.appearance().barTintColor = .black
                  UINavigationBar.appearance().tintColor = .white
                  UINavigationBar.appearance().titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
                  UINavigationBar.appearance().isTranslucent = true
    }
    
    class var userNameAlreadyExist: UIColor {
        return  UIColor(red: 255.0/255.0, green: 0/255.0, blue: 0/255.0, alpha: 1.0)
    }
  
    class var colorSeparatorLine_darkGray: UIColor {
        return  UIColor(red: 43.0/255.0, green: 43.0/255.0, blue: 43.0/255.0, alpha: 1.0)
    }
    
    class var colorWhite: UIColor {
        return #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
    }
    
    class var colorThemeBlue: UIColor {//0e8aee
       return UIColor(red: 14.0/255.0, green: 138.0/255.0, blue: 238.0/255.0, alpha: 1.0)
        //return  UIColor(red: 0.0/255.0, green: 168.0/255.0, blue: 222.0/255.0, alpha: 1.0)
    }
    
    class var colorThemeDarkBlue: UIColor {//005D92
           return  UIColor(red: 0.0/255.0, green: 93.0/255.0, blue: 146.0/255.0, alpha: 1.0)
       }
    class var colorBlack: UIColor {
        return  UIColor(red: 0.0/255.0, green: 0.0/255.0, blue: 0.0/255.0, alpha: 1.0)
    }
    
    class var filterSelectedBorderColor: UIColor {
        return  UIColor(red: 255.0/255.0, green: 255.0/255.0, blue: 255.0/255.0, alpha: 0.8)
       }
    
   
    class var HandelColor: UIColor {
     return  UIColor(red: 255.0/255.0, green: 255.0/255.0, blue: 255.0/255.0, alpha: 0.08)
    }

    class var whiteWithAlphaColor: UIColor {
           return  UIColor(red: 255.0/255.0, green: 255.0/255.0, blue: 255.0/255.0, alpha: 0.6)
       }
    
    class var dropdownItemTextColor_darkGray: UIColor {
              return  UIColor(red: 74.0/255.0, green: 74.0/255.0, blue: 74.0/255.0, alpha: 1.0)
          }
    
   class var placeHolderColor_lightGray: UIColor {
                return  UIColor(red: 149.0/255.0, green: 149.0/255.0, blue: 149.0/255.0, alpha: 1.0)
    }
    
    class var colorYellowTimerSelection: UIColor {//#F0F89F
              return  UIColor(red: 240.0/255.0, green: 248.0/255.0, blue: 159.0/255.0, alpha: 1.0)
          }
    class var colorGraySelection: UIColor {//#707070
              return  UIColor(red: 112.0/255.0, green: 112.0/255.0, blue: 112.0/255.0, alpha: 1.0)
          }

    class var growingTextViewContainerColor: UIColor {
        return  UIColor(red: 225.0/255, green: 225.0/255, blue: 225.0/255, alpha: 1.0)
    }
    
    class var buttonDisableColor: UIColor {
        return  UIColor(red: 212.0/255, green: 212.0/255, blue: 212.0/255, alpha: 1.0)
    }
    class var buttonGrayDisableColor: UIColor {//#EBEBEB
           return  UIColor(red: 235.0/255, green: 235.0/255, blue: 235.0/255, alpha: 1.0)
       }
    class var buttonDisableTextColor: UIColor {//#8D8D8D
        return  UIColor(red: 141.0/255, green: 141.0/255, blue: 141.0/255, alpha: 1.0)
          }
    class var backgroundDimColor: UIColor {
        return  UIColor.black.withAlphaComponent(0.7)
    }
    class var backgroundBlurColor: UIColor {
           return  UIColor.lightGray.withAlphaComponent(0.5)
       }
    
    class var sepratorLineColor: UIColor {//#AEBBCE
        return  UIColor(red: 174.0/255.0, green: 187.0/255.0, blue: 206.0/255.0, alpha: 1.0)
          }
    
    // MARK: - App Theme Color
    class var buttonActiveColor: UIColor {
        return UIColor(red: 14.0/255.0, green: 138.0/255.0, blue: 238.0/255.0, alpha: 1.0)

    }

    class var replyViewColor: UIColor {
        return  UIColor(red: 215.0/255, green: 226.0/255, blue: 236.0/255, alpha: 1.0)
    }

    class var _596870: UIColor {
        return  UIColor(red: 89.0/255, green: 104.0/255, blue: 112.0/255, alpha: 1.0)
    }
    
    class var buttonInactiveColor: UIColor {
        return  UIColor(red: 112.0/255.0, green: 112.0/255.0, blue: 112.0/255.0, alpha: 1.0)
    }
    
    class var outlineButtonColor: UIColor {
        return  UIColor(red: 112.0/255.0, green: 112.0/255.0, blue: 112.0/255.0, alpha: 1.0)
    }
    
    class var iconColor: UIColor {
        return UIColor(red: 14.0/255.0, green: 138.0/255.0, blue: 238.0/255.0, alpha: 1.0)
    }
    class var appPrimaryColor: UIColor {
        return UIColor(red: 14.0/255.0, green: 138.0/255.0, blue: 238.0/255.0, alpha: 1.0)
    }
    class var appSecondaryColor: UIColor {
        return UIColor(red: 14.0/255.0, green: 138.0/255.0, blue: 238.0/255.0, alpha: 1.0)
    }
    class var textColorBlack: UIColor {
        return UIColor(red: 0/255.0, green: 0/255.0, blue: 0/255.0, alpha: 1.0)
    }
    class var actionColorDefault: UIColor {
        return UIColor(red: 14.0/255.0, green: 138.0/255.0, blue: 238.0/255.0, alpha: 1.0)
    }
    class var dividerOutlineColor: UIColor {
        return  UIColor(red: 112.0/255.0, green: 112.0/255.0, blue: 112.0/255.0, alpha: 1.0)
    }
    class var inActiveButtonColor: UIColor {
        return  UIColor(red: 112.0/255.0, green: 112.0/255.0, blue: 112.0/255.0, alpha: 1.0)
    }
    class var selectedCellColor: UIColor {
        return  UIColor(red: 112.0/255.0, green: 112.0/255.0, blue: 112.0/255.0, alpha: 1.0)

    }
    class var textfieldBorderColor: UIColor {
        return  UIColor(red: 112.0/255.0, green: 112.0/255.0, blue: 112.0/255.0, alpha: 1.0)
    }
    class var secondaryButtonColor: UIColor {
        return UIColor(red: 14.0/255.0, green: 138.0/255.0, blue: 238.0/255.0, alpha: 1.0)
    }
    class var inActiveButtonTitleColor: UIColor {
        return UIColor(red: 14.0/255.0, green: 138.0/255.0, blue: 238.0/255.0, alpha: 1.0)
    }
    class var unreadNotificationColor: UIColor {
        return UIColor(red: 14.0/255.0, green: 138.0/255.0, blue: 238.0/255.0, alpha: 1.0)
    }
    
    class var tintColor: UIColor {
        return  UIColor(red: 112.0/255.0, green: 112.0/255.0, blue: 112.0/255.0, alpha: 1.0)
    }
    
    class var unselectedItemTintColor: UIColor {
        return  UIColor(red: 0/255.0, green: 0/255.0, blue: 0/255.0, alpha: 1.0)

    }
    
    class var barTintColor: UIColor {
        return  UIColor(red: 112.0/255.0, green: 112.0/255.0, blue: 112.0/255.0, alpha: 1.0)
    }
    
    class var selectionIndicatorColor: UIColor {
        return  UIColor(red: 112.0/255.0, green: 112.0/255.0, blue: 112.0/255.0, alpha: 1.0)
    }
    
    
    class func blackWithAlpha(alpha: CGFloat) -> UIColor {
        return UIColor(red: 0.0/255.0, green: 0.0/255.0, blue: 0.0/255.0, alpha: alpha)
    }
    
    class var giTextColorSecondary: UIColor {
        return  UIColor(red: 188.0/255.0, green: 188.0/255.0, blue: 188.0/255.0, alpha: 1.0)
    }
    
    class var giBackgroundColor: UIColor {
        return  UIColor(red: 34.0/255.0, green: 34.0/255.0, blue: 34.0/255.0, alpha: 1.0)
    }
    
    class var giGrayColor: UIColor {
        return  UIColor(red: 77.0/255.0, green: 77.0/255.0, blue: 77.0/255.0, alpha: 1.0)
    }
    
    class var giTextColorPrimary: UIColor {
        return  UIColor(red: 255.0/255.0, green: 255.0/255.0, blue: 255.0/255.0, alpha: 1.0)
    }
    
    class var giButtonActiveColor: UIColor {
        return  UIColor(red: 0.0/255.0, green: 51.0/255.0, blue: 255.0/255.0, alpha: 1.0)
    }
    
    class func giBlackWithAlpha(alpha: CGFloat) -> UIColor {
        return UIColor(red: 0.0/255.0, green: 0.0/255.0, blue: 0.0/255.0, alpha: alpha)
    }
    
    class func giWhiteWithAlpha(alpha: CGFloat) -> UIColor {
        return UIColor(red: 255.0/255.0, green: 255.0/255.0, blue: 255.0/255.0, alpha: alpha)
    }
}
