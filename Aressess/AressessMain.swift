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

  private var _cloudManager : CloudExchangeManager

  override init()
  {
    let fm = FeedManager.shared
    _cloudManager = CloudExchangeManager(feedManager:fm)
    super.init()
    _loadFeeds()
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
    FeedManager.shared.save()
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
    if let win = self.window
    {
      win.tintColor = UIColor.gray
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
    FeedManager.shared.registerChangeObserver(self)

    return shouldPerformAdditionalDelegateHandling
  }

  func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any]) -> Bool
  {
    let status = false
    if url.scheme == "feed"
    {
      if let navController = self.window!.rootViewController as? UINavigationController
      {
        var feedListViewController = navController.topViewController as? FeedGroupViewController

        if feedListViewController ==  nil
        {
          navController.popToRootViewController(animated: true)
          feedListViewController = navController.topViewController as? FeedGroupViewController
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

  private func _handleShortcutItem(_ shortcutItem: UIApplicationShortcutItem) -> Bool
  {
    let type = shortcutItem.type
    guard let selectedGroupIndex = Int(type) else { return false }
    FeedManager.shared.changeActiveFeedGroup(selectedGroupIndex)
    return true
  }

  private func _updateShortcutItems()
  {
    var shortcutItems = [UIApplicationShortcutItem]()
    for (index, feedGroup) in FeedManager.shared.feedGroups.enumerated()
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


extension AressessMain : FeedGroupsChangeObserver
{
  func handleFeedGroupsChanged()
  {
    _updateShortcutItems()
  }
}

extension AressessMain
{

  private func _loadFeeds()
  {
    _cloudManager.load()

    let fm = FeedManager.shared
    fm.commitChanges(by:self) {
      if fm.feedGroups.isEmpty
      {
        if let feedGroupsData = UserDefaults.standard.data(forKey: FeedManager.ArchivingKey.FeedGroups.rawValue)
        {
          do
          {
            fm.feedGroups = try JSONDecoder().decode([FeedGroup].self, from:feedGroupsData)
          }
          catch
          {
            DebugLog("Error while decoding feed groups. " + error.localizedDescription)
          }
        }
        if fm.feedGroups.isEmpty
        {
          self._loadInitialFeeds()
          assert(!fm.feedGroups.isEmpty)
        }
        fm.activeGroupIndex = UserDefaults.standard.integer(forKey: FeedManager.ArchivingKey.ActiveFeedGroupIndex.rawValue)

        self._cloudManager.save()
      }
    }
  }

  private func _loadInitialFeeds()
  {
    var feeds = [Feed]()
    var append = { (name:String, address:String) -> Void in
      if let url = URL(string:address)
      {
        feeds.append(Feed(location:url, name:name))
      }
    }

    #if false
      append("Quartz",           "http://qz.com/feed")
      append("Mashable",         "feed://feeds.mashable.com/Mashable")
      append("Zeit Online",      "feed://newsfeed.zeit.de/index")
      append("ORF News",         "feed://rss.orf.at/news.xml")
      append("Der Standard",     "http://derstandard.at/?page=rss&ressort=seite1")
      append("Dagens Nyheter",   "http://www.dn.se/nyheter/m/rss/")
      append("Asahi Shimbun",    "http://www3.asahi.com/rss/science.rdf")
      append("Spiegel Online",   "http://www.spiegel.de/schlagzeilen/tops/index.rss")
      append("Focus Online",     "http://rss.focus.de/fol/XML/rss_folnews.xml")
      append("Milliyet",         "http://www.milliyet.com.tr/D/rss/rss/Rss_2.xml")
      append("Sabah",            "http://www.sabah.com.tr/rss/Anasayfa.xml")
      append("Hürriyet Daily News", "feed://www.hurriyetdailynews.com/rss.aspx")
      append("Xinhua World",     "http://www.xinhuanet.com/world/news_world.xml")
      append("Xinhua Autos",     "http://www.xinhuanet.com/auto/news_auto.xml")
      feedGroups[UserFeedGroup.Blue.rawValue].feeds = feeds

      feeds.removeAll()
      append("Slashdot",         "feed://rss.slashdot.org/Slashdot/slashdot")
      append("Golem RSS 0.91",   "http://rss.golem.de/rss.php?feed=RSS0.91")
      append("Golem RSS 1.0",    "http://rss.golem.de/rss.php?feed=RSS1.0")
      append("Golem RSS 2.0",    "http://rss.golem.de/rss.php?feed=RSS2.0")
      append("Golem Atom 1.0",   "http://rss.golem.de/rss.php?feed=ATOM1.0")
      append("Golem OPML",       "http://rss.golem.de/rss.php?feed=OPML")
      append("The Verge",        "http://www.theverge.com/rss/index.xml")
      append("AppleInsider",     "http://appleinsider.com/appleinsider.rss")
      append("MacRumors",        "feed://feeds.macrumors.com/MacRumors-All?format=xml")
      feedGroups[UserFeedGroup.Red.rawValue].feeds = feeds
    #else
      if let initialFeedsFileLocation = Bundle.main.url(forResource:"InitialFeeds", withExtension:"plist")
      {
        do
        {
          let initialFeedsData = try Data(contentsOf: initialFeedsFileLocation, options:[])
          guard let initialFeedsPlist = try PropertyListSerialization.propertyList(from: initialFeedsData, options:[], format:nil) as? NSDictionary else { return }

          //println("\(NSLocale.availableLocaleIdentifiers())")

          let defaultLanguage = "en"
          let defaultRegionCode = "en_US"

          var languageCode = defaultLanguage
          let languages = Locale.preferredLanguages
          if !languages.isEmpty
          {
            languageCode = languages[0] as String
          }

          let regionCode = Locale.current.identifier
          var groups : NSArray? = nil

          if let regions = initialFeedsPlist[languageCode] as? NSDictionary
          {
            groups = regions[regionCode] as? NSArray
            if groups == nil
            {
              groups = regions.allValues[0] as? NSArray
            }
          }
          else
          {
            if let defaultLanguageRegions = initialFeedsPlist[defaultLanguage] as? NSDictionary
            {
              groups = defaultLanguageRegions[defaultRegionCode] as? NSArray
            }
          }

          if let groups_ = groups
          {
            for (groupIndex,group) in groups_.enumerated()
            {
              if let localizedFeeds = group as? [NSDictionary]
              {
                feeds.removeAll()
                for feed in localizedFeeds
                {
                  if
                    let feedName = feed["name"] as? String,
                    let feedLocation = feed["location"] as? String
                  {
                    append(feedName, feedLocation)
                  }
                }
                let fm = FeedManager.shared
                fm.commitChanges(by: self) {
                  fm.addFeedGroup(named:"Group\(groupIndex)", feeds:feeds)
                }
              }
            }
          }
        }
        catch
        {
          DebugLog(error.localizedDescription)
        }
      }
    #endif
  }
}

