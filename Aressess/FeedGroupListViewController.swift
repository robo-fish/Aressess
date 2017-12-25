//
//  FeedGroupListViewController.swift
//  Aressess
//
//  Created by Kai Oezer on 8/16/14.
//  Copyright (c) 2014, 2017 Kai Oezer. All rights reserved.
//

import UIKit


class FeedGroupListViewController : UITableViewController
{
  @IBOutlet var backgroundView : UIImageView!
  private var _nightModeIsOn = false
  private var _selectedRow : Int = -1
  private let FeedGroupListCellIdentifier = "FeedGroupListCell"

  var backgroundImage : UIImage? = nil

  override func viewDidLoad()
  {
    super.viewDidLoad()
    navigationItem.rightBarButtonItem = editButtonItem
    navigationItem.largeTitleDisplayMode = .automatic
    navigationItem.title = LocString("FeedGroupSelectorTitle")
    hidesBottomBarWhenPushed = false
  }

  override func viewWillAppear(_ animated:Bool)
  {
    super.viewWillAppear(animated)
    _nightModeIsOn = UserDefaults.standard.bool(forKey: PreferenceKey_NightModeEnabled)
    self.view.backgroundColor = _nightModeIsOn ? NightModeBackgroundColor : DefaultBackgroundColor
  }

  override func viewDidAppear(_ animated: Bool)
  {
    super.viewDidAppear(animated)
    _createToolbarItems()
  }

  private func _removeGroup(at rowIndex : Int)
  {
    FeedManager.shared.removeFeedGroup(at:rowIndex)
    if _selectedRow == rowIndex
    {
      _selectedRow = -1
    }
    else if _selectedRow > rowIndex
    {
      _selectedRow -= 1
    }
  }
}


extension FeedGroupListViewController
{
  // MARK: UITableViewDataSource

  override func numberOfSections(in tableView: UITableView) -> Int
  {
    return 1
  }

  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
  {
    return FeedManager.shared.feedGroups.count
  }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
  {
    let cell = tableView.dequeueReusableCell(withIdentifier: FeedGroupListCellIdentifier, for: indexPath)
    let feedGroup = FeedManager.shared.feedGroups[indexPath.row]
    cell.textLabel?.text = feedGroup.name
    cell.textLabel?.font = UIFont.preferredFont(forTextStyle: UIFontTextStyle.headline)
    cell.textLabel?.textColor = _nightModeIsOn ? NightModeTextColor : DefaultTextColor
    cell.textLabel?.highlightedTextColor = _nightModeIsOn ? NightModeTextColor : DefaultTextColor
    let coloredBackgroundView = UIView()
    coloredBackgroundView.backgroundColor = _nightModeIsOn ? FeedManager.shared.darkerActiveColor : FeedManager.shared.lighterActiveColor
    cell.selectedBackgroundView = coloredBackgroundView
    cell.backgroundColor = _nightModeIsOn ? NightModeBackgroundColor : DefaultBackgroundColor
    return cell
  }

  override func tableView(_ tableView:UITableView, moveRowAt sourceIndexPath:IndexPath, to destinationIndexPath:IndexPath)
  {
    let sourceRowIndex = sourceIndexPath.row
    let destinationRowIndex = destinationIndexPath.row
    FeedManager.shared.moveFeedGroup(fromRow:sourceRowIndex, toRow:destinationRowIndex)

    if _selectedRow == sourceRowIndex
    {
      _selectedRow = destinationRowIndex
    }
    else if (_selectedRow > sourceRowIndex) && (_selectedRow < destinationRowIndex)
    {
      _selectedRow -= 1
    }
    else if (_selectedRow >= destinationRowIndex) && (_selectedRow < sourceRowIndex)
    {
      _selectedRow += 1
    }

    tableView.reloadData()
  }
}


extension FeedGroupListViewController
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
      _removeGroup(at: indexPath.row)
      tableView.deleteRows(at: [indexPath], with: .fade)
    }
    else if editingStyle == .insert
    {
      //_insertNewGroup(self)
    }
  }

  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
  {
    FeedManager.shared.activeGroupIndex = indexPath.row
    performSegue(withIdentifier:"showFeedList", sender:self.tableView.cellForRow(at: indexPath))
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

extension FeedGroupListViewController
{
  // MARK: Toolbar actions

  private func _createToolbarItems()
  {
    let night_mode_toolbar_icon = UIImage(named:"toolbar_night_mode")
    assert(night_mode_toolbar_icon != nil)
    let leftButton = UIBarButtonItem(image:night_mode_toolbar_icon, landscapeImagePhone:night_mode_toolbar_icon, style:.plain, target:self, action:#selector(FeedGroupListViewController.toggleNightMode(_:)))
    let flexSpace = UIBarButtonItem(barButtonSystemItem:.flexibleSpace, target:self, action:nil)
    let helpButton = UIBarButtonItem(title:"?", style:.plain, target:self.navigationController, action:#selector(AressessNavigationController.showHelp(_:)))
    //let leadingFixedSpace = UIBarButtonItem(barButtonSystemItem:.fixedSpace, target:self, action:nil)
    //leadingFixedSpace.width = 24.0
    let trailingFixedSpace = UIBarButtonItem(barButtonSystemItem:.fixedSpace, target:self, action:nil)
    trailingFixedSpace.width = 6.0
    toolbarItems = [leftButton, flexSpace, helpButton, trailingFixedSpace]
  }

  @objc func toggleNightMode(_ sender:AnyObject!)
  {
    toggleGlobalNightMode()
  }

}
