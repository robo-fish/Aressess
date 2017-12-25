//
//  FeedEditingViewController.swift
//  Aressess
//
//  Created by Kai Oezer on 7/18/14.
//  Copyright (c) 2014, 2017 Kai Oezer. All rights reserved.
//

import UIKit

class FeedEditorViewController : UIViewController, UITextFieldDelegate
{
  @IBOutlet var nameField : UITextField!
  @IBOutlet var URLField : UITextField!
  @IBOutlet var groupViewsContainer : UIView!
  @IBOutlet var nameFieldTopMargin : NSLayoutConstraint!
  @IBOutlet var nameFieldToURLFieldVerticalMargin : NSLayoutConstraint!

  private var _groupViews = [FeedGroupView]()
  private var _nightMode = false

  required init?(coder:NSCoder)
  {
    super.init(coder:coder)
  }

  deinit
  {
    NotificationCenter.default.removeObserver(self)
  }

  var feed : Feed? = nil
  {
    didSet
    {
      _updateViewsFromModel()
    }
  }

  //MARK: UIViewController overrides

  override func viewDidLoad()
  {
    super.viewDidLoad()

    assert(nameField != nil, "the name field must already be constructed at this point")
    nameField.autocorrectionType = .no
    nameField.spellCheckingType = .no
    nameField.delegate = self
    nameField.placeholder = LocString("FeedEditorNameFieldPlaceholder")

    assert(URLField != nil, "the URL field must already be constructed at this point")
    URLField.keyboardType = .URL
    URLField.autocorrectionType = .no
    URLField.spellCheckingType = .no
    URLField.placeholder = LocString("FeedEditorURLFieldPlaceholder")
    URLField.delegate = self

    assert(groupViewsContainer != nil, "the view for assigning feeds to groups is not available")
    _createGroupAssignmentButtons()

    let nc = NotificationCenter.default
    nc.addObserver(self, selector:#selector(FeedEditorViewController.adjustLayoutForKeyboard(_:)), name:NSNotification.Name.UIKeyboardWillShow, object:nil)
    nc.addObserver(self, selector:#selector(FeedEditorViewController.adjustLayoutForKeyboard(_:)), name:NSNotification.Name.UIKeyboardWillHide, object:nil)
    nc.addObserver(self, selector:#selector(FeedEditorViewController.handleTextDidChange(_:)), name:NSNotification.Name.UITextFieldTextDidChange, object:URLField)
  }

  override func viewWillAppear(_ animated: Bool)
  {
    _nightMode = UserDefaults.standard.bool(forKey: PreferenceKey_NightModeEnabled)
    self.view.tintColor = _nightMode ? UIColor(red:0.4, green:0.227, blue:0.94, alpha:1.0) : self.view.window?.tintColor
    _layoutGroupAssignmentButtons()
    _updateViewsFromModel()
  }

  override func viewDidAppear(_ animated: Bool)
  {
    _updateViewsFromModel()
    if !_startEditingEmptyFields()
    {
      _startEditingURLFieldIfInvalid()
    }
  }

  override func viewWillDisappear(_ animated: Bool)
  {
    if feed != nil
    {
      FeedManager.sharedFeedManager().save()
    }
  }

  //MARK: UITextFieldDelegate

  func textFieldDidEndEditing(_ textField: UITextField)
  {
    if textField === nameField
    {
      if feed != nil && nameField.text != nil
      {
        feed!.name = nameField.text!
      }
    }
    else if textField === URLField
    {
      if let feed_ = feed, let text = URLField.text
      {
        if var url = URL(string:text)
        {
          if URLField.text!.count > 0
          {
            if let prefixedURL = URL(string:"http://\(text)")
            {
              url = prefixedURL
            }
          }
          feed_.location = url
        }
      }
    }
  }

  func textFieldShouldReturn(_ textField: UITextField) -> Bool
  {
    if (textField === nameField) && (URLField.text == nil || URLField.text!.isEmpty)
    {
      URLField.becomeFirstResponder()
    }
    else if (textField === URLField) && (nameField.text == nil || nameField.text!.isEmpty)
    {
      nameField.becomeFirstResponder()
    }
    else
    {
      textField.resignFirstResponder()
    }
    return false
  }

  //MARK: Actions

  @objc func handleSelectFeedGroup(_ gestureRecognizer:UIGestureRecognizer)
  {
    if feed != nil
    {
      var selectedGroupViewIndex = -1
      for (index,groupView) in _groupViews.enumerated()
      {
        if groupView === gestureRecognizer.view
        {
          selectedGroupViewIndex = index
          break
        }
      }
      assert(selectedGroupViewIndex >= 0, "The action method should only be callable by tapping on a group view.")
      _moveFeedToGroupAtIndex(selectedGroupViewIndex)
      _dismissWithDelay(0.2)
    }
  }

  //MARK: Notification Handlers

  @objc func adjustLayoutForKeyboard(_ notification:Notification)
  {
    if notification.name == NSNotification.Name.UIKeyboardWillShow
    {
      if self.view.traitCollection.verticalSizeClass == .compact
      {
        let height = self.view.window?.frame.size.height ?? 0
        if height < 330
        {
          nameFieldTopMargin.constant = 20
          nameFieldToURLFieldVerticalMargin.constant = 20
          UIView.animate(withDuration: 0.25, animations:{ self.view.layoutIfNeeded() })
        }
      }
    }
    else if nameFieldTopMargin.constant < 40
    {
      nameFieldTopMargin.constant = 40
      nameFieldToURLFieldVerticalMargin.constant = 40
      UIView.animate(withDuration: 0.25, animations:{ self.view.layoutIfNeeded() })
    }
  }

  @objc func handleTextDidChange(_ notification : Notification)
  {
    if let field = notification.object as? UITextField, field === URLField
    {
      _validateDisplayedURL()
    }
  }

  //MARK: FeedManagerExtrasObserver

  func handleDidUpdateExtras()
  {
    _updateViewsFromModel()
  }

  //MARK: Private

  private func _updateViewsFromModel()
  {
    let textBackgroundColor = _nightMode ? NightModeTextFieldBackgroundColor : DefaultTextFieldBackgroundColor
    let textColor = _nightMode ? DefaultBackgroundColor : NightModeBackgroundColor
    let backgroundColor = _nightMode ? NightModeBackgroundColor : DefaultBackgroundColor
    let keyboardColor = _nightMode ? UIKeyboardAppearance.dark : UIKeyboardAppearance.default
    self.view.backgroundColor = backgroundColor
    groupViewsContainer.backgroundColor = backgroundColor

    if nameField != nil
    {
      nameField.backgroundColor = textBackgroundColor
      nameField.textColor = textColor
      nameField.keyboardAppearance = keyboardColor
      if let name = feed?.name
      {
        nameField!.text = name
      }
    }

    if URLField != nil
    {
      URLField.backgroundColor = textBackgroundColor
      URLField.textColor = textColor
      URLField.keyboardAppearance = keyboardColor
      if let location = feed?.location
      {
        URLField!.text = location.absoluteString
        _validateDisplayedURL()
      }
    }

    if !_groupViews.isEmpty
    {
      for (index,feedGroup) in FeedManager.sharedFeedManager().feedGroups.enumerated()
      {
        let groupView = _groupViews[index]
        if feedGroup.feeds.contains(feed!)
        {
          groupView.layer.borderWidth = 4.0
          groupView.layer.borderColor = feedGroup.color.cgColor
          groupView.backgroundColor = UIColor.clear
        }
        else
        {
          groupView.layer.borderWidth = 0
          groupView.backgroundColor = feedGroup.color
        }
      }
    }
  }

  // :returns: whether one of the text fields has become first responder
  private func _startEditingEmptyFields() -> Bool
  {
    if nameField.text == nil || nameField.text!.isEmpty
    {
      nameField.becomeFirstResponder()
    }
    else if URLField.text == nil || URLField.text!.isEmpty
    {
      if nameField.text == LocString("DefaultFeedName")
      {
        // The user most probably wants to rename the feed before entering the URL.
        nameField.becomeFirstResponder()
        nameField.selectAll(self)
      }
      else
      {
        URLField.becomeFirstResponder()
      }
    }
    else
    {
      return false
    }
    return true
  }

  private func _startEditingURLFieldIfInvalid()
  {
    if (URLField.text != nil) && !URLField.text!.isEmpty
    {
      if let url = URL(string:URLField.text!)
      {
        if !isValidFeedAddress(url)
        {
          URLField.becomeFirstResponder()
        }
      }
    }
  }

  private func _createGroupAssignmentButton(_ color:UIColor) -> FeedGroupView
  {
    let feedGroupView = FeedGroupView(frame:CGRect(x: 0, y: 0, width: 20, height: 20))
    let layer = feedGroupView.layer
    layer.cornerRadius = 6.0
    layer.backgroundColor = color.cgColor
    feedGroupView.addGestureRecognizer(UITapGestureRecognizer(target:self, action:#selector(FeedEditorViewController.handleSelectFeedGroup(_:))))
    feedGroupView.translatesAutoresizingMaskIntoConstraints = false
    groupViewsContainer.addSubview(feedGroupView)
    return feedGroupView
  }

  private func _createGroupAssignmentButtons()
  {
    assert(_groupViews.count == 0, "group view creation should be performed only once")
    groupViewsContainer.clipsToBounds = false
    for feedGroup in FeedManager.sharedFeedManager().feedGroups
    {
      let buttonView = _createGroupAssignmentButton(feedGroup.color)
      _groupViews.append(buttonView)
    }
  }

  private func _layoutGroupAssignmentButtons()
  {
    let numSubviews = _groupViews.count
    if numSubviews > 0
    {
      let metrics = ["hm":12.0]
      var previousGroupView : UIView! = nil
      for (index, groupView) in _groupViews.enumerated()
      {
        if index == 0
        {
          groupViewsContainer.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[v]", options:[], metrics:metrics, views:["v":groupView]))
        }
        else
        {
          if index == numSubviews - 1
          {
            groupViewsContainer.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:[pv]-hm-[v]|", options:[], metrics:metrics, views:["v":groupView, "pv":previousGroupView]))
          }
          else
          {
            groupViewsContainer.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:[pv]-hm-[v]", options:[], metrics:metrics, views:["v":groupView, "pv":previousGroupView]))
          }
          groupViewsContainer.addConstraint(NSLayoutConstraint(item:groupView, attribute:.width, relatedBy:.equal, toItem:previousGroupView, attribute:.width, multiplier:1.0, constant:0))
        }
        groupViewsContainer.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[v]|", options:[], metrics:metrics, views:["v":groupView]))
        previousGroupView = groupView as UIView
      }
    }
  }

  private func _moveFeedToGroupAtIndex(_ groupIndex:Int)
  {
    for feedGroup in FeedManager.sharedFeedManager().feedGroups
    {
      let feedIndex = (feedGroup.feeds as NSArray).index(of: feed!)
      if feedIndex != NSNotFound
      {
        feedGroup.feeds.remove(at: feedIndex)
        break
      }
    }
    FeedManager.sharedFeedManager().feedGroups[groupIndex].feeds.append(feed!)
    _updateViewsFromModel()
  }

  private func _dismissWithDelay(_ delayInSeconds:TimeInterval)
  {
    let dispatchTime = DispatchTime.now() + Double(Int64(delayInSeconds * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
    DispatchQueue.main.asyncAfter(deadline: dispatchTime, execute: {
      if let navController = self.navigationController
      {
        navController.popViewController(animated: true)
      }
    })
  }

  private func _validateDisplayedURL()
  {
    if (URLField.text != nil) && !URLField.text!.isEmpty
    {
      if let url = URL(string:URLField.text!)
      {
        if isValidFeedAddress(url)
        {
          URLField.textColor = _nightMode ? DefaultBackgroundColor : NightModeBackgroundColor
        }
        else
        {
          URLField.textColor = UIColor.red
        }
      }
    }
  }
}
