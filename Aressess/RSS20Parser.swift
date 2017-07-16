//
//  RSS20Parser.swift
//  Aressess
//
//  Created by Kai Özer on 7/29/14.
//  Copyright (c) 2014, 2017 Kai Özer. All rights reserved.
//

import Foundation

/// A parser for the RSS 2.0 XML format
class RSS20Parser : Parser
{
  var channel : RSSChannel?
  fileprivate var isRSS : Bool = false
  fileprivate var channelElementStackDepth = 0
  fileprivate var currentItem : RSSItem!
  fileprivate var itemElementStackDepth : Int = 0
  fileprivate var currentTitleData : String!
  fileprivate var titleElementStackDepth : Int = 0
  fileprivate var currentLinkData : String!
  fileprivate var linkElementStackDepth : Int = 0
  fileprivate var currentDescriptionData : String!
  fileprivate var descriptionElementStackDepth : Int = 0
  fileprivate var waitingForTitleData = false
  fileprivate var waitingForLinkData = false
  fileprivate var waitingForDescriptionData = false

  override init()
  {
    super.init()
  }

  //MARK: Parser overrides

  override func parsingWillStart()
  {
    _reset()
    channel = RSSChannel()
  }

  override func parsingStartsElementWithName(_ name: String, namespaceURI: String?, attributes: [String : String])
  {
    switch name
    {
      case "rss":         _checkRSSVersion(attributes as [NSObject : AnyObject]!)
      case "channel":     _startChannel(attributes as [NSObject : AnyObject]!)
      case "item":        _startItem(attributes as [NSObject : AnyObject]!)
      case "title":       _startTitle(attributes as [NSObject : AnyObject]!)
      case "link":        _startLink(attributes as [NSObject : AnyObject]!)
      case "description": _startDescription(attributes as [NSObject : AnyObject]!)
      default: break
    }
  }

  override func parsingEndsElementWithName(_ name: String, namespaceURI: String!)
  {
    switch name
    {
      case "rss":
        isRSS = false
      case "channel":
        if (channelElementStackDepth > 0)
        {
          channelElementStackDepth -= 1
          itemElementStackDepth = 0
        }
      case "item":
        if (currentItem != nil) && (itemElementStackDepth == 1)
        {
          if channel != nil
          {
            if !currentItem.title.isEmpty
            {
              channel!.items.append(currentItem)
            }
          }
          currentItem = nil
          titleElementStackDepth = 0
          linkElementStackDepth = 0
          descriptionElementStackDepth = 0
          itemElementStackDepth -= 1
        }
      case "title":
        if waitingForTitleData && (titleElementStackDepth == 1)
        {
          if (currentItem != nil) && (currentTitleData != nil)
          {
            currentItem!.title = currentTitleData.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
          }
          currentTitleData = nil
          waitingForTitleData = false
          titleElementStackDepth -= 1
        }
      case "link":
        if waitingForLinkData && (linkElementStackDepth == 1)
        {
          if (currentItem != nil) && (currentLinkData != nil)
          {
            currentItem!.link = currentLinkData.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
          }
          currentLinkData = nil
          waitingForLinkData = false
          linkElementStackDepth -= 1
        }
      case "description":
        if waitingForDescriptionData && (descriptionElementStackDepth == 1)
        {
          if (currentItem != nil) && (currentDescriptionData != nil)
          {
            currentItem!.description = currentDescriptionData.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
          }
          currentDescriptionData = nil
          waitingForDescriptionData = false
          descriptionElementStackDepth -= 1
        }
      default: break
    }
  }

  override func parsingFindsString(_ string: String)
  {
    if waitingForTitleData && (titleElementStackDepth == 1) && (currentTitleData != nil)
    {
      currentTitleData! += string
    }
    else if waitingForLinkData && (linkElementStackDepth == 1) && (currentLinkData != nil)
    {
      currentLinkData! += string
    }
    else if waitingForDescriptionData && (descriptionElementStackDepth == 1) && (currentDescriptionData != nil)
    {
      currentDescriptionData! += string
    }
  }

  //MARK: Private

  fileprivate func _reset()
  {
    isRSS = false
    channel = nil
    currentItem = nil
    currentTitleData = nil
    currentLinkData = nil
    currentDescriptionData = nil
  }

  fileprivate func _checkRSSVersion(_ attributes : [AnyHashable: Any]!)
  {
    if attributes != nil
    {
      if let version = attributes["version" as NSString] as? String
      {
        if version == "2.0"
        {
          isRSS = true
        }
      }
    }
  }

  fileprivate func _startChannel(_ attributes : [AnyHashable: Any]!)
  {
    if isRSS && (channelElementStackDepth == 0)
    {
      channel = RSSChannel()
      itemElementStackDepth = 0
      channelElementStackDepth += 1
    }
  }

  fileprivate func _startItem(_ attributes : [AnyHashable: Any]!)
  {
    if isRSS && (itemElementStackDepth == 0)
    {
      currentItem = RSSItem()
      waitingForDescriptionData = true
      waitingForTitleData = true
      waitingForLinkData = true
      itemElementStackDepth += 1
    }
  }

  fileprivate func _startTitle(_ attributes : [AnyHashable: Any]!)
  {
    if isRSS && waitingForTitleData && (titleElementStackDepth == 0)
    {
      currentTitleData = ""
      titleElementStackDepth += 1
    }
  }

  fileprivate func _startLink(_ attributes : [AnyHashable: Any]!)
  {
    if isRSS && waitingForLinkData && (linkElementStackDepth == 0)
    {
      currentLinkData = ""
      linkElementStackDepth += 1
    }
  }

  fileprivate func _startDescription(_ attributes : [AnyHashable: Any]!)
  {
    if isRSS && waitingForDescriptionData && (descriptionElementStackDepth == 0)
    {
      currentDescriptionData = ""
      descriptionElementStackDepth += 1
    }
  }
}
