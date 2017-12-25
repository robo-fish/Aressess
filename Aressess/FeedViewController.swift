//
//  FeedViewController.swift
//  Aressess
//
//  Created by Kai Oezer on 7/17/14.
//  Copyright (c) 2014, 2017 Kai Oezer. All rights reserved.
//

import UIKit

private let NewsCellIdentifier = "NewsItemCell"
private let ErrorMessageCellIdentifier = "ErrorMessageCellIdentifier"


class FeedViewController : UITableViewController
{
  private var _nightMode = false
  private var _news : [News]?
  private var _readNews : [News]? // news that have been read
  private var _errorMessage = ""
  private var _activityIndicator : UIActivityIndicatorView! // used to indicate activity when loading news of a new feed
  private var _searchWorker = SearchWorker<News>()
  private var _loader : FeedLoader?

  var feed: Feed?
  {
    didSet
    {
      _dismissErrorMessage()
      _configureView()
      _news = nil
      _readNews = nil
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

  override func prepare(for segue: UIStoryboardSegue, sender: Any?)
  {
    guard segue.identifier == "showNewsContent" else { return }
    guard let indexPath = self.tableView.indexPathForSelectedRow else { return }
    let row = indexPath.row
    guard let newsItem = _searchWorker.results?[row] ?? _news?[row] else { return }
    guard let newsContentViewController = segue.destination as? NewsContentViewController else { return }
    newsItem.hasBeenRead = true
    newsContentViewController.news = newsItem
  }

  override func viewDidLoad()
  {
    super.viewDidLoad()

    hidesBottomBarWhenPushed = true

    assert(tableView != nil, "reference to table should already be set")
    tableView.register(NewsCellView.self, forCellReuseIdentifier:NewsCellIdentifier)
    tableView.register(ErrorMessageCellView.self, forCellReuseIdentifier:ErrorMessageCellIdentifier)
    tableView.delegate = self
    tableView.dataSource = self

    _activityIndicator = UIActivityIndicatorView(activityIndicatorStyle:.gray)
    _activityIndicator.hidesWhenStopped = true
    navigationItem.rightBarButtonItem = UIBarButtonItem(customView:_activityIndicator)

    self.navigationItem.largeTitleDisplayMode = .never

    NotificationCenter.default.addObserver(self, selector:#selector(FeedViewController.handleNightModeChanged(_:)), name:NSNotification.Name(rawValue: NightModeChangedNotification), object:nil)

    self.navigationItem.searchController = _searchWorker.controller
    self.navigationItem.hidesSearchBarWhenScrolling = true
    _searchWorker.completionHandler = { self.tableView.reloadData() }

    _setUpRefreshControl()
    _configureView()
  }

  override func viewWillAppear(_ animated: Bool)
  {
    super.viewWillAppear(animated)
    _updateColors()
    _searchWorker.refreshView()
    self.tableView?.reloadData()
  }

  override func viewWillDisappear(_ animated: Bool)
  {
    _searchWorker.deactivateView()
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

  private func _setUpRefreshControl()
  {
    refreshControl = UIRefreshControl()
    refreshControl?.addTarget(self, action:#selector(FeedViewController.handleFeedRefresh(_:)), for:.valueChanged)
  }

  private func _configureView()
  {
    self.navigationItem.title = feed?.name ?? ""
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
    let darkActiveColor = FeedManager.shared.darkerActiveColor
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

    let searchBar = _searchWorker.controller.searchBar
    searchBar.barStyle = _nightMode ? .black : .default
    searchBar.keyboardAppearance = _nightMode ? .dark : .default
  }

  private func _dismissErrorMessage()
  {
    _errorMessage = ""
    tableView?.separatorStyle = .singleLine
    DispatchQueue.main.async { self.tableView?.isScrollEnabled = true }
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

}

extension FeedViewController
{
  //MARK: UITableViewDataSource

  override func numberOfSections(in tableView: UITableView) -> Int
  {
    return 1
  }

  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
  {
    return _errorMessage.isEmpty ? (_searchWorker.results?.count ?? (_news?.count ?? 0)) : 1
  }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
  {
    if _errorMessage.isEmpty
    {
      if let cell = tableView.dequeueReusableCell(withIdentifier: NewsCellIdentifier) as? NewsCellView
      {
        cell.news = _searchWorker.results?[indexPath.row] ?? _news?[indexPath.row]
        cell.backgroundColor = _nightMode ? NightModeBackgroundColor : DefaultBackgroundColor
        let coloredBackgroundView = UIView()
        coloredBackgroundView.backgroundColor = _nightMode ? FeedManager.shared.darkerActiveColor : FeedManager.shared.lighterActiveColor
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

}

extension FeedViewController : FeedLoaderDelegate
{
  func handleLoadedFeedForLoader(_ loader:FeedLoader)
  {
    loader.delegate = nil // prevents retain cycle
    _news = loader.news
    _searchWorker.searchables = _news
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

  private func _showErrorMessage(_ message:String)
  {
    _errorMessage = message
    tableView.separatorStyle = .none
    tableView.isScrollEnabled = false
    tableView.reloadData()
  }

}

