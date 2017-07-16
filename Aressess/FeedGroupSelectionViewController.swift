//
//  FeedGroupSelectionViewController.swift
//  Aressess
//
//  Created by Kai Özer on 8/16/14.
//  Copyright (c) 2014, 2017 Kai Özer. All rights reserved.
//

import UIKit
import FXKit

protocol FeedGroupSelectionDelegate
{
  func feedGroupSelector(_ feedGroupSelector:FeedGroupSelectionViewController, selectedGroupIndex:Int)
}


class FeedGroupSelectionViewController : UIViewController
{
  @IBOutlet var backgroundView : UIImageView!

  private var labels = [UILabel]()
  private var groupViews = [FeedGroupView]()

  var delegate : FeedGroupSelectionDelegate? = nil
  var backgroundImage : UIImage? = nil

  override func viewDidLoad()
  {
    _createGroupViews()
    _layoutGroupViews()
    _installDismissingSwipeGestureRecognizerOnView(self.view)
    self.view.addGestureRecognizer(UITapGestureRecognizer(target:self, action:#selector(FeedGroupSelectionViewController.handleTap(_:))))
  }

  override func viewWillAppear(_ animated:Bool)
  {
    super.viewWillAppear(animated)
    let nightMode = UserDefaults.standard.bool(forKey: PreferenceKey_NightModeEnabled)
    self.view.backgroundColor = nightMode ? NightModeBackgroundColor : DefaultBackgroundColor

    if backgroundImage != nil
    {
      if let blurredBackground = ImageUtils.newImageFromImage(backgroundImage!, brightnessChange:nightMode ? -0.7 : 0.7, blurRadius:3.0)
      {
        self.view.layer.contents = blurredBackground.cgImage
      }
    }
    _updateLabels()
    _updateGroupViews()
  }

  //MARK: Actions

  @objc func handleTap(_ sender: UITapGestureRecognizer)
  {
    if sender.state == .ended
    {
      if sender.view === self.view
      {
        dismiss(animated: true, completion:nil)
      }
      else
      {
        var selectedGroupIndex = -1
        for (index, view) in groupViews.enumerated()
        {
          if view === sender.view
          {
            selectedGroupIndex = index
            break
          }
        }
        let fm = FeedManager.sharedFeedManager()
        if (selectedGroupIndex >= 0) && (selectedGroupIndex < fm.feedGroups.count)
        {
          delegate?.feedGroupSelector(self, selectedGroupIndex:selectedGroupIndex)
        }
      }
    }
  }

  @objc func handleSwipe(_ gestureRecognizer:UISwipeGestureRecognizer)
  {
    dismiss(animated: true, completion:nil)
  }

  //MARK: FeedManagerExtrasObserver

  func handleDidUpdateExtras()
  {
    _updateLabels()
    _updateGroupViews()
  }

  //MARK: Private

  private func _createGroupView(_ color:UIColor) -> FeedGroupView
  {
    let dummyFrame = CGRect(x: 0, y: 0, width: 100, height: 44)
    let groupView = FeedGroupView(frame:dummyFrame)
    let layer = groupView.layer
    layer.cornerRadius = 12.0
    layer.backgroundColor = color.cgColor
    let tapRecognizer = UITapGestureRecognizer(target:self, action:#selector(FeedGroupSelectionViewController.handleTap(_:)))
    groupView.addGestureRecognizer(tapRecognizer)
    _installDismissingSwipeGestureRecognizerOnView(groupView)
    view.addSubview(groupView)
    return groupView
  }

  private func _createLabelForView(_ view:UIView) -> UILabel
  {
    let newLabel = UILabel(frame:CGRect(x: 0, y: 0, width: 80, height: 20))
    newLabel.textColor = UIColor.white
    view.addSubview(newLabel)
    newLabel.translatesAutoresizingMaskIntoConstraints = false
    view.addConstraint(NSLayoutConstraint(item:newLabel, attribute:.centerX, relatedBy:.equal, toItem:view, attribute:.centerX, multiplier:1.0, constant:0))
    view.addConstraint(NSLayoutConstraint(item:newLabel, attribute:.centerY, relatedBy:.equal, toItem:view, attribute:.centerY, multiplier:1.0, constant:0))
    view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "|-12-[label]-12-|", options:NSLayoutFormatOptions(rawValue: 0), metrics:nil, views:["label":newLabel]))
    return newLabel
  }

  private func _createGroupViews()
  {
    for feedGroup in FeedManager.sharedFeedManager().feedGroups
    {
      let groupView = _createGroupView(feedGroup.color)
      groupViews.append(groupView)
      let label = _createLabelForView(groupView)
      labels.append(label)
    }
  }

  private func _layoutGroupViews()
  {
    if groupViews.count > 0
    {
      let metrics : [String : NSNumber] = ["vm":16, "hm":12, "vh":44]
      var previousView : UIView? = nil
      for currentView in groupViews
      {
        if previousView == nil
        {
          view.layoutWithVisualFormats(["H:|-hm-[v]-hm-|", "V:[v(vh)]-vm-|"], metricsInfo:metrics, viewsInfo:["v":currentView])
        }
        else
        {
          view.layoutWithVisualFormats(["H:|-hm-[v]-hm-|", "V:[v(vh)]-vm-[prev]"], metricsInfo:metrics, viewsInfo:["v":currentView, "prev":previousView!])
        }
        previousView = currentView
      }
    }
  }

  private func _updateLabels()
  {
    let fm = FeedManager.sharedFeedManager()
    assert(fm.feedGroups.count == labels.count, "there must be as many labels as there are feed groups")
    for (index,feedGroup) in fm.feedGroups.enumerated()
    {
      var labelText = ""
      var textAttributes : [NSAttributedStringKey:Any] = [NSAttributedStringKey.kern : NSNull()] // reduces letter spacing to fit the text if necessary
      let numFeedsInGroup = feedGroup.feeds.count
      if numFeedsInGroup >= 1
      {
        labelText = feedGroup.feeds[0].name
        if numFeedsInGroup > 1
        {
          labelText += " " + LocString("AndMore")
        }
        textAttributes[NSAttributedStringKey.font] = UIFont.boldSystemFont(ofSize: 18.0)
      }
      else
      {
        labelText = LocString("EmptyFeedGroup")
        textAttributes[NSAttributedStringKey.font] = UIFont.systemFont(ofSize: 14.0)
      }
      labels[index].attributedText = NSAttributedString(string:labelText, attributes:textAttributes)
      labels[index].textAlignment = .center
    }
  }

  private func _updateGroupViews()
  {
    let fm = FeedManager.sharedFeedManager()
    let nightMode = UserDefaults.standard.bool(forKey: PreferenceKey_NightModeEnabled)
    for (index,feedGroup) in fm.feedGroups.enumerated()
    {
      let label = labels[index]
      let currentView = groupViews[index]
      let feedGroupColor = nightMode ? feedGroup.color.lighter(1.10) : feedGroup.color
      let layer = currentView.layer
      if index == fm.activeGroupIndex
      {
        layer.borderWidth = 4
        layer.backgroundColor = UIColor.clear.cgColor
        layer.borderColor = feedGroupColor.cgColor
        label.textColor = feedGroupColor
      }
      else
      {
        layer.borderWidth = 0
        layer.backgroundColor = feedGroupColor.cgColor
        label.textColor = UIColor.white
      }
    }
  }

  private func _installDismissingSwipeGestureRecognizerOnView(_ sourceView:UIView)
  {
    let swipeRecognizer = UISwipeGestureRecognizer(target:self, action:#selector(FeedGroupSelectionViewController.handleSwipe(_:)))
    swipeRecognizer.direction = .down
    swipeRecognizer.numberOfTouchesRequired = 1
    sourceView.addGestureRecognizer(swipeRecognizer)
  }

}
