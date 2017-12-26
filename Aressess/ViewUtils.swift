//
//  ViewUtils.swift
//  FXKit
//
//  Created by Kai Oezer on 7/25/14.
//  Copyright (c) 2014, 2017 Kai Oezer. All rights reserved.
//

import UIKit

public class ViewUtils
{
  // Use this method if you want to turn a view into an image and then process the image before using it.
  public class func imageOfView(_ view:UIView) -> UIImage
  {
    UIGraphicsBeginImageContextWithOptions(view.bounds.size, false, 0.0)
    view.drawHierarchy(in: view.bounds, afterScreenUpdates:false)
    let result = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    return result!
  }

  // Use this method if you want to turn a view into an image (embedded in a view) that will not be further processed.
  public class func snapshotViewFromView(_ view:UIView) -> UIView
  {
    return view.snapshotView(afterScreenUpdates: false)!
  }

  /**
   Convenience method for adding layout constraints to a view.

   Adds layout constraints of subviews to the given view according to the given visual format strings, the given metric names dictionary and the given view names dictionary.

   - parameter view: the view to which the constraints are added
   */
  public class func layout(in view:UIView, visualFormats:[String], metricsInfo metrics:[String:Any]?, viewsInfo views:[String:UIView])
  {
    for subview in views.values
    {
      subview.translatesAutoresizingMaskIntoConstraints = false
    }
    for format in visualFormats
    {
      view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: format, options:NSLayoutFormatOptions(rawValue: 0), metrics:metrics, views:views))
    }
  }
}


public extension UIView
{
  public func layoutWithVisualFormats(_ visualFormats:[String], metricsInfo metrics:[String:NSNumber]?, viewsInfo views:[String:UIView])
  {
    ViewUtils.layout(in: self, visualFormats:visualFormats, metricsInfo:metrics, viewsInfo:views)
  }
}

