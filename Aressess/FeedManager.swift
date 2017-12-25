//
//  FeedManager.swift
//  Aressess
//
//  Created by Kai Oezer on 7/17/14.
//  Copyright (c) 2014, 2017 Kai Oezer. All rights reserved.
//

import UIKit


@objc protocol FeedManagerExternalChangeObserver
{
  func handleFeedGroupContentsChangedExternally()
}

@objc protocol FeedManagerInternalChangeObserver
{
  func handleFeedGroupContentsChangedInternally()
}

private let DefaultGroupColor = UIColor(red:0.5, green: 0.5, blue: 1.0, alpha: 1)
private let CloudFormatVersion : Int64 = 1

class FeedManager
{
  enum ArchivingKey : String
  {
    case FeedGroups = "FeedGroups"
    case ActiveFeedGroupIndex = "ActiveFeedGroupIndex"
    case CloudFormatVersion = "CloudFormatVersion"
    case Timestamp = "Timestamp"
  }

  var feedGroups : [FeedGroup] = [FeedGroup]()

  private var _activeGroupIndex : Int = 0

  var activeGroupIndex : Int
  {
    get { return _activeGroupIndex }
    set {
      _activeGroupIndex = max(0, min(feedGroups.count - 1, newValue))
      _saveActiveGroupIndex()
    }
  }

  var activeGroup : FeedGroup
  {
    return feedGroups[_activeGroupIndex]
  }

  var activeFeeds : [Feed]
  {
    return feedGroups[_activeGroupIndex].feeds
  }

  var activeColor : UIColor
  {
    return feedGroups[_activeGroupIndex].color
  }

  var darkerActiveColor : UIColor
  {
    return activeColor.lighter(0.8)
  }

  var lighterActiveColor : UIColor
  {
    return activeColor.lighter(8)
  }

  private(set) var userCanPurchaseExtras = false
  private(set) var purchasePrice : String? = nil

  fileprivate var _externalChangeObservers = [FeedManagerExternalChangeObserver]()
  fileprivate var _internalChangeObservers = [FeedManagerInternalChangeObserver]()

  static private let _sharedFeedManager = FeedManager()

  class var shared : FeedManager { return _sharedFeedManager }

  private init()
  {
    _initializeCloud()
    _load()
  }

  deinit
  {
    NotificationCenter.default.removeObserver(self)
  }

  func addFeed(name: String, location: String, groupIndex:Int = -1)
  {
    if let url = URL(string: location)
    {
      feedGroups[groupIndex >= 0 ? groupIndex : _activeGroupIndex].feeds.append(Feed(location: url, name: name))
      _handleFeedsChanged()
    }
  }

  func insertFeedAtIndex(_ positionIndex:Int, name: String, location: String, groupIndex:Int = -1)
  {
    if let url = URL(string:location)
    {
      let newFeed = Feed(location:url, name: name)
      feedGroups[groupIndex >= 0 ? groupIndex : _activeGroupIndex].feeds.insert(newFeed, at:positionIndex)
      _handleFeedsChanged()
    }
  }

  func removeFeedGroup(at groupIndex : Int)
  {
    if groupIndex < feedGroups.count
    {
      feedGroups.remove(at: groupIndex)
      _handleFeedsChanged()
    }
  }

  func moveFeedGroup(fromRow sourceRowIndex : Int, toRow destinationRowIndex : Int)
  {
    if (sourceRowIndex < feedGroups.count) && (destinationRowIndex < feedGroups.count)
    {
      let movedGroup = feedGroups[sourceRowIndex]
      feedGroups.remove(at: sourceRowIndex)
      if destinationRowIndex > sourceRowIndex
      {
        feedGroups.insert(movedGroup, at:destinationRowIndex)
      }
      else
      {
        feedGroups.insert(movedGroup, at:destinationRowIndex)
      }
      _handleFeedsChanged()
    }
  }

