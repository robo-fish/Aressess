//
//  Feed.swift
//  Aressess
//
//  Created by Kai Oezer on 8/13/14.
//  Copyright (c) 2014, 2017 Kai Oezer. All rights reserved.
//

import Foundation


class Feed : NSObject, NSCoding
{
  var location : URL? = nil
  var name : String = ""

  init(location: URL, name: String)
  {
    self.location = location
    self.name = name
  }

  //MARK: NSCoding

  private let CodingKey_Location = "location"
  private let CodingKey_Name = "name"

  func encode(with coder: NSCoder)
  {
    if location != nil
    {
      coder.encode(location!, forKey:CodingKey_Location)
    }
    coder.encode(name, forKey:CodingKey_Name)
  }

  required init?(coder decoder: NSCoder)
  {
    location = decoder.decodeObject(forKey: CodingKey_Location) as? URL
    name = decoder.decodeObject(forKey: CodingKey_Name) as! String
  }
}

// implementation of Equatable
func ==(lhs:Feed, rhs:Feed) -> Bool
{
  return (lhs.name == rhs.name) && (lhs.location == rhs.location)
}
