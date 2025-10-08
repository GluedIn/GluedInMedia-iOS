//
//  UIFont+Addition.swift
//  GluedIn
//
//  Created by Amit Choudhary on 24/07/24.
//

import UIKit

extension UIFont {
    
    private class MyFontClass {}

       static func loadFontWith(name: String) {
           let frameworkBundle = Bundle(for: MyFontClass.self)
           guard let pathForResourceString = frameworkBundle.path(forResource: name, ofType: "otf") else { return }
           let fontData = NSData(contentsOfFile: pathForResourceString)
           let dataProvider = CGDataProvider(data: fontData!)
           let fontRef = CGFont(dataProvider!)
           var errorRef: Unmanaged<CFError>? = nil

           if (CTFontManagerRegisterGraphicsFont(fontRef!, &errorRef) == false) {
               NSLog("Failed to register font - register graphics font failed - this font may have already been registered in the main bundle.")
           }
       }

    public static let loadMyFonts: () = {
        loadFontWith(name: "SanFranciscoText-Regular")
        loadFontWith(name: "SanFranciscoText-Medium")
        loadFontWith(name: "SanFranciscoText-Light")
        loadFontWith(name: "SanFranciscoText-Bold")
        loadFontWith(name: "SanFranciscoText-Semibold")
        loadFontWith(name: "SanFranciscoDisplay-Regular")
        loadFontWith(name: "SanFranciscoDisplay-Medium")
        loadFontWith(name: "SanFranciscoDisplay-Light")
        loadFontWith(name: "SanFranciscoDisplay-Bold")
        loadFontWith(name: "SanFranciscoDisplay-Semibold")
    }()
    
  class var textStyle1: UIFont {
    return UIFont(name: "SanFranciscoText-Regular", size: 15.0) ??
      UIFont.systemFont(ofSize: 15.0)
  }

  class var textStyle2: UIFont {
    return UIFont(name: "SanFranciscoText-Medium", size: 16.0) ??
      UIFont.systemFont(ofSize: 16.0)
  }
    
  class var textStyle3: UIFont {
      return UIFont(name: "SanFranciscoText-Light", size: 12.0) ??
      UIFont.systemFont(ofSize: 12.0)
  }
  class var textStyle4: UIFont {
      return UIFont(name: "SanFranciscoText-Bold", size: 12.0) ??
      UIFont.systemFont(ofSize: 12.0)
    }
    
  class var textStyle5: UIFont {
      return UIFont(name: "SanFranciscoText-Regular", size: 10.0) ??
      UIFont.systemFont(ofSize: 10.0)
    }
  class var textStyle6: UIFont {
       return UIFont(name: "SanFranciscoText-Regular", size: 210.0) ??
      UIFont.systemFont(ofSize: 210.0)
     }
  class var textStyle7: UIFont {
      return UIFont(name: "SanFranciscoText-Regular", size: 13.0) ??
      UIFont.systemFont(ofSize: 13.0)
    }
    class var textStyle8: UIFont {
         return UIFont(name: "SanFranciscoText-Regular", size: 11.0) ??
        UIFont.systemFont(ofSize: 11.0)
       }
    class var textStyle9: UIFont {
      return UIFont(name: "SanFranciscoText-Semibold", size: 18.0) ??
        UIFont.systemFont(ofSize: 18.0)
    }
    
    class var textStyle10: UIFont {
        return UIFont(name: "SanFranciscoText-Regular", size: 16.0) ??
        UIFont.systemFont(ofSize: 16.0)
      }
    class var textStyle11: UIFont {
       return UIFont(name: "SanFranciscoText-Regular", size: 12.0) ??
        UIFont.systemFont(ofSize: 12.0)
     }
    class var textStyle18: UIFont {
      return UIFont(name: "SanFranciscoText-Regular", size: 12.0) ??
        UIFont.systemFont(ofSize: 12.0)
    }
    class var textStyle17: UIFont {
      return UIFont(name: "SanFranciscoText-Regular", size: 17.0) ??
        UIFont.systemFont(ofSize: 17.0)
    }

    class var editDeleteOptionsFont: UIFont {
        return UIFont(name: "SanFranciscoText-Regular", size: 15.0) ??
        UIFont.systemFont(ofSize: 15.0)
    }
    
    class var alertButtonTitleFont: UIFont {
        return UIFont(name: "SanFranciscoText-Regular", size: 18.0) ??
        UIFont.systemFont(ofSize: 18.0)
    }
    
    class var alertMessageFont: UIFont {
        return UIFont(name: "SanFranciscoText-Regular", size: 16.0) ??
        UIFont.systemFont(ofSize: 16.0)
    }
    
