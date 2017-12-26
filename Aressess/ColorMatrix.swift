//
//  ColorMatrix.swift
//  Aressess
//
//  Created by Kai Oezer on 12/26/17.
//  Copyright © 2017 Kai Oezer. All rights reserved.
//

import UIKit

class ColorMatrix
{
  private(set) var view = UIView(frame:.zero)

  private let _colors : [UIColor] = [.black, .white]

  init()
  {
    view.backgroundColor = .red
  }
}
