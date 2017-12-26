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
  @IBOutlet var groupPicker : UIPickerView!
  @IBOutlet var nameFieldTopMargin : NSLayoutConstraint!
  @IBOutlet var nameFieldToURLFieldVerticalMargin : NSLayoutConstraint!

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

    assert(groupPicker != nil, "the view for reassigning a feed to another group is not available")
    groupPicker.dataSource = self
    groupPicker.delegate = self

    let nc = NotificationCenter.default
    nc.addObserver(self, selector:#selector(FeedEditorViewController.adjustLayoutForKeyboard(_:)), name:NSNotification.Name.UIKeyboardWillShow, object:nil)
    nc.addObserver(self, selector:#selector(FeedEditorViewController.adjustLayoutForKeyboard(_:)), name:NSNotification.Name.UIKeyboardWillHide, object:nil)
    nc.addObserver(self, selector:#selector(FeedEditorViewController.handleTextDidChange(_:)), name:NSNotification.Name.UITextFieldTextDidChange, object:URLField)
  }

  override func viewWillAppear(_ animated: Bool)
  {
    _nightMode = UserDefaults.standard.bool(forKey: PreferenceKey_NightModeEnabled)
    self.view.tintColor = _nightMode ? UIColor(red:0.4, green:0.227, blue:0.94, alpha:1.0) : self.view.window?.tintColor
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
      FeedManager.shared.save()
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
      if var feed_ = feed, let text = URLField.text
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

  //MARK: Private

  private func _updateViewsFromModel()
  {
    let textBackgroundColor = _nightMode ? NightModeTextFieldBackgroundColor : DefaultTextFieldBackgroundColor
    let textColor = _nightMode ? DefaultBackgroundColor : NightModeBackgroundColor
    let backgroundColor = _nightMode ? NightModeBackgroundColor : DefaultBackgroundColor
    let keyboardColor = _nightMode ? UIKeyboardAppearance.dark : UIKeyboardAppearance.default
    self.view.backgroundColor = backgroundColor
    groupPicker.backgroundColor = backgroundColor

    nameField.backgroundColor = textBackgroundColor
    nameField.textColor = textColor
    nameField.keyboardAppearance = keyboardColor
    if let name = feed?.name
    {
      nameField!.text = name
    }

    URLField.backgroundColor = textBackgroundColor
    URLField.textColor = textColor
    URLField.keyboardAppearance = keyboardColor
    if let location = feed?.location
    {
      URLField!.text = location.absoluteString
      _validateDisplayedURL()
    }

    for (groupIndex, group) in FeedManager.shared.feedGroups.enumerated()
    {
      if group.feeds.contains(feed!)
      {
        groupPicker.selectRow(groupIndex, inComponent: 0, animated: false)
        break
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

extension FeedEditorViewController : UIPickerViewDelegate, UIPickerViewDataSource
{
  func numberOfComponents(in pickerView: UIPickerView) -> Int
  {
    return 1
  }

  func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int
  {
    return FeedManager.shared.feedGroups.count
  }

  func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String?
  {
    let groups = FeedManager.shared.feedGroups
    return row < groups.count ? groups[row].name : nil
  }

  func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int)
  {
    if feed != nil
    {
      assert(row >= 0, "The action method should only be callable by tapping on a group view.")
      _moveFeedToGroupAtIndex(row)
      _dismissWithDelay(0.2)
    }
  }

  private func _moveFeedToGroupAtIndex(_ groupIndex:Int)
  {
    if let feed_ = feed, groupIndex != FeedManager.shared.activeGroupIndex
    {
      FeedManager.shared.removeFeed(feed_, fromGroup: FeedManager.shared.activeGroupIndex)
      FeedManager.shared.feedGroups[groupIndex].feeds.append(feed_)
      _updateViewsFromModel()
    }
  }

}
