//
//  FeedManager.swift
//  Aressess
//
//  Created by Kai Oezer on 7/17/14.
//  Copyright (c) 2014, 2017 Kai Oezer. All rights reserved.
//

import UIKit


protocol FeedGroupsChangeObserver
{
  func handleFeedGroupsChanged()
}

private let DefaultGroupColor = UIColor(red:0.5, green: 0.5, blue: 1.0, alpha: 1)

class FeedManager
{
  enum ArchivingKey : String
  {
    case FeedGroups = "FeedGroups"
    case ActiveFeedGroupIndex = "ActiveFeedGroupIndex"
    case CloudFormatVersion = "CloudFormatVersion"
    case Timestamp = "Timestamp"
  }

  static private let _sharedFeedManager = FeedManager()
  class var shared : FeedManager { return _sharedFeedManager }

  var feedGroups = [FeedGroup]()

  private var _editingQueue = DispatchQueue(label:"fish.robo.feedr.FeedGroupsEditing")
  typealias FeedGroupsChangeObserverObject = AnyObject & FeedGroupsChangeObserver
  private var _changeObservers = [FeedGroupsChangeObserverObject]()

  private var _activeGroupIndex : Int = 0

  private init()
  {
  }
}

// MARK: Methods Provided for Feed Group Editing

extension FeedManager
{
  func commitChanges(by source : FeedGroupsChangeObserverObject, _ block : ()->())
  {
    _editingQueue.sync {
      defer {
        _saveToLocal()
        DispatchQueue.main.async{ self._signalFeedGroupsChanged(by: source) }
      }
      block()
    }
  }

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

  func addFeed(name: String, location: String, groupIndex:Int = -1)
  {
    if let url = URL(string: location)
    {
      feedGroups[groupIndex >= 0 ? groupIndex : _activeGroupIndex].feeds.append(Feed(location: url, name: name))
    }
  }

  func insertFeedAtIndex(_ positionIndex:Int, name: String, location: String, groupIndex:Int = -1)
  {
    if let url = URL(string:location)
    {
      let newFeed = Feed(location:url, name: name)
      feedGroups[groupIndex >= 0 ? groupIndex : _activeGroupIndex].feeds.insert(newFeed, at:positionIndex)
    }
  }

  func removeFeed(_ feed : Feed, fromGroup groupIndex : Int)
  {
    if (groupIndex >= 0) && (groupIndex < feedGroups.count)
    {

    }
  }

  func addFeedGroup(named name : String, feeds : [Feed])
  {
    feedGroups.append(FeedGroup(name:name, feeds:feeds))
  }

  func removeFeedGroup(at groupIndex : Int)
  {
    if groupIndex < feedGroups.count
    {
      feedGroups.remove(at: groupIndex)
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
    }
  }

  func removeFeed(at feedIndex:Int, fromGroupAt groupIndex:Int = -1)
  {
    let targetGroup = feedGroups[groupIndex >= 0 ? groupIndex : _activeGroupIndex]
    if (feedIndex >= 0) && (feedIndex < targetGroup.feeds.count)
    {
      targetGroup.feeds.remove(at: feedIndex)
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
    }
  }

  func save()
  {
    _saveToLocal()
    _signalFeedGroupsChanged(by:self)
  }

  func changeActiveFeedGroup(_ newActiveGroupIndex : Int)
  {
    activeGroupIndex = newActiveGroupIndex
  }

  func registerChangeObserver(_ observer:FeedGroupsChangeObserverObject)
  {
    var found = false
    for object in _changeObservers { if object === observer { found = true; break } }
    if !found
    {
      _changeObservers.append(observer)
    }
  }

  func removeChangeObserver(_ observer:FeedGroupsChangeObserverObject)
  {
    for (index, object) in _changeObservers.enumerated()
    {
      if object === observer
      {
        _changeObservers.remove(at: index)
      }
    }
  }
}

//MARK: Private Methods

extension FeedManager
{

  func _signalFeedGroupsChanged(by source : AnyObject)
  {
    for observer in _changeObservers
    {
      if observer !== source
      {
        observer.handleFeedGroupsChanged()
      }
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
}
