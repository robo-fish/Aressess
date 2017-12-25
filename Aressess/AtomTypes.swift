//
//  AtomTypes.swift
//  Aressess
//
//  Created by Kai Oezer on 8/1/14.
//  Copyright (c) 2014, 2017 Kai Oezer. All rights reserved.
//

import Foundation


open class AtomFeed
{
  open var entries = [AtomEntry]()
  open var title : String = ""
  open var subtitle : String = ""
  open var link : URL?
  open var lastUpdated : Date?
  public init()
  {
    link = nil
    lastUpdated = nil
  }
}


open class AtomEntry
{
  open var title : String?
  open var summary : String?
  open var content : String?
  open var lastUpdated : Date?
  open var link : String?
  public init()
  {
    title = nil;
    summary = nil;
    content = nil;
    lastUpdated = nil
    link = nil
  }
}
