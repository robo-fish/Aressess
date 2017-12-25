//
//  FeedGroup.swift
//  Aressess
//
//  Created by Kai Oezer on 8/13/14.
//  Copyright (c) 2014, 2017 Kai Oezer. All rights reserved.
//

import UIKit


class FeedGroup : Nameable, Codable
{
  var feeds = [Feed]()
  var name = ""
  private var color_r : Float = 0.0
  private var color_g : Float = 0.0
  private var color_b : Float = 0.0

  init()
  {
  }

  convenience init(name: String, feeds : [Feed])
  {
    self.init()
    self.name = name
    self.feeds = feeds
  }

  var color : UIColor {
    get { return UIColor(red:CGFloat(color_r), green:CGFloat(color_g), blue:CGFloat(color_b), alpha:1.0) }
    set {
      var comp : (r:CGFloat, g:CGFloat, b:CGFloat, a:CGFloat) = (0.0, 0.0, 0.0, 0.0)
      newValue.getRed(&comp.r, green: &comp.g, blue: &comp.b, alpha: &comp.a)
      (color_r, color_g, color_b) = (Float(comp.r), Float(comp.g), Float(comp.b))
    }
  }
}
