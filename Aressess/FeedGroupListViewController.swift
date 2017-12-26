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
  private var _tableViewHandler : AressessTableViewHandler<FeedGroup>?
  private var _nightModeIsOn = false

  deinit
  {
    NotificationCenter.default.removeObserver(self)
    FeedManager.shared.removeExternalChangeObserver(self)
  }

  override func viewDidLoad()
  {
    super.viewDidLoad()
    self.clearsSelectionOnViewWillAppear = true

    navigationItem.rightBarButtonItem = editButtonItem
    navigationItem.largeTitleDisplayMode = .automatic
    navigationItem.title = LocString("FeedGroupSelectorTitle")
    hidesBottomBarWhenPushed = false

    _setUpTableViewHandler()
  }

  override func viewWillAppear(_ animated:Bool)
  {
    super.viewWillAppear(animated)
    _nightModeIsOn = UserDefaults.standard.bool(forKey: PreferenceKey_NightModeEnabled)
    self.view.backgroundColor = _nightModeIsOn ? NightModeBackgroundColor : DefaultBackgroundColor

    _refreshTable()
  }

  override func viewDidAppear(_ animated: Bool)
  {
    super.viewDidAppear(animated)
    _createToolbarItems()
  }

  private func _setUpTableViewHandler()
  {
    let handler = AressessTableViewHandler<FeedGroup>(tableView: tableView, cellIdentifier:"FeedGroupListCell")
    handler.removalCallback = {
      FeedManager.shared.removeFeedGroup(at:$0.row)
    }
    handler.selectionCallback = {
      FeedManager.shared.activeGroupIndex = $0.row
      self.performSegue(withIdentifier:"showGroup", sender:self.tableView.cellForRow(at: $0))
    }
    handler.editingCallback = {
      self.performSegue(withIdentifier:"showGroupEditor", sender:self.tableView.cellForRow(at: $0))
    }
    _tableViewHandler = handler
  }

  private func _refreshTable()
  {
    _tableViewHandler?.elements = FeedManager.shared.feedGroups
  }
}

extension FeedGroupListViewController : FeedManagerExternalChangeObserver
{
  // MARK: FeedManagerExternalChangeObserver to be implemented

  func handleFeedGroupContentsChangedExternally()
  {
    _refreshTable()
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
