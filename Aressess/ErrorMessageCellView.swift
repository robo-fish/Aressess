//
//  ErrorMessageCellView.swift
//  Aressess
//
//  Created by Kai Oezer on 8/26/14.
//  Copyright (c) 2014, 2017 Kai Oezer. All rights reserved.
//

import UIKit

class ErrorMessageCellView : UITableViewCell
{
  var messageLabel : UILabel

  var message : String = ""
  {
    didSet
    {
      messageLabel.text = message
    }
  }

  override init(style: UITableViewCellStyle, reuseIdentifier: String!)
  {
    messageLabel = UILabel()
    super.init(style:.default, reuseIdentifier:reuseIdentifier)
    _configureViews()
    _layoutViews()
  }

  required init?(coder decoder: NSCoder)
  {
    messageLabel = UILabel()
    super.init(coder:decoder)
    _configureViews()
    _layoutViews()
  }

  deinit
  {
    NotificationCenter.default.removeObserver(self)
  }

  class func estimatedHeight() -> CGFloat
  {
    return 70.0
  }

  /*
  // Only override drawRect: if you perform custom drawing.
  // An empty implementation adversely affects performance during animation.
  override func drawRect(rect: CGRect)
  {
  // Drawing code
  }
  */

  //MARK: Private

  private func _layoutViews()
  {
    contentView.removeConstraints(contentView.constraints)
    contentView.layoutWithVisualFormats(["H:|-hm-[label]-hm-|", "V:|-vm-[label]"],
      metricsInfo:["hm":12, "vm":100],
      viewsInfo:["label" : messageLabel])
  }

  private func _configureViews()
  {
    for subview in contentView.subviews { subview.removeFromSuperview() }
    contentView.addSubview(messageLabel)
    messageLabel.numberOfLines = 0 // multi-line
    messageLabel.textAlignment = .center
    _updateFonts(nil)
    // handling changes to the font size
    NotificationCenter.default.addObserver(self, selector:#selector(ErrorMessageCellView._updateFonts(_ :)), name:NSNotification.Name.UIContentSizeCategoryDidChange, object:nil)
  }

  /**
  This method must not be private, otherwise it will not be visible to the Objective-C runtime
  and sending a notification results in a crash
  */
  @objc func _updateFonts(_ notification:Notification!)
  {
    messageLabel.font = UIFont.preferredFont(forTextStyle: UIFontTextStyle.headline)
  }
}
