//
//  AressessNavigationController.swift
//  Aressess
//
//  Created by Kai Oezer on 12/25/17.
//  Copyright © 2017 Kai Oezer. All rights reserved.
//

import UIKit

class AressessNavigationController : UINavigationController
{
  deinit
  {
    NotificationCenter.default.removeObserver(self)
  }

  override func viewDidLoad()
  {
    super.viewDidLoad()
    navigationBar.prefersLargeTitles = true
    NotificationCenter.default.addObserver(self, selector: #selector(AressessNavigationController.handleNightModeChanged), name: NSNotification.Name(rawValue: NightModeChangedNotification), object: nil)
    _updateColors()
  }

  @objc func showHelp(_ sender:AnyObject!)
  {
    performSegue(withIdentifier: "showHelp", sender:self)
  }

  @objc func handleNightModeChanged(notification : Notification)
  {
    _updateColors()
  }

  private func _updateColors()
  {
    let nightModeIsOn = UserDefaults.standard.bool(forKey: PreferenceKey_NightModeEnabled)
    navigationBar.barTintColor = nightModeIsOn ? NightModeNavigationBarBackgroundColor : DefaultNavigationBarBackgroundColor
    navigationBar.titleTextAttributes = [NSAttributedStringKey.foregroundColor : (nightModeIsOn ? NightModeTitleColor : DefaultTitleColor)]
    toolbar.barTintColor = navigationBar.barTintColor
    view.backgroundColor = nightModeIsOn ? NightModeBackgroundColor : DefaultBackgroundColor
  }
}
