//
//  AressessTableViewController.swift
//  Aressess
//
//  Created by Kai Oezer on 12/25/17.
//  Copyright © 2017 Kai Oezer. All rights reserved.
//

import UIKit

class AressessTableViewDataSource<Element:Codable&Nameable> : NSObject, UITableViewDataSource, UITableViewDelegate
{
  private var _elements : [Element]
  private var _tableView : UITableView
  private var _searchWorker = SearchWorker<Element>()
  private let _cellID : String
  private var _selectedRow : Int = -1

  init(tableView : UITableView, cellIdentifier : String)
  {
    _cellID = cellIdentifier
    _elements = [Element]()
    _tableView = tableView
    super.init()
    _tableView.dataSource = self
    _tableView.delegate = self
    _searchWorker.completionHandler = { self._tableView.reloadData() }

    NotificationCenter.default.addObserver(self, selector:#selector(AressessTableViewDataSource<Element>.handleNightModeChanged), name:NSNotification.Name(rawValue: NightModeChangedNotification), object:nil)
  }

  deinit
  {
    NotificationCenter.default.removeObserver(self)
  }

  var elements : [Element]
  {
    get { return _elements }
    set
    {
      _elements = newValue
      _searchWorker.searchables = _elements
      _tableView.reloadData()
    }
  }

  var searchController : UISearchController
  {
    return _searchWorker.controller
  }

  var nightModeIsOn = false

  // MARK: UITableViewDataSource

  func numberOfSections(in tableView: UITableView) -> Int
  {
    return 1
  }

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
  {
    return _searchWorker.results?.count ?? FeedManager.shared.activeFeeds.count
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
  {
    let cell = _tableView.dequeueReusableCell(withIdentifier: _cellID, for: indexPath)
    cell.accessoryType = .detailDisclosureButton
    let row = indexPath.row
    let element = _searchWorker.results?[row] ?? _elements[row]
    cell.textLabel?.text = element.name
    cell.textLabel?.font = UIFont.preferredFont(forTextStyle: UIFontTextStyle.headline)
    cell.textLabel?.textColor = nightModeIsOn ? NightModeTextColor : DefaultTextColor
    cell.textLabel?.highlightedTextColor = nightModeIsOn ? NightModeTextColor : DefaultTextColor
    let coloredBackgroundView = UIView()
    coloredBackgroundView.backgroundColor = nightModeIsOn ? DefaultBackgroundColor : NightModeBackgroundColor
    cell.selectedBackgroundView = coloredBackgroundView
    cell.backgroundColor = nightModeIsOn ? NightModeBackgroundColor : DefaultBackgroundColor
    return cell
  }

  func tableView(_ tableView:UITableView, moveRowAt sourceIndexPath:IndexPath, to destinationIndexPath:IndexPath)
  {
    let sourceRowIndex = sourceIndexPath.row
    let destinationRowIndex = destinationIndexPath.row
    FeedManager.shared.moveFeedInActiveGroup(fromRow:sourceRowIndex, toRow:destinationRowIndex)

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

  // MARK: Notification Handlers

  @objc func handleNightModeChanged(notification : Notification)
  {
    
  }
}

