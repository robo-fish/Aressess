//
//  FeedGroupViewController.swift
//  Aressess
//
//  Created by Kai Oezer on 7/17/14.
//  Copyright (c) 2014, 2017 Kai Oezer. All rights reserved.
//

import UIKit

class FeedGroupViewController : UITableViewController
{
  private var _dataSource : AressessTableViewDataSource<Feed>?
  private var _selectedRow = -1 // we need to store the row index here because 'cell.selected' does not work reliably
  private var _nightModeIsOn = false
  private let FeedGroupCellIdentifier = "FeedGroupCell"

  deinit
  {
    NotificationCenter.default.removeObserver(self)
    FeedManager.shared.removeExternalChangeObserver(self)
  }

  override func awakeFromNib()
  {
    super.awakeFromNib()
    self.clearsSelectionOnViewWillAppear = true
    tableView.delegate = self
    _dataSource = AressessTableViewDataSource<Feed>(tableView: tableView, cellIdentifier:"FeedGroupCell")
  }

  override func viewDidLoad()
  {
    super.viewDidLoad()

    self.navigationItem.rightBarButtonItem = editButtonItem
    self.navigationItem.largeTitleDisplayMode = .always
    self.navigationItem.title = LocString("FeedsListTitle")
    self.navigationItem.searchController = _dataSource?.searchController
    hidesBottomBarWhenPushed = true

    FeedManager.shared.addExternalChangeObserver(self)
    _handleFeedGroupChange() // for initial configuration

    _updateColors()
    NotificationCenter.default.addObserver(self, selector:#selector(FeedGroupViewController.handleNightModeChanged(_:)), name:NSNotification.Name(rawValue: NightModeChangedNotification), object:nil)
  }

  override func viewWillAppear(_ animated:Bool)
  {
    super.viewWillAppear(animated)
    _dataSource?.elements = FeedManager.shared.activeFeeds
    _selectedRow = -1
    tableView.reloadData()
  }

  override var preferredStatusBarStyle: UIStatusBarStyle
  {
    get { return _nightModeIsOn ? .lightContent : .default }
  }

  @objc func insertNewFeed(_ sender: AnyObject)
  {
    _createNewFeed(name: LocString("DefaultFeedName"), for: nil, insertAtTopOfGroup: true)
  }

  func insertFeed(name : String, for location : URL)
  {
    _createNewFeed(name: name, for: location, insertAtTopOfGroup: true)
  }

  override func setEditing(_ editing: Bool, animated: Bool)
  {
    super.setEditing(editing, animated: animated)
    if editing
    {
      let addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(FeedGroupViewController.insertNewFeed(_:)))
      self.navigationItem.leftBarButtonItem = addButton
    }
    else
    {
      self.navigationItem.leftBarButtonItem = nil
    }
  }

  override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool
  {
    if identifier == "showFeed"
    {
      if let selectedRow = tableView.indexPathForSelectedRow?.row
      {
        let feed = FeedManager.shared.activeFeeds[selectedRow]
        return isValidFeedAddress(feed.location)
      }
    }
    return true
  }

  override func prepare(for segue:UIStoryboardSegue, sender:Any?)
  {
    if segue.identifier == "showFeed"
    {
      guard let indexPath = self.tableView.indexPathForSelectedRow else { return }
      let feed = FeedManager.shared.activeFeeds[indexPath.row]
      guard let feedViewController = segue.destination as? FeedViewController else { return }
      feedViewController.feed = feed
    }
    else if segue.identifier == "showFeedEditor"
    {
      if
        let cell = sender as? UITableViewCell,
        let indexPath = self.tableView.indexPath(for: cell),
        let feedEditorViewController = segue.destination as? FeedEditorViewController
      {
        let editedFeed = FeedManager.shared.activeFeeds[indexPath.row]
        feedEditorViewController.feed = editedFeed
        _selectedRow = -1
        _clearFeedView()
      }
    }
  }

  @objc func handleNightModeChanged(_ notification:Notification!)
  {
    _updateColors()
  }
}

extension FeedGroupViewController
{
  //MARK: Private
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
    if on != _nightModeIsOn
    {
      _nightModeIsOn = on
      setNeedsStatusBarAppearanceUpdate()
      _updateGroupColors()
      self.view.backgroundColor = _nightModeIsOn ? NightModeBackgroundColor : DefaultBackgroundColor
      tableView.indicatorStyle = _nightModeIsOn ? .white : .default
      tableView.reloadData()
    }
  }

  private func _updateGroupColors()
  {
    let activeColor = FeedManager.shared.activeColor
    let darkerActiveColor = FeedManager.shared.darkerActiveColor
    let veryDarkActiveColor = darkerActiveColor.lighter(0.6)
    tableView.sectionIndexBackgroundColor = _nightModeIsOn ? veryDarkActiveColor : activeColor
    tableView.separatorColor = _nightModeIsOn ? veryDarkActiveColor : darkerActiveColor
  }

  private func _handleFeedGroupChange()
  {
    _updateGroupColors()
    _dataSource?.elements = FeedManager.shared.activeFeeds
    tableView.reloadData()
  }

  private func _createNewFeed(name : String, for location : URL?, insertAtTopOfGroup : Bool)
  {
    let locationString = location?.absoluteString ?? ""
    let fm = FeedManager.shared
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
    _selectedRow += 1
    performSegue(withIdentifier: "showFeedEditor", sender:self.tableView.cellForRow(at: indexPath))
  }
}


extension FeedGroupViewController
{
  // MARK: UITableViewDelegate

  override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool
  {
    return true
  }

  override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath)
  {
    if editingStyle == .delete
    {
      FeedManager.shared.removeFeed(at:indexPath.row)
      tableView.deleteRows(at: [indexPath], with: .fade)
      if _selectedRow == indexPath.row
      {
        _selectedRow = -1
        _clearFeedView()
      }
      else if _selectedRow > indexPath.row
      {
        _selectedRow -= 1
      }
    }
    else if editingStyle == .insert
    {
      insertNewFeed(self)
    }
  }

  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
  {
    let feed = FeedManager.shared.activeFeeds[indexPath.row]
    if isValidFeedAddress(feed.location)
    {
      performSegue(withIdentifier: "showFeed", sender:self.tableView.cellForRow(at: indexPath))
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
      if _selectedRow >= 0
      {
        if let currentSelectedCell = tableView.cellForRow(at: NSIndexPath(indexes:[0,_selectedRow], length: 2) as IndexPath)
        {
          currentSelectedCell.backgroundColor = UIColor.clear
        }
      }
      _selectedRow = indexPath.row
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
}


extension FeedGroupViewController : FeedManagerExternalChangeObserver
{
  func handleFeedGroupContentsChangedExternally()
  {
    _handleFeedGroupChange()
  }
}

