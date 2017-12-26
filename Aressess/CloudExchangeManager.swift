//
//  CloudExchangeManager.swift
//  Aressess
//
//  Created by Kai Oezer on 12/26/17.
//  Copyright © 2017 Kai Oezer. All rights reserved.
//

import Foundation

private let CloudFormatVersion : Int64 = 1

class CloudExchangeManager
{
  private var _feedManager : FeedManager

  init(feedManager : FeedManager)
  {
    _feedManager = feedManager
    let store = NSUbiquitousKeyValueStore.default
    NotificationCenter.default.addObserver(self, selector:#selector(CloudExchangeManager.handleCloudStorageNotification(_:)), name:NSUbiquitousKeyValueStore.didChangeExternallyNotification, object:store)
    store.synchronize()
  }

  deinit
  {
    NotificationCenter.default.removeObserver(self)
  }

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
          load()
        }
      }
    }
  }

  func load()
  {
    let store = NSUbiquitousKeyValueStore.default
    let version = store.longLong(forKey: FeedManager.ArchivingKey.CloudFormatVersion.rawValue)
    if _isValidFormatVersion(version)
    {
      if let data = NSUbiquitousKeyValueStore.default.data(forKey: FeedManager.ArchivingKey.FeedGroups.rawValue)
      {
        _feedManager.commitChanges(by: self) {
          do
          {
            _feedManager.feedGroups = try JSONDecoder().decode([FeedGroup].self, from:data)
            _feedManager.activeGroupIndex = Int(store.longLong(forKey: FeedManager.ArchivingKey.ActiveFeedGroupIndex.rawValue))
          }
          catch
          {
            DebugLog("Error while decoding feed groups. " + error.localizedDescription)
          }
        }
      }
    }
  }

  func save()
  {
    let store = NSUbiquitousKeyValueStore.default
    store.set(CloudFormatVersion, forKey:FeedManager.ArchivingKey.CloudFormatVersion.rawValue)
    do
    {
      let encodedGroups = try JSONEncoder().encode(_feedManager.feedGroups)
      store.set(encodedGroups, forKey: FeedManager.ArchivingKey.FeedGroups.rawValue)
    }
    catch
    {
      DebugLog("Error while encoding feed groups. " + error.localizedDescription)
    }
    store.set(Int64(_feedManager.activeGroupIndex), forKey:FeedManager.ArchivingKey.ActiveFeedGroupIndex.rawValue)
    store.set(Date.timeIntervalSinceReferenceDate, forKey:FeedManager.ArchivingKey.Timestamp.rawValue)
  }

  private func _isValidFormatVersion(_ version:Int64) -> Bool
  {
    return (version > 0) && (version <= CloudFormatVersion)
  }

}

extension CloudExchangeManager : FeedGroupsChangeObserver
{
  func handleFeedGroupsChanged()
  {
    save()
  }
}
