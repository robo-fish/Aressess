//
//  MainSplitViewController.swift
//  Aressess
//
//  Created by Kai Oezer on 9/2/15.
//  Copyright © 2015, 2017 Kai Oezer. All rights reserved.
//

import UIKit

class MainSplitViewController : UISplitViewController
{
  private var _nightMode = false

  override func viewWillAppear(_ animated: Bool)
  {
    _nightMode = UserDefaults.standard.bool(forKey: PreferenceKey_NightModeEnabled)
    NotificationCenter.default.addObserver(self, selector: #selector(MainSplitViewController.handleNightModeChanged(_:)), name:NSNotification.Name(rawValue: NightModeChangedNotification), object: nil)
  }

  override var preferredStatusBarStyle : UIStatusBarStyle
  {
    get { return _nightMode ? .lightContent : .default }
  }

  @objc func handleNightModeChanged(_ notification : Notification)
  {
    _nightMode = UserDefaults.standard.bool(forKey: PreferenceKey_NightModeEnabled)
    setNeedsStatusBarAppearanceUpdate()
  }
}
