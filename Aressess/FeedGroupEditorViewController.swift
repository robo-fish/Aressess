//
//  FeedGroupEditorViewController.swift
//  Aressess
//
//  Created by Kai Oezer on 12/26/17.
//  Copyright © 2017 Kai Oezer. All rights reserved.
//

import UIKit

class FeedGroupEditorViewController : UIViewController
{
  @IBOutlet var nameField : UITextField?
  @IBOutlet var colorMatrixContainer : UIView?
  private var _colorMatrix = ColorMatrix()

  override func viewDidLoad()
  {
    assert(nameField != nil)
    assert(colorMatrixContainer != nil)

    let matrixView = _colorMatrix.view
    colorMatrixContainer?.addSubview(matrixView)
    colorMatrixContainer?.layoutWithVisualFormats(["H:|[m]|", "V:|[m]|"], metricsInfo: nil, viewsInfo:["m" : matrixView])
  }


}
