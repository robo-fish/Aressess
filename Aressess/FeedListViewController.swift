//
//  FeedListViewController.swift
//  Aressess
//
//  Created by Kai Özer on 7/17/14.
//  Copyright (c) 2014, 2017 Kai Özer. All rights reserved.
//

import UIKit
import FXKit

class FeedListViewController : UITableViewController, FeedGroupSelectionDelegate, FeedManagerExternalChangeObserver
{
  var detailViewController: FeedViewController? = nil
  private var selectedRow = -1 // we need to store the row index here because 'cell.selected' does not work reliably
  private var feedGroupSelector : UIBarButtonItem? = nil
  private var nightModeIsOn = false

  override func awakeFromNib()
  {
    super.awakeFromNib()
    self.clearsSelectionOnViewWillAppear = true
    tableView.delegate = self
  }

  override func viewDidLoad()
  {
    super.viewDidLoad()

    self.navigationItem.leftBarButtonItem = self.editButtonItem

    let addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(FeedListViewController.insertNewFeed(_:)))
    self.navigationItem.rightBarButtonItem = addButton
    if let navController = self.splitViewController?.viewControllers.last as? UINavigationController
    {
      self.detailViewController = navController.topViewController as? FeedViewController
    }

    title = LocString("FeedsListTitle")
    _createToolbarItems()
    FeedManager.sharedFeedManager().addExternalChangeObserver(self)
    _handleFeedGroupChange() // for initial configuration

    _updateColors()
    NotificationCenter.default.addObserver(self, selector:#selector(FeedListViewController.handleNightModeChanged(_:)), name:NSNotification.Name(rawValue: NightModeChangedNotification), object:nil)
  }

  deinit
  {
    NotificationCenter.default.removeObserver(self)
    FeedManager.sharedFeedManager().removeExternalChangeObserver(self)
  }

  override func viewWillAppear(_ animated:Bool)
  {
    super.viewWillAppear(animated)
    selectedRow = -1
    tableView.reloadData()
  }

  override func didReceiveMemoryWarning()
  {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }

  override var preferredStatusBarStyle: UIStatusBarStyle
  {
    get { return nightModeIsOn ? .lightContent : .default }
  }

  @objc func insertNewFeed(_ sender: AnyObject)
  {
    _createNewFeed(name: LocString("DefaultFeedName"), for: nil, insertAtTopOfGroup: true)
  }

  func insertFeed(name : String, for location : URL)
  {
    _createNewFeed(name: name, for: location, insertAtTopOfGroup: true)
  }

  //MARK: FeedManagerExternalChangeObserver

  func handleFeedGroupContentsChangedExternally()
  {
    _handleFeedGroupChange()
  }

  //MARK: Segues

  override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool
  {
    if identifier == "showDetail"
    {
      if let selectedRow = (tableView.indexPathForSelectedRow as NSIndexPath?)?.row
      {
        let feed = FeedManager.sharedFeedManager().activeFeeds[selectedRow]
        return (feed.location != nil) && isValidFeedAddress(feed.location!)
      }
    }
    return true
  }

  override func prepare(for segue:UIStoryboardSegue, sender:Any?)
  {
    if segue.identifier == "showDetail"
    {
      if let indexPath = self.tableView.indexPathForSelectedRow
      {
        let feed = FeedManager.sharedFeedManager().activeFeeds[(indexPath as NSIndexPath).row]
        if
          let navigationController = segue.destination as? UINavigationController,
          let feedViewController = navigationController.topViewController as? FeedViewController
        {
          feedViewController.feed = feed
        }
      }
    }
    else if segue.identifier == "showFeedEditor"
    {
      if
        let cell = sender as? UITableViewCell,
        let indexPath = self.tableView.indexPath(for: cell),
        let feedEditorViewController = segue.destination as? FeedEditorViewController
      {
        let editedFeed = FeedManager.sharedFeedManager().activeFeeds[(indexPath as NSIndexPath).row]
        feedEditorViewController.feed = editedFeed
        selectedRow = -1
        _clearFeedView()
      }
    }
    else if segue.identifier == "showFeedGroupSelector"
    {
      if let selectionView = segue.destination as? FeedGroupSelectionViewController
      {
        selectionView.delegate = self
        if let navController = self.navigationController
        {
          selectionView.backgroundImage = ViewUtils.imageOfView(navController.view)
        }
      }
    }
  }

  //MARK: UITableViewDataSource

