//
//  NewsContentViewController.swift
//  Aressess
//
//  Created by Kai Oezer on 8/6/14.
//  Copyright (c) 2014, 2017 Kai Oezer. All rights reserved.
//

import UIKit


class NewsContentViewController : UIViewController
{
  @IBOutlet weak var webview : UIWebView!
  private var _activityIndicator : UIActivityIndicatorView!
  private var _activityBarItem : UIBarButtonItem!
  private var _loadingNewsItemContent = false
  private var _nightMode = false

  var news : News?

  deinit
  {
    NotificationCenter.default.removeObserver(self)
  }

  //MARK: UIViewController overrides

  override func viewDidLoad()
  {
    assert(webview != nil)
    webview.isOpaque = false
    webview.delegate = self

    _activityIndicator = UIActivityIndicatorView(activityIndicatorStyle:.gray)
    _activityIndicator.hidesWhenStopped = true
    _activityBarItem = UIBarButtonItem(customView:_activityIndicator)

    NotificationCenter.default.addObserver(self, selector:#selector(NewsContentViewController.handleNightModeChanged(_:)), name:NSNotification.Name(rawValue: NightModeChangedNotification), object:nil)
  }

  override func viewWillAppear(_ animated : Bool)
  {
    super.viewWillAppear(animated)
    navigationItem.searchController = nil
    _updateColors()
    _updateToolbar()
  }

  override func viewDidAppear(_ animated : Bool)
  {
    navigationItem.title = (news != nil) ? news!.title : ""
    if !_loadNewsContent()
    {
      _loadLinkedPage()
    }
  }

  override func viewWillTransition(to size:CGSize, with coordinator:UIViewControllerTransitionCoordinator)
  {
    if !_loadNewsContent()
    {
      _loadLinkedPage()
    }
  }

  //MARK: Actions and Notifications

  /// Must not be private, otherwise this method can't receive messages from the Objective-C runtime.
  @objc func openInSafari(_ sender:AnyObject!)
  {
    if (news != nil) && !news!.link.isEmpty
    {
      if let pageLocation = URL(string:news!.link)
      {
        UIApplication.shared.open(pageLocation)
      }
    }
  }

  @objc func handleNightModeChanged(_ notification : Notification)
  {
    _updateColors()
    let _ = _loadNewsContent()
  }

  @objc func toggleNightMode(_ sender:AnyObject!)
  {
    toggleGlobalNightMode()
  }

  //MARK: Private

  private func _preparePage()
  {
    if let scriptFilePath = Bundle.main.path(forResource: "pageBeautification", ofType:"js")
    {
      do
      {
        let scriptContent = try String(contentsOfFile:scriptFilePath, encoding:String.Encoding.utf8)
        webview.stringByEvaluatingJavaScript(from: scriptContent)
      }
      catch let error as NSError
      {
        print(error.localizedDescription)
      }
    }
  }

  private func _loadNewsContent() -> Bool
  {
    var content = news?.content
    if (content == nil) || content!.isEmpty
    {
      content = news?.summary
    }
    if content != nil && !content!.isEmpty
    {
      webview.scalesPageToFit = false
      _loadingNewsItemContent = true
      let white = "white"
      let black = "black"
      let pageStyle = "body { background-color: \(_nightMode ? black : white); color: \(_nightMode ? white : black); }"
      let wrappedContent = "<html><head><style>\(pageStyle)</style></head><body><div id=\"topContainer\">\(content!)</div></body></html>"
      webview.loadHTMLString(wrappedContent, baseURL:URL(string:""))
      return true
    }
    return false
  }

  private func _pageIsEmpty() -> Bool
  {
    let PageHeightThreshold = 8 // points
    var result = false
    if let pageHeight : String = webview.stringByEvaluatingJavaScript(from: "document.getElementById('topContainer').clientHeight;")
    {
      result = (Int(pageHeight)! < PageHeightThreshold)
    }
    return result
  }

  private func _loadLinkedPage()
  {
    if !news!.link.isEmpty
    {
      webview!.scalesPageToFit = true
      if let pageLocation = URL(string:news!.link)
      {
        let request = URLRequest(url:pageLocation)
        DispatchQueue.main.async(execute: {self.webview!.loadRequest(request)})
      }
    }
  }

  private func _updateColors()
  {
    _nightMode = UserDefaults.standard.bool(forKey: PreferenceKey_NightModeEnabled)
    self.view.backgroundColor = _nightMode ? NightModeBackgroundColor : DefaultBackgroundColor
    if let navController = self.navigationController
    {
      navController.navigationBar.barTintColor = _nightMode ? NightModeNavigationBarBackgroundColor : DefaultNavigationBarBackgroundColor
      let textColor = _nightMode ? NightModeTitleColor : DefaultTitleColor
      navController.navigationBar.titleTextAttributes = [NSAttributedStringKey.foregroundColor : textColor]
      navController.toolbar.barTintColor = navController.navigationBar.barTintColor
    }
    webview?.scrollView.indicatorStyle = _nightMode ? .white : .default
  }

  private func _updateToolbar()
  {
    var items : [UIBarButtonItem] = []
    if traitCollection.horizontalSizeClass == .compact
    {
      let night_mode_toolbar_icon = UIImage(named:"toolbar_night_mode")
      assert(night_mode_toolbar_icon != nil)
      let leftButton = UIBarButtonItem(image:night_mode_toolbar_icon, landscapeImagePhone:night_mode_toolbar_icon, style:.plain, target:self, action:#selector(NewsContentViewController.toggleNightMode(_:)))
      items.append(leftButton)
    }
    let spacer = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target:nil, action:nil)
    items.append(spacer)
    if let link = news?.link, !link.isEmpty
    {
      let safariButton = UIBarButtonItem(title: LocString("OpenInSafari"), style: .plain, target: self, action: #selector(NewsContentViewController.openInSafari(_:)))
      items.append(safariButton)
    }
    self.toolbarItems = items
  }
}

extension NewsContentViewController : UIWebViewDelegate
{
  func webViewDidStartLoad(_ webView : UIWebView)
  {
    navigationItem.setRightBarButton(_activityBarItem, animated:true)
    self._activityIndicator.startAnimating()
  }

  func webViewDidFinishLoad(_ webView : UIWebView)
  {
    var stopActivityIndicator = true
    if _loadingNewsItemContent
    {
      _loadingNewsItemContent = false
      if _pageIsEmpty()
      {
        _loadLinkedPage()
        stopActivityIndicator = false
      }
    }
    if stopActivityIndicator
    {
      _activityIndicator.stopAnimating()
      _updateToolbar()
    }
    _preparePage()
  }

  func webView(_ webView: UIWebView, didFailLoadWithError error : Error)
  {
    self._activityIndicator.stopAnimating()
    _updateToolbar()
  }
}

