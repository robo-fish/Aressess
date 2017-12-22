//
//  FeedViewController.swift
//  Aressess
//
//  Created by Kai Özer on 7/17/14.
//  Copyright (c) 2014, 2017 Kai Özer. All rights reserved.
//

import UIKit
import FXKit

private let NewsCellIdentifier = "NewsCellIdentifier"
private let ErrorMessageCellIdentifier = "ErrorMessageCellIdentifier"


class FeedViewController: UITableViewController,
  FeedLoaderDelegate,
  UISplitViewControllerDelegate,
  UISearchBarDelegate, UISearchResultsUpdating
{
  private var _nightMode = false
  private var _news : [News]?
  private var _readNews : [News]? // news that have been read
  private var _searchResults : [News]?
  private var _searchKeywords : [String]?
  private var _errorMessage = ""
  private var _activityIndicator : UIActivityIndicatorView! // used to indicate activity when loading news of a new feed
  private var _searchController : UISearchController! // used to indicate activity when refreshing the news of the current feed
  private var _loader : FeedLoader?

  var feed: Feed?
  {
    didSet
    {
      _dismissErrorMessage()
      _configureView()
      _news = nil
      _readNews = nil
      _searchResults = nil
      tableView?.reloadData()
      if feed != nil
      {
        if _fetchNewsItems()
        {
          _startActivityIndicator()
        }
      }
    }
  }

  deinit
  {
    NotificationCenter.default.removeObserver(self)
  }

  //MARK: NSViewController overrides

  override func prepare(for segue: UIStoryboardSegue, sender: Any?)
  {
    if segue.identifier == "showNewsContent"
    {
      if let indexPath = self.tableView.indexPathForSelectedRow
      {
        if
          let newsItem = _searchResults?[(indexPath as NSIndexPath).row] ?? _news?[(indexPath as NSIndexPath).row],
          let newsContentViewController = segue.destination as? NewsContentViewController
        {
          newsItem.hasBeenRead = true
          newsContentViewController.news = newsItem
        }
      }
    }
  }

  override func viewDidLoad()
  {
    super.viewDidLoad()

    assert(tableView != nil, "reference to table should already be set")
    tableView.register(NewsCellView.self, forCellReuseIdentifier:NewsCellIdentifier)
    tableView.register(ErrorMessageCellView.self, forCellReuseIdentifier:ErrorMessageCellIdentifier)
    tableView.delegate = self
    tableView.dataSource = self

    _activityIndicator = UIActivityIndicatorView(activityIndicatorStyle:.gray)
    _activityIndicator.hidesWhenStopped = true
    navigationItem.rightBarButtonItem = UIBarButtonItem(customView:_activityIndicator)

    NotificationCenter.default.addObserver(self, selector:#selector(FeedViewController.handleNightModeChanged(_:)), name:NSNotification.Name(rawValue: NightModeChangedNotification), object:nil)

    _setUpSearchController()
    _setUpRefreshControl()

    _configureView()
  }

  override func viewWillAppear(_ animated: Bool)
  {
    super.viewWillAppear(animated)
    _updateColors()
    _updateToolbar()
    if let keywords = _searchKeywords
    {
      if !keywords.isEmpty
      {
        _searchController.isActive = true
        _searchController.searchBar.text = (keywords as NSArray).componentsJoined(by: " ") // triggers new search
      }
    }
    self.tableView?.reloadData()
  }

  override func viewWillDisappear(_ animated: Bool)
  {
    _searchController.isActive = false
    if _loader != nil
    {
      _loader!.delegate = nil
    }

    super.viewWillDisappear(animated)
  }

  override var preferredStatusBarStyle : UIStatusBarStyle
  {
    get { return _nightMode ? .lightContent : .default }
  }

  //MARK: UISplitViewControllerDelegate

  func splitViewController(_ splitController: UISplitViewController, collapseSecondary secondaryViewController: UIViewController, onto primaryViewController: UIViewController) -> Bool
  {
    return true // Indicates that we have handled the collapse by doing nothing; the secondary controller will be discarded.
  }

  //MARK: FeedLoaderDelegate

  func handleLoadedFeedForLoader(_ loader:FeedLoader)
  {
    loader.delegate = nil // prevents retain cycle
    self._news = loader.news
    _dismissErrorMessage()
    DispatchQueue.main.async(execute: {self.tableView.reloadData()}) // UI refreshes must be performed in the main thread
    _stopActivityIndicator()
    _markReadNews()
  }

  func handleErrorMessage(_ message:String, forLoader loader:FeedLoader)
  {
    loader.delegate = nil // prevents retain cycle
    _showErrorMessage(message)
    _stopActivityIndicator()
  }

  //MARK: UITableViewDataSource

  override func numberOfSections(in tableView: UITableView) -> Int
  {
    return 1
  }

  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
  {
    return _errorMessage.isEmpty ? (_searchResults?.count ?? (_news?.count ?? 0)) : 1
  }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
  {
    if _errorMessage.isEmpty
    {
      if let cell = tableView.dequeueReusableCell(withIdentifier: NewsCellIdentifier) as? NewsCellView
      {
        cell.news = _searchResults?[(indexPath as NSIndexPath).row] ?? _news?[(indexPath as NSIndexPath).row]
        cell.backgroundColor = _nightMode ? NightModeBackgroundColor : DefaultBackgroundColor
        let coloredBackgroundView = UIView()
        coloredBackgroundView.backgroundColor = _nightMode ? FeedManager.sharedFeedManager().darkerActiveColor : FeedManager.sharedFeedManager().lighterActiveColor
        cell.selectedBackgroundView = coloredBackgroundView
        return cell
      }
    }
    else
    {
      if let cell = tableView.dequeueReusableCell(withIdentifier: ErrorMessageCellIdentifier) as? ErrorMessageCellView
      {
        cell.message = _errorMessage
        cell.backgroundColor = _nightMode ? NightModeBackgroundColor : DefaultBackgroundColor
        cell.messageLabel.textColor = _nightMode ? NightModeTextColor : DefaultTextColor
        return cell
      }
    }
    return UITableViewCell()
  }

  //MARK: UITableViewDelegate

  override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath?
  {
    return _errorMessage.isEmpty ? indexPath : nil
  }

  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
  {
    performSegue(withIdentifier: "showNewsContent", sender:self)
  }

  override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool
  {
    return _errorMessage.isEmpty
  }

  //MARK: UISearchBarDelegate

  func searchBarSearchButtonClicked(_ searchBar: UISearchBar)
  {
    searchBar.resignFirstResponder()
  }

  //MARK: UISearchResultsUpdating

  func updateSearchResults(for searchController: UISearchController)
  {
    if navigationController?.visibleViewController == self // do nothing if the view is offscreen
    {
      _searchKeywords = nil
      if let text = searchController.searchBar.text, !text.isEmpty
      {
        let strippedString = text.trimmingCharacters(in: CharacterSet.whitespaces)
        _searchKeywords = strippedString.components(separatedBy: " ")
      }
      _updateSearchResults()
    }
  }

  //MARK: Actions and Notifications

  @objc func handleFeedRefresh(_ sender:AnyObject!)
  {
    _collectReadNewsItems()
    if !_fetchNewsItems()
    {
      self.refreshControl?.endRefreshing()
    }
  }

  @objc func handleNightModeChanged(_ notification:Notification!)
  {
    _updateColors()
    tableView.reloadData()
  }

  @objc func toggleNightMode(_ sender:AnyObject!)
  {
    toggleGlobalNightMode()
  }

  //MARK: Private

  private func _setUpSearchController()
  {
    _searchController = UISearchController(searchResultsController:nil)
    _searchController.searchResultsUpdater = self
    _searchController.searchBar.sizeToFit()
    _searchController.searchBar.searchBarStyle = .default
    tableView.tableHeaderView = _searchController.searchBar
    _searchController.dimsBackgroundDuringPresentation = false
    _searchController.hidesNavigationBarDuringPresentation = false
    _searchController.searchBar.delegate = self
    self.definesPresentationContext = true // necessary for search results to be displayed as a subview of this view controller
    extendedLayoutIncludesOpaqueBars = true
  }

  private func _setUpRefreshControl()
  {
    let refreshControl = UIRefreshControl()
    refreshControl.addTarget(self, action:#selector(FeedViewController.handleFeedRefresh(_:)), for:.valueChanged)
    self.refreshControl = refreshControl
  }

  private func _updateToolbar()
  {
    if traitCollection.horizontalSizeClass == .compact
    {
      let night_mode_toolbar_icon = UIImage(named:"toolbar_night_mode")
      assert(night_mode_toolbar_icon != nil)
      let leftButton = UIBarButtonItem(image:night_mode_toolbar_icon, landscapeImagePhone:night_mode_toolbar_icon, style:.plain, target:self, action:#selector(FeedViewController.toggleNightMode(_:)))
      let spacer = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
      self.toolbarItems = [leftButton, spacer]
    }
  }

  private func _configureView()
  {
    title = feed?.name ?? ""
    _updateColors()
  }

  /// :return: whether the news are being downloaded
  private func _fetchNewsItems() -> Bool
  {
    if feed?.location?.scheme != nil
    {
      _loader = FeedLoader(feed:feed!)
      _loader!.loadNewsWithDelegate(self)
      return true
    }
    return false
  }

  private func _updateColors()
  {
    _nightMode = UserDefaults.standard.bool(forKey: PreferenceKey_NightModeEnabled)
    setNeedsStatusBarAppearanceUpdate()

    tableView.backgroundColor = _nightMode ? NightModeBackgroundColor : DefaultBackgroundColor
    let darkActiveColor = FeedManager.sharedFeedManager().darkerActiveColor
    let veryDarkActiveColor = darkActiveColor.lighter(0.6)
    tableView.separatorColor = _nightMode ? veryDarkActiveColor : darkActiveColor
    tableView.indicatorStyle = _nightMode ? .white : .default
    if let navController = self.navigationController
    {
      navController.navigationBar.barTintColor = _nightMode ? NightModeNavigationBarBackgroundColor : DefaultNavigationBarBackgroundColor
      let textColor = _nightMode ? NightModeTitleColor : DefaultTitleColor
      navController.navigationBar.titleTextAttributes = [NSAttributedStringKey.foregroundColor : textColor]
      navController.toolbar.barTintColor = navController.navigationBar.barTintColor
    }

    _activityIndicator.activityIndicatorViewStyle = _nightMode ? .white : .gray

    refreshControl?.tintColor = _nightMode ? NightModeTextColor : DefaultTextColor
    refreshControl?.backgroundColor = _nightMode ? NightModeBackgroundColor : DefaultBackgroundColor

    let searchBar = _searchController.searchBar
    searchBar.barStyle = _nightMode ? .black : .default
    searchBar.keyboardAppearance = _nightMode ? .dark : .default
  }

  private func _showErrorMessage(_ message:String)
  {
    _errorMessage = message
    tableView.separatorStyle = .none
    tableView.isScrollEnabled = false
    tableView.reloadData()
  }

  private func _dismissErrorMessage()
  {
    _errorMessage = ""
    tableView?.separatorStyle = .singleLine
    tableView?.isScrollEnabled = true
  }

  private func _startActivityIndicator()
  {
    DispatchQueue.main.async(execute: {self._activityIndicator.startAnimating()})
  }

  private func _stopActivityIndicator()
  {
    DispatchQueue.main.async(execute: {
      self._activityIndicator.stopAnimating()
      self.refreshControl?.endRefreshing()
    })
  }

  private func _collectReadNewsItems()
  {
    if _readNews == nil
    {
      _readNews = [News]()
    }
    else
    {
      _readNews!.removeAll()
    }

    if _news != nil
    {
      for newsItem in _news!
      {
        if newsItem.hasBeenRead
        {
          _readNews!.append(newsItem)
        }
      }
    }
  }

  private func _markReadNews()
  {
    if (_news != nil) && (_readNews != nil)
    {
      for newsItem in _news!
      {
        for readNewsItem in _readNews!
        {
          if newsItem == readNewsItem
          {
            newsItem.hasBeenRead = true
          }
        }
      }
    }
  }

  /// The search results will include the news items that contain all of the given keywords in their title.
  private func _updateSearchResults()
  {
    _searchResults = nil
    if let keywords = _searchKeywords
    {
      if !keywords.isEmpty
      {
        var searchPredicates = [NSPredicate]()
        for keyword in keywords
        {
          let lhs = NSExpression(forKeyPath:"title")
          let rhs = NSExpression(forConstantValue:keyword)
          let predicate = NSComparisonPredicate(leftExpression:lhs, rightExpression:rhs, modifier:.direct, type:.contains, options:.caseInsensitive)
          searchPredicates.append(predicate)
        }
        let compoundSearchPredicate = NSCompoundPredicate(andPredicateWithSubpredicates:searchPredicates)
        _searchResults = _news?.filter( { (n : News) in return compoundSearchPredicate.evaluate(with: n) } )
      }
    }

    self.tableView.reloadData()
  }

}