  func removeFeed(at feedIndex:Int, fromGroupAt groupIndex:Int = -1)
  {
    let targetGroup = feedGroups[groupIndex >= 0 ? groupIndex : _activeGroupIndex]
    if (feedIndex >= 0) && (feedIndex < targetGroup.feeds.count)
    {
      targetGroup.feeds.remove(at: feedIndex)
      _handleFeedsChanged()
    }
  }

  func moveFeedInActiveGroup(fromRow sourceRowIndex:Int, toRow destinationRowIndex:Int)
  {
    let activeGroup = feedGroups[_activeGroupIndex]
    if (sourceRowIndex < activeGroup.feeds.count) && (destinationRowIndex < activeGroup.feeds.count)
    {
      let movedFeed = activeGroup.feeds[sourceRowIndex]
      activeGroup.feeds.remove(at: sourceRowIndex)
      if destinationRowIndex > sourceRowIndex
      {
        activeGroup.feeds.insert(movedFeed, at:destinationRowIndex)
      }
      else
      {
        activeGroup.feeds.insert(movedFeed, at:destinationRowIndex)
      }
      _handleFeedsChanged()
    }
  }

  func save()
  {
    _saveToLocal()
    _saveToCloud()
    _handleFeedsChangedInternally()
  }

  func changeActiveFeedGroup(_ newActiveGroupIndex : Int)
  {
    activeGroupIndex = newActiveGroupIndex
    for observer in _externalChangeObservers
    {
      observer.handleFeedGroupContentsChangedExternally()
    }
  }

  //MARK: Private

  fileprivate func _handleFeedsChanged(saveToCloud:Bool = true)
  {
    _saveToLocal()
    if saveToCloud
    {
      _saveToCloud()
    }
  }

  func _saveToLocal()
  {
    _saveFeeds()
    _saveActiveGroupIndex()
    _saveTimestamp()
  }

  private func _saveFeeds()
  {
    do
    {
      let encoder = JSONEncoder()
      let encodedFeeds = try encoder.encode(feedGroups)
      UserDefaults.standard.set(encodedFeeds, forKey:ArchivingKey.FeedGroups.rawValue)
    }
    catch
    {
      DebugLog("There was a problem encoding the feed groups. " + error.localizedDescription)
    }
  }

  private func _saveActiveGroupIndex()
  {
    UserDefaults.standard.set(_activeGroupIndex, forKey:ArchivingKey.ActiveFeedGroupIndex.rawValue)
  }

  private func _saveTimestamp()
  {
    UserDefaults.standard.set(Date.timeIntervalSinceReferenceDate, forKey:ArchivingKey.Timestamp.rawValue)
  }

