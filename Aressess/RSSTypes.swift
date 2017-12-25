//
//  RSSTypes.swift
//  Aressess
//
//  Created by Kai Oezer on 7/29/14.
//  Copyright (c) 2014, 2017 Kai Oezer. All rights reserved.
//

import Foundation


open class RSSChannel
{
  open var items = [RSSItem]()
  open var title : String
  open var link : URL?
  open var description : String
  init()
  {
    title = ""
    link = nil
    description = ""
  }
}


public struct RSSItem
{
  public var title : String
  public var description : String
  public var link : String
  public init()
  {
    title = ""
    link = ""
    description = ""
  }
}
