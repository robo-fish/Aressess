//
//  FeedGroup.swift
//  Aressess
//
//  Created by Kai Oezer on 8/13/14.
//  Copyright (c) 2014, 2017 Kai Oezer. All rights reserved.
//

import UIKit


class FeedGroup : NSObject, NSCoding
{
  enum ArchivingKey : String
  {
    case BlueGroup = "Blue Group"
    case RedGroup = "Red Group"
    case GreenGroup = "Green Group"
    case OrangeGroup = "Orange Group"

    static func keyForFeedGroup(_ group:UserGroup) -> ArchivingKey
    {
      switch group
      {
      case .blue:   return .BlueGroup
      case .red:    return .RedGroup
      case .green:  return .GreenGroup
      case .orange: return .OrangeGroup
      }
    }

    static func groupForKey(_ key:ArchivingKey) -> UserGroup?
    {
      switch key
      {
        case .BlueGroup :   return .blue
        case .RedGroup :    return .red
        case .GreenGroup :  return .green
        case .OrangeGroup : return .orange
      }
    }
  }

  enum UserGroup : Int
  {
    case blue = 0
    case red
    case green
    case orange
  }

  var feeds = [Feed]()
  var name : String
  var color : UIColor

  init(name groupName:String, userGroup:UserGroup, locked:Bool = false)
  {
    name = groupName
    color = FeedGroup.colorForUserGroup(userGroup)
  }

  //MARK: Public

  class func colorForUserGroup(_ group:UserGroup) -> UIColor
  {
    let CMV : CGFloat = 0.1 // the minimum value of a channel. Not zero because we want to be able multiply it with a factor.
    switch group
    {
      case .blue : return UIColor(red:CMV, green:CMV, blue:1.0, alpha:1.0)
      case .red: return UIColor(red:1.0, green: CMV, blue:CMV, alpha:1.0)
      case .green: return UIColor(red:CMV, green:0.7, blue:CMV, alpha:1.0)
      case .orange: return UIColor(red:0.95, green:0.7, blue:CMV, alpha:1.0)
    }
  }

  //MARK: NSCoding

  private let CodingKey_Feeds = "location"
  private let CodingKey_Name = "name"
  private let CodingKey_Color = "color"

  func encode(with coder: NSCoder)
  {
    coder.encode(feeds, forKey:CodingKey_Feeds)
    coder.encode(name, forKey:CodingKey_Name)
    coder.encode(color, forKey:CodingKey_Color)
  }

  required init?(coder decoder: NSCoder)
  {
    feeds = decoder.decodeObject(forKey: CodingKey_Feeds) as? [Feed] ?? [Feed]()
    name = decoder.decodeObject(forKey: CodingKey_Name) as? String ?? ""
    color = decoder.decodeObject(forKey: CodingKey_Color) as! UIColor
  }

}