  private func _load()
  {
    _loadFromCloud()

    if feedGroups.isEmpty
    {
      if let feedGroupsData = UserDefaults.standard.data(forKey: ArchivingKey.FeedGroups.rawValue)
      {
        do
        {
          feedGroups = try JSONDecoder().decode([FeedGroup].self, from:feedGroupsData)
        }
        catch
        {
          DebugLog("Error while decoding feed groups. " + error.localizedDescription)
        }
      }
      if feedGroups.isEmpty
      {
        _loadInitialFeeds()
        assert(!feedGroups.isEmpty)
      }
      _activeGroupIndex = UserDefaults.standard.integer(forKey: ArchivingKey.ActiveFeedGroupIndex.rawValue)
      _activeGroupIndex = max(0, min(feedGroups.count - 1, _activeGroupIndex))

      _saveToCloud()
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
              feedGroups.append(FeedGroup(name:"Group\(groupIndex)", feeds:feeds))
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

  fileprivate func _isValidFormatVersion(_ version:Int64) -> Bool
  {
    return (version > 0) && (version <= CloudFormatVersion)
  }
}


//MARK: iCloud


extension FeedManager
{
  //MARK: Public

  func addExternalChangeObserver(_ observer:FeedManagerExternalChangeObserver)
  {
    if !(_externalChangeObservers as NSArray).contains(observer)
    {
      _externalChangeObservers.append(observer)
    }
  }

  func removeExternalChangeObserver(_ observer:FeedManagerExternalChangeObserver)
  {
    let index = (_externalChangeObservers as NSArray).index(of: observer)
    _externalChangeObservers.remove(at: index)
  }

  func addInternalChangeObserver(_ observer:FeedManagerInternalChangeObserver)
  {
    if !(_internalChangeObservers as NSArray).contains(observer)
    {
      _internalChangeObservers.append(observer)
    }
  }

  func removeInternalChangeObserver(_ observer:FeedManagerInternalChangeObserver)
  {
    let index = (_internalChangeObservers as NSArray).index(of: observer)
    _internalChangeObservers.remove(at: index)
  }

  //MARK: Private

  fileprivate func _initializeCloud()
  {
    let store = NSUbiquitousKeyValueStore.default
    NotificationCenter.default.addObserver(self, selector:#selector(FeedManager.handleCloudStorageNotification(_:)), name:NSUbiquitousKeyValueStore.didChangeExternallyNotification, object:store)
    store.synchronize()
  }

  fileprivate func _loadFromCloud()
  {
    let store = NSUbiquitousKeyValueStore.default
    let version = store.longLong(forKey: ArchivingKey.CloudFormatVersion.rawValue)
    if _isValidFormatVersion(version)
    {
      if let data = NSUbiquitousKeyValueStore.default.data(forKey: ArchivingKey.FeedGroups.rawValue)
      {
        do
        {
          self.feedGroups = try JSONDecoder().decode([FeedGroup].self, from:data)
        }
        catch
        {
          DebugLog("Error while decoding feed groups. " + error.localizedDescription)
        }
      }
      activeGroupIndex = Int(store.longLong(forKey: ArchivingKey.ActiveFeedGroupIndex.rawValue))
    }
  }

  fileprivate func _saveToCloud()
  {
    let store = NSUbiquitousKeyValueStore.default
    store.set(CloudFormatVersion, forKey:ArchivingKey.CloudFormatVersion.rawValue)
    do
    {
      let encodedGroups = try JSONEncoder().encode(feedGroups)
      store.set(encodedGroups, forKey: ArchivingKey.FeedGroups.rawValue)
    }
    catch
    {
      DebugLog("Error while encoding feed groups. " + error.localizedDescription)
    }
    store.set(Int64(activeGroupIndex), forKey:ArchivingKey.ActiveFeedGroupIndex.rawValue)
    store.set(Date.timeIntervalSinceReferenceDate, forKey:ArchivingKey.Timestamp.rawValue)
  }

  fileprivate func _handleFeedsChangedExternally()
  {
    for observer in _externalChangeObservers
    {
      observer.handleFeedGroupContentsChangedExternally()
    }
    _handleFeedsChanged(saveToCloud: false)
  }

  fileprivate func _handleFeedsChangedInternally()
  {
    for observer in _internalChangeObservers
    {
      observer.handleFeedGroupContentsChangedInternally()
    }
  }

  //MARK: Notification handlers

  // @objc attribute is required for receiving notifications from NSNotificationCenter.
  @objc func handleCloudStorageNotification(_ notification:Notification)
  {
    if let userInfo = (notification as NSNotification).userInfo
    {
      if let reasonForChange = userInfo[NSUbiquitousKeyValueStoreChangeReasonKey] as? NSNumber
      {
        let reason = reasonForChange.intValue
        if (reason == NSUbiquitousKeyValueStoreServerChange)
        || (reason == NSUbiquitousKeyValueStoreInitialSyncChange)
        || (reason == NSUbiquitousKeyValueStoreAccountChange)
        {
          // Note: Conflict resolution is not possible with iCloud's Key-Value Store syncing.
          _loadFromCloud()
          _handleFeedsChangedExternally()
        }
      }
    }
  }

}
