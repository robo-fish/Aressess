//
//  Utilities.swift
//  Aressess
//
//  Created by Kai Oezer on 8/11/14.
//  Copyright (c) 2014, 2017 Kai Oezer. All rights reserved.
//

import UIKit

#if DEBUG
  public func DebugLog(_ s:String) { NSLog(s) }
#else
  public func DebugLog(_ s:String) {}
#endif

let PreferenceKey_NightModeEnabled = "NightModeEnabled"
let NightModeChangedNotification = "NightModeChangedNotification"

let DefaultBackgroundColor = UIColor.white
let DefaultNavigationBarBackgroundColor = DefaultBackgroundColor
let DefaultSplitViewBackgroundColor = UIColor(white:0.5, alpha:1.0)
let DefaultTextColor = UIColor.black
let DefaultTextFieldBackgroundColor = UIColor.white
let DefaultTextFieldTextColor = DefaultTextColor
let DefaultTitleColor = DefaultTextColor
let DefaultTextColorOfReadNewsItem = UIColor(white:0.75, alpha:1.0)

let NightModeBackgroundColor = UIColor.black
let NightModeNavigationBarBackgroundColor = UIColor(red:44/255, green:44/255, blue:39/255, alpha:1.0)
let NightModeSplitViewBackgroundColor = UIColor(white:0.64, alpha:1.0)
let NightModeTextColor = UIColor.white
let NightModeTextFieldBackgroundColor = UIColor(white:0.2, alpha:1.0)
let NightModeTextFieldTextColor = NightModeTextColor
let NightModeTitleColor = UIColor.gray
let NightModeTextColorOfReadNewsItem = UIColor(white:0.40, alpha:1.0)

func LocString(_ key:String) -> String
{
  return NSLocalizedString(key, tableName:"Localizable", bundle:Bundle.main, value:"!Translate!", comment:"")
}


func addBackgroundGradientToView(_ view : UIView)
{
  if let layers = view.layer.sublayers
  {
    for layer in layers
    {
      if layer is CAGradientLayer
      {
        layer.removeFromSuperlayer()
      }
    }
  }

  let gradientLayer = CAGradientLayer()
  gradientLayer.backgroundColor = UIColor.clear.cgColor
  gradientLayer.colors = [UIColor(red:87.0/255.0, green:69.0/255.0, blue:1, alpha:1).cgColor, UIColor.white.cgColor]
  gradientLayer.locations = [0.0, 0.9]
  gradientLayer.startPoint = CGPoint(x:0.5, y: 0.0)
  gradientLayer.endPoint = CGPoint(x:0.5, y:1.0)
  gradientLayer.frame = view.bounds
  view.layer.insertSublayer(gradientLayer, at:0)
}


func isValidFeedAddress(_ address:URL) -> Bool
{
  let scheme = address.scheme
  if (scheme == "http") || (scheme == "feed")
  {
    if (address.host != nil) && !address.host!.isEmpty
    {
      return true
    }
  }
  return false
}


func toggleGlobalNightMode()
{
  let oldState = UserDefaults.standard.bool(forKey: PreferenceKey_NightModeEnabled)
  UserDefaults.standard.set(!oldState, forKey:PreferenceKey_NightModeEnabled)
  NotificationCenter.default.post(name: Notification.Name(rawValue: NightModeChangedNotification), object:nil)
}


extension UIColor
{
  /// - returns: A lighter or darker variant, depending on the given factor.
  /// - parameter factor: needs to be greater than 1 in order to produce a lighter color
  public func lighter(_ factor:CGFloat) -> UIColor
  {
    var r : CGFloat = 0.0
    var g : CGFloat = 0.0
    var b : CGFloat = 0.0
    var a : CGFloat = 1.0
    if self.getRed(&r, green:&g, blue:&b, alpha:&a)
    {
      return UIColor(red:factor*r, green:factor*g, blue:factor*b, alpha:a)
    }
    return self
  }
}
