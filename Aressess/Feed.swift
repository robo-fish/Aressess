//
//  Feed.swift
//  Aressess
//
//  Created by Kai Oezer on 8/13/14.
//  Copyright (c) 2014, 2017 Kai Oezer. All rights reserved.
//

import Foundation


struct Feed : Nameable, Codable
{
  var location : URL
  var name : String

  init(location: URL, name: String)
  {
    self.location = location
    self.name = name
  }

  // The compiler automatically generates the Encodable-compliant function and Decodable-compliant initializer.
}

extension Feed : Equatable
{
  static func ==(lhs: Feed, rhs: Feed) -> Bool
  {
    return (lhs.name == rhs.name) && (lhs.location == rhs.location)
  }
}
