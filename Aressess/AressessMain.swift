//
//  AressessMain.swift
//  Aressess
//
//  Created by Kai Oezer on 7/17/14.
//  Copyright (c) 2014, 2017 Kai Oezer. All rights reserved.
//

import UIKit

@UIApplicationMain
class AressessMain: UIResponder
{
  var window: UIWindow?

  fileprivate func _handleShortcutItem(_ shortcutItem: UIApplicationShortcutItem) -> Bool
  {
    let type = shortcutItem.type
    guard let selectedGroupIndex = Int(type) else { return false }
    FeedManager.sharedFeedManager().changeActiveFeedGroup(selectedGroupIndex)
    return true
  }

  fileprivate func _updateShortcutItems()
  {
    var shortcutItems = [UIApplicationShortcutItem]()
    for (index, feedGroup) in FeedManager.sharedFeedManager().feedGroups.enumerated()
    {
      if let feed = feedGroup.feeds.first
      {
        let feedName = feed.name + " " + LocString("AndMore")
        shortcutItems.append(UIMutableApplicationShortcutItem(type: "\(index)", localizedTitle: feedName))
      }
    }
    UIApplication.shared.shortcutItems = shortcutItems
  }
}


extension AressessMain : UIApplicationDelegate
{
  func applicationWillResignActive(_ application: UIApplication)
  {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    UserDefaults.standard.synchronize()
  }

  func applicationDidEnterBackground(_ application: UIApplication)
  {
    FeedManager.sharedFeedManager().save()
  }

  func applicationWillEnterForeground(_ application: UIApplication)
  {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
  }

  func applicationWillTerminate(_ application: UIApplication)
  {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
  }

  func application(_ application: UIApplication, willFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey : Any]?) -> Bool
  {
    return true
  }

  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey : Any]?) -> Bool
  {
    if let splitViewController = self.window!.rootViewController as? UISplitViewController
    {
      if UIDevice.current.userInterfaceIdiom == .pad
      {
        splitViewController.preferredDisplayMode = .allVisible
      }
      self.window!.tintColor = UIColor.gray
      if
        let navigationController = splitViewController.viewControllers[splitViewController.viewControllers.count-1] as? UINavigationController,
        let feedViewController = navigationController.topViewController as? FeedViewController
      {
        splitViewController.delegate = feedViewController
      }
    }

    var shouldPerformAdditionalDelegateHandling = true

    // If a shortcut was launched, display its information and take the appropriate action
    if let shortcutItem = launchOptions?[UIApplicationLaunchOptionsKey.shortcutItem] as? UIApplicationShortcutItem
    {
      let _ = _handleShortcutItem(shortcutItem)

      // This will block "performActionForShortcutItem:completionHandler" from being called.
      shouldPerformAdditionalDelegateHandling = false
    }
    _updateShortcutItems()
    FeedManager.sharedFeedManager().addInternalChangeObserver(self)

    return shouldPerformAdditionalDelegateHandling
  }

  func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any]) -> Bool
  {
    let status = false
    if url.scheme == "feed"
    {
      if let splitViewController = self.window!.rootViewController as? UISplitViewController,
        let navigationController = splitViewController.viewControllers[0] as? UINavigationController
      {
        var feedListViewController = navigationController.topViewController as? FeedListViewController

        if feedListViewController ==  nil
        {
          navigationController.popToRootViewController(animated: true)
          feedListViewController = navigationController.topViewController as? FeedListViewController
        }

        if let controller = feedListViewController
        {
          var host = url.host ?? ""
          if host.hasPrefix("www.")
          {
            host = String(host[host.index(host.startIndex, offsetBy: 4)...])
          }
          if host.hasSuffix(".com") || host.hasSuffix(".org") || host.hasSuffix(".net") || host.hasSuffix(".edu")
          {
            host = String(host[...host.index(host.endIndex, offsetBy: -4)])
          }
          controller.insertFeed(name: host, for: url)
        }
      }
    }
    return status
  }

  func application(_ application: UIApplication, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void)
  {
    _updateShortcutItems()
    completionHandler(_handleShortcutItem(shortcutItem))
  }

}


extension AressessMain : FeedManagerInternalChangeObserver
{
  func handleFeedGroupContentsChangedInternally()
  {
    _updateShortcutItems()
  }
}