  override func numberOfSections(in tableView: UITableView) -> Int
  {
    return 1
  }

  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
  {
    return FeedManager.sharedFeedManager().activeFeeds.count
  }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
  {
    let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) 
    cell.accessoryType = .detailDisclosureButton
    let feed = FeedManager.sharedFeedManager().activeFeeds[(indexPath as NSIndexPath).row]
    cell.textLabel?.text = feed.name
    cell.textLabel?.font = UIFont.preferredFont(forTextStyle: UIFontTextStyle.headline)
    cell.textLabel?.textColor = nightModeIsOn ? NightModeTextColor : DefaultTextColor
    cell.textLabel?.highlightedTextColor = nightModeIsOn ? NightModeTextColor : DefaultTextColor
    let coloredBackgroundView = UIView()
    coloredBackgroundView.backgroundColor = nightModeIsOn ? FeedManager.sharedFeedManager().darkerActiveColor : FeedManager.sharedFeedManager().lighterActiveColor
    cell.selectedBackgroundView = coloredBackgroundView
    cell.backgroundColor = nightModeIsOn ? NightModeBackgroundColor : DefaultBackgroundColor
    return cell
  }

  override func tableView(_ tableView:UITableView, moveRowAt sourceIndexPath:IndexPath, to destinationIndexPath:IndexPath)
  {
    let sourceRowIndex = (sourceIndexPath as NSIndexPath).row
    let destinationRowIndex = (destinationIndexPath as NSIndexPath).row
    FeedManager.sharedFeedManager().moveFeedInActiveGroupFromRow(sourceRowIndex, toRow:destinationRowIndex)

    if selectedRow == sourceRowIndex
    {
      selectedRow = destinationRowIndex
    }
    else if (selectedRow > sourceRowIndex) && (selectedRow < destinationRowIndex)
    {
      selectedRow -= 1
    }
    else if (selectedRow >= destinationRowIndex) && (selectedRow < sourceRowIndex)
    {
      selectedRow += 1
    }

    tableView.reloadData()
  }

  //MARK: UITableViewDelegate

  override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool
  {
    // Return false if you do not want the specified item to be editable.
    return true
  }

  override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath)
  {
    if editingStyle == .delete
    {
      FeedManager.sharedFeedManager().removeFeedAtIndex((indexPath as NSIndexPath).row)
      tableView.deleteRows(at: [indexPath], with: .fade)
      if selectedRow == (indexPath as NSIndexPath).row
      {
        selectedRow = -1
        _clearFeedView()
      }
      else if selectedRow > (indexPath as NSIndexPath).row
      {
        selectedRow -= 1
      }
    }
    else if editingStyle == .insert
    {
      insertNewFeed(self)
    }
  }

  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
  {
    let feed = FeedManager.sharedFeedManager().activeFeeds[(indexPath as NSIndexPath).row]
    if (feed.location != nil) && isValidFeedAddress(feed.location!)
    {
      if let window = self.view.window
      {
        if window.rootViewController!.traitCollection.horizontalSizeClass == .regular
        {
          _popNewsContentView()
          detailViewController?.feed = feed
        }
      }
    }
    else
    {
      performSegue(withIdentifier: "showFeedEditor", sender:self.tableView.cellForRow(at: indexPath))
    }
  }

  override func tableView(_ tableView:UITableView, willSelectRowAt indexPath : IndexPath) -> IndexPath?
  {
    if tableView.cellForRow(at: indexPath) != nil
    {
      if selectedRow >= 0
      {
        if let currentSelectedCell = tableView.cellForRow(at: NSIndexPath(indexes:[0,selectedRow], length: 2) as IndexPath)
        {
          currentSelectedCell.backgroundColor = UIColor.clear
        }
      }
      selectedRow = (indexPath as NSIndexPath).row
    }
    return indexPath
  }

  override func tableView(_ tableView:UITableView, willDeselectRowAt indexPath : IndexPath) -> IndexPath?
  {
    if let cell = tableView.cellForRow(at: indexPath)
    {
      cell.backgroundColor = UIColor.clear
    }
    return indexPath
  }

  //MARK: FeedGroupSelectionDelegate

  func feedGroupSelector(_ feedGroupSelector:FeedGroupSelectionViewController, selectedGroupIndex:Int)
  {
    let fm = FeedManager.sharedFeedManager()
    if (selectedGroupIndex >= 0) && (selectedGroupIndex < fm.feedGroups.count)
    {
      fm.activeGroupIndex = selectedGroupIndex
      _handleFeedGroupChange()
      feedGroupSelector.delegate = nil // prevents retain cycle
      feedGroupSelector.dismiss(animated: true, completion:nil)
    }
  }

  //MARK: Actions and Notification Handlers

  @objc func showFeedGroupSelector(_ sender:AnyObject!)
  {
    if self.view.window != nil
    {
      performSegue(withIdentifier: "showFeedGroupSelector", sender:self)
    }
  }

  @objc func showHelp(_ sender:AnyObject!)
  {
    performSegue(withIdentifier: "showHelp", sender:self)
  }

  func showSettings(_ sender:AnyObject!)
  {
    performSegue(withIdentifier: "showSettings", sender:self)
  }

  @objc func handleNightModeChanged(_ notification:Notification!)
  {
    _updateColors()
  }

  @objc func toggleNightMode(_ sender:AnyObject!)
  {
    toggleGlobalNightMode()
  }

  //MARK: Private

  private func _createToolbarItems()
  {
    let night_mode_toolbar_icon = UIImage(named:"toolbar_night_mode")
    assert(night_mode_toolbar_icon != nil)
    let leftButton = UIBarButtonItem(image:night_mode_toolbar_icon, landscapeImagePhone:night_mode_toolbar_icon, style:.plain, target:self, action:#selector(FeedListViewController.toggleNightMode(_:)))
    let groupSelector = UIBarButtonItem(title:LocString("FeedGroupSelectorTitle"), style:.plain, target:self, action:#selector(FeedListViewController.showFeedGroupSelector(_:)))
    groupSelector.setTitleTextAttributes([NSAttributedStringKey.font:UIFont.boldSystemFont(ofSize: 18.0)], for:UIControlState())
    let flexSpace = UIBarButtonItem(barButtonSystemItem:.flexibleSpace, target:self, action:nil)
    let helpButton = UIBarButtonItem(title:"?", style:.plain, target:self, action:#selector(FeedListViewController.showHelp(_:)))
    let leadingFixedSpace = UIBarButtonItem(barButtonSystemItem:.fixedSpace, target:self, action:nil)
    leadingFixedSpace.width = 24.0
    let trailingFixedSpace = UIBarButtonItem(barButtonSystemItem:.fixedSpace, target:self, action:nil)
    trailingFixedSpace.width = 6.0
    self.toolbarItems = [leftButton, leadingFixedSpace, flexSpace, groupSelector, flexSpace, helpButton, trailingFixedSpace]
    feedGroupSelector = groupSelector
  }

  private func _clearFeedView()
  {
    if let split = self.splitViewController
    {
      let controllers = split.viewControllers
      if let navController = controllers[controllers.count-1] as? UINavigationController
      {
        if let feedViewController = navController.topViewController as? FeedViewController
        {
          feedViewController.feed = nil
        }
        else
        {
          // Dismissing the news content view before clearing the feed view.
          navController.popViewController(animated: true)
          if let feedViewController = navController.topViewController as? FeedViewController
          {
            feedViewController.feed = nil
          }
        }
      }
    }
  }

  private func _popNewsContentView()
  {
    if let split = splitViewController
    {
      if let navController = split.viewControllers[split.viewControllers.count - 1] as? UINavigationController
      {
        if navController.topViewController is NewsContentViewController
        {
          navController.popViewController(animated: true)
        }
      }
    }
  }

  private func _updateColors()
  {
    let on = UserDefaults.standard.bool(forKey: PreferenceKey_NightModeEnabled)
    if on != nightModeIsOn
    {
      nightModeIsOn = on
      setNeedsStatusBarAppearanceUpdate()
      _updateGroupColors()
      _updateSplitViewColors()
      self.view.backgroundColor = nightModeIsOn ? NightModeBackgroundColor : DefaultBackgroundColor
      if let navController = self.navigationController
      {
        navController.navigationBar.barTintColor = nightModeIsOn ? NightModeNavigationBarBackgroundColor : DefaultNavigationBarBackgroundColor
        navController.navigationBar.titleTextAttributes = [NSAttributedStringKey.foregroundColor : (nightModeIsOn ? NightModeTitleColor : DefaultTitleColor)]
        navController.toolbar.barTintColor = navController.navigationBar.barTintColor
        navController.view.backgroundColor = nightModeIsOn ? NightModeBackgroundColor : DefaultBackgroundColor
      }
      tableView.indicatorStyle = nightModeIsOn ? .white : .default
      tableView.reloadData()
    }
  }

  private func _updateGroupColors()
  {
    let activeColor = FeedManager.sharedFeedManager().activeColor
    let darkerActiveColor = FeedManager.sharedFeedManager().darkerActiveColor
    let veryDarkActiveColor = darkerActiveColor.lighter(0.6)
    tableView.sectionIndexBackgroundColor = nightModeIsOn ? veryDarkActiveColor : activeColor
    tableView.separatorColor = nightModeIsOn ? veryDarkActiveColor : darkerActiveColor
    feedGroupSelector?.tintColor = nightModeIsOn ? activeColor : darkerActiveColor
  }

  private func _updateSplitViewColors()
  {
    if let splitter = self.splitViewController
    {
      // Note: The background color is also used for the divider line.
      splitter.view.backgroundColor = nightModeIsOn ? NightModeSplitViewBackgroundColor : DefaultSplitViewBackgroundColor
    }
  }

  private func _handleFeedGroupChange()
  {
    _updateGroupColors()
    tableView.reloadData()
  }

  private func _createNewFeed(name : String, for location : URL?, insertAtTopOfGroup : Bool)
  {
    let locationString = location?.absoluteString ?? ""
    let fm = FeedManager.sharedFeedManager()
    if fm.activeFeeds.count > 0
    {
      fm.insertFeedAtIndex(0, name: name, location: locationString)
    }
    else
    {
      fm.addFeed(name: name, location: locationString)
    }
    let indexPath = IndexPath(row: 0, section: 0)
    tableView.insertRows(at: [indexPath], with: .automatic)
    tableView.scrollToRow(at: indexPath, at:.top, animated:true)
    selectedRow += 1
    performSegue(withIdentifier: "showFeedEditor", sender:self.tableView.cellForRow(at: indexPath))
  }
}

