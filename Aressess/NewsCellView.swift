//
//  NewsCellView.swift
//  Aressess
//
//  Created by Kai Özer on 8/4/14.
//  Copyright (c) 2014, 2017 Kai Özer. All rights reserved.
//

import UIKit
import FXKit

class NewsCellView : UITableViewCell
{
  var newsTitleView : UILabel

  var news : News!
  {
    didSet
    {
      newsTitleView.text = (news != nil) ? news!.title : ""
      let nightMode = UserDefaults.standard.bool(forKey: PreferenceKey_NightModeEnabled)
      if (news != nil) && news.hasBeenRead
      {
        newsTitleView.textColor = nightMode ? NightModeTextColorOfReadNewsItem : DefaultTextColorOfReadNewsItem
      }
      else
      {
        newsTitleView.textColor = nightMode ? NightModeTextColor : DefaultTextColor
      }
    }
  }

  override init(style: UITableViewCellStyle, reuseIdentifier: String!)
  {
    newsTitleView = UILabel()
    super.init(style:.default, reuseIdentifier:reuseIdentifier)
    _configureViews()
    _layoutViews()
  }

  required init?(coder decoder: NSCoder)
  {
    newsTitleView = UILabel()
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
    contentView.layoutWithVisualFormats(["H:|-hm-[title]-hm-|", "V:|-vm-[title]-vm-|"],
      metricsInfo:["hm":12, "vm":10],
      viewsInfo:["title" : newsTitleView])
  }

  private func _configureViews()
  {
    for subview in contentView.subviews { subview.removeFromSuperview() }
    contentView.addSubview(newsTitleView)
    newsTitleView.numberOfLines = 0 // multi-line
    _updateFonts(nil)
    // handling changes to the font size
    NotificationCenter.default.addObserver(self, selector:#selector(NewsCellView._updateFonts(_:)), name:NSNotification.Name.UIContentSizeCategoryDidChange, object:nil)
  }

  /**
    This method must not be private, otherwise it will not be visible to the Objective-C runtime
    and sending a notification results in a crash
  */
  @objc func _updateFonts(_ notification:Notification!)
  {
    newsTitleView.font = UIFont.preferredFont(forTextStyle: UIFontTextStyle.headline)
  }
}