    class var alertTitleFont: UIFont {
        return UIFont(name: "SanFranciscoText-Regular", size: 16.0) ??
        UIFont.systemFont(ofSize: 16.0)
    }
    class var textStyle_10: UIFont {
       return UIFont(name: "SanFranciscoText-Regular", size: 10.0) ??
        UIFont.systemFont(ofSize: 10.0)
     }
    class var textStyle12: UIFont {
        return UIFont(name: "SanFranciscoText-Medium", size: 12.0) ??
        UIFont.systemFont(ofSize: 12.0)
      }
    class var textStyle13: UIFont {
        return UIFont(name: "SanFranciscoText-Bold", size: 15.0) ??
        UIFont.systemFont(ofSize: 15.0)
      }
    class var textStyle14: UIFont {
        return UIFont(name: "SanFranciscoText-Medium", size: 17.0) ??
        UIFont.systemFont(ofSize: 17.0)
      }
    class var textStyleMedium17: UIFont {
        return UIFont(name: "SanFranciscoText-Medium", size: 17.0) ??
        UIFont.systemFont(ofSize: 17.0)
      }
    class var textStyleRegular15: UIFont {
        return UIFont(name: "SanFranciscoText-Regular", size: 15.0) ??
        UIFont.systemFont(ofSize: 15.0)
    }
    class var textStyle15: UIFont {
        return UIFont(name: "SanFranciscoText-Medium", size: 15.0) ??
        UIFont.systemFont(ofSize: 15.0)
      }
    class var textStyleDisplay10: UIFont {
        return UIFont(name: "SanFranciscoDisplay-Regular", size: 10.0) ??
        UIFont.systemFont(ofSize: 10.0)
      }
    class var textStyleDisplay12: UIFont {
        return UIFont(name: "SanFranciscoDisplay-Regular", size: 12.0) ?? UIFont.systemFont(ofSize: 12)
      }
    class var textStyleDisplay13: UIFont {
        return UIFont(name: "SanFranciscoDisplay-Regular", size: 13.0) ??
        UIFont.systemFont(ofSize: 13.0)
      }
    class var textStyleDisplay14: UIFont {
        return UIFont(name: "SanFranciscoDisplay-Regular", size: 14.0)  ??
        UIFont.systemFont(ofSize: 14.0)
      }
    class var textStyleDisplay15: UIFont {
        return UIFont(name: "SanFranciscoDisplay-Regular", size: 15.0) ??
        UIFont.systemFont(ofSize: 15.0)
      }
    class var textStyleDisplay17: UIFont {
        return UIFont(name: "SanFranciscoDisplay-Regular", size: 17.0) ??
        UIFont.systemFont(ofSize: 17.0)
      }
    class var textStyleDisplayMedium17: UIFont {
        return UIFont(name: "SanFranciscoDisplay-Medium", size: 17.0) ??
        UIFont.systemFont(ofSize: 17.0)
      }
    
    class var textStyleMedium14: UIFont {
        return UIFont(name: "SanFranciscoDisplay-Medium", size: 14.0) ??
        UIFont.systemFont(ofSize: 14.0)
    }
    class var textStyleMedium12: UIFont {
        return UIFont(name: "SanFranciscoDisplay-Medium", size: 12.0) ??
        UIFont.systemFont(ofSize: 12.0)
    }
    class var textStyleMedium10: UIFont {
        return UIFont(name: "SanFranciscoDisplay-Medium", size: 10.0) ??
        UIFont.systemFont(ofSize: 10.0)
    }
    
    class var textStyleSemiBold18: UIFont {
      return UIFont(name: "SanFranciscoText-Semibold", size: 18.0) ??
        UIFont.systemFont(ofSize: 18.0)
    }
    
    class var textStyleSemiBold8: UIFont {
      return UIFont(name: "SanFranciscoText-Semibold", size: 8.0) ??
        UIFont.systemFont(ofSize: 8.0)
    }
    
    class var textStyleSemiBold12: UIFont {
      return UIFont(name: "SanFranciscoText-Semibold", size: 12.0) ??
        UIFont.systemFont(ofSize: 12.0)
    }
    
    class var textStyleSemiBold14: UIFont {
      return UIFont(name: "SanFranciscoText-Semibold", size: 14.0) ??
        UIFont.systemFont(ofSize: 14.0)
    }
    
    class var textStyleBold24: UIFont {
        return UIFont(name: "SanFranciscoDisplay-Bold", size: 24.0) ?? UIFont.systemFont(ofSize: 24.0)
    }
    
    class var textStyleRegular14: UIFont {
        return UIFont(name: "SanFranciscoDisplay-Regular", size: 14.0) ?? UIFont.systemFont(ofSize: 14.0)
    }
    
    class var textStyleRegular13: UIFont {
        return UIFont(name: "SanFranciscoDisplay-Regular", size: 13.0) ?? UIFont.systemFont(ofSize: 13.0)
    }
    
    class var textStyleSemibold12: UIFont {
        return UIFont(name: "SanFranciscoText-Semibold", size: 12.0) ??
        UIFont.systemFont(ofSize: 12.0)
    }
    
    class var textStyleSemibold14: UIFont {
        return UIFont(name: "SanFranciscoText-Semibold", size: 14.0) ??
        UIFont.systemFont(ofSize: 14.0)
    }
    class var textStyleSemibold16: UIFont {
        return UIFont(name: "SanFranciscoText-Semibold", size: 16.0) ??
        UIFont.systemFont(ofSize: 16.0)
    }
    
    class var textStyleBold14: UIFont {
        return UIFont(name: "SanFranciscoDisplay-Bold", size: 14.0) ?? UIFont.systemFont(ofSize: 14.0)
    }
    class var textStyleBold12: UIFont {
        return UIFont(name: "SanFranciscoDisplay-Bold", size: 12.0) ?? UIFont.systemFont(ofSize: 12.0)
    }
    class var textStyleBold10: UIFont {
        return UIFont(name: "SanFranciscoDisplay-Bold", size: 10.0) ?? UIFont.systemFont(ofSize: 10.0)
    }
   
    
    class var textStyleBold16: UIFont {
        return UIFont(name: "SanFranciscoText-Bold", size: 16.0) ??
        UIFont.systemFont(ofSize: 16.0)
      }
    
}
