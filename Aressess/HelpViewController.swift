//
//  HelpViewController.swift
//  Aressess
//
//  Created by Kai Oezer on 8/26/14.
//  Copyright (c) 2014, 2017 Kai Oezer. All rights reserved.
//

import UIKit

class HelpContentCell : UICollectionViewCell
{
  var imageView : UIView
  var label : UILabel

  override init(frame:CGRect)
  {
    imageView = UIView(frame:frame)
    label = UILabel(frame:frame)
    super.init(frame:frame)
    _setUpViews()
  }

  required init?(coder decoder: NSCoder)
  {
    let dummyFrame = CGRect(x: 0, y: 0, width: 100, height: 20)
    imageView = UIView(frame:dummyFrame)
    label = UILabel(frame:dummyFrame)
    super.init(coder:decoder)
    _setUpViews()
  }

  func layoutContentsForWidth(_ width:CGFloat, height:CGFloat)
  {
    contentView.removeConstraints(contentView.constraints)
    let verticalMargin : NSNumber = 12.0
    let horizontalMargin : NSNumber = 20.0
    let width = NSNumber(value:Float(width) - 2*horizontalMargin.floatValue)
    let height = NSNumber(value:Float(height) - 32 - 2 * verticalMargin.floatValue)
    ViewUtils.layout(in: contentView,
      visualFormats:["H:|-hm-[iv(w)]-hm-|", "H:|-hm-[label]-hm-|", "V:|-vm-[label(32)]-vm-[iv(h)]|"],
      metricsInfo: ["hm":horizontalMargin, "vm":verticalMargin, "w":width, "h":height],
      viewsInfo:["iv":imageView, "label":label]
    )
  }

  private func _setUpViews()
  {
    contentView.translatesAutoresizingMaskIntoConstraints = false
    contentView.addSubview(imageView)
    contentView.addSubview(label)
    label.adjustsFontSizeToFitWidth = true
  }
}

//MARK: -

class HelpViewController : UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UIScrollViewDelegate
{
  @IBOutlet var versionLabel : UILabel?
  @IBOutlet var closeButton : UIButton?
  @IBOutlet var pageControl : UIPageControl?
  @IBOutlet var collectionView : UICollectionView?
  @IBOutlet var linkView : UIView?

  private var numberOfHelpPages = 0

  //MARK: UIViewController overrides

  override func viewDidLoad()
  {
    super.viewDidLoad()
    assert(linkView != nil, "there must be a view that can be tapped")
    linkView?.addGestureRecognizer(UITapGestureRecognizer(target:self, action:#selector(HelpViewController.handleLinkTap(_:))))
    if let cv = collectionView
    {
      cv.register(HelpContentCell.self, forCellWithReuseIdentifier:"HelpContentCell")
      cv.backgroundColor = UIColor.clear
      if let flowLayout = cv.collectionViewLayout as? UICollectionViewFlowLayout
      {
        flowLayout.minimumInteritemSpacing = 0
        flowLayout.minimumLineSpacing = 0
        flowLayout.sectionInset = UIEdgeInsets.zero
      }
    }
  }

  override func viewWillLayoutSubviews()
  {
    addBackgroundGradientToView(self.view)
  }

  override func viewWillAppear(_ animated: Bool)
  {
    super.viewWillAppear(animated)
    var versionLabelText = ""
    if let bundleInfo = Bundle.main.infoDictionary
    {
      if let versionString = bundleInfo["CFBundleShortVersionString"] as? NSString
      {
        versionLabelText = NSString(format:LocString("HelpVersionLabelString") as NSString, versionString) as String
      }
    }
    versionLabel?.text = versionLabelText
    closeButton?.setTitle(LocString("ViewCloseButtonTitle"), for:UIControlState())
    collectionView?.dataSource = self
    collectionView?.delegate = self
  }

  override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?)
  {
    super.traitCollectionDidChange(previousTraitCollection)
    collectionView?.reloadData()
  }

  override var preferredStatusBarStyle : UIStatusBarStyle
  {
    get {
      // status bar style can only be set if UIViewControllerBasedStatusBarAppearance in the plist is NO
      if let window = self.view.window, window.traitCollection.horizontalSizeClass == .compact
      {
        return .lightContent
      }
      return .default
    }
  }

  //MARK: Actions

  @IBAction func dismiss(_ sender:AnyObject!)
  {
    self.dismiss(animated: true, completion:nil)
  }

  @objc func handleLinkTap(_ tapRecognizer : UITapGestureRecognizer)
  {
    if let homepageLocation = URL(string:"http://robo.fish/feed-r")
    {
      UIApplication.shared.open(homepageLocation)
    }
  }

  //MARK: UICollectionViewDataSource

  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int
  {
    return 2
  }

  func collectionView(_ cv:UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell
  {
    let cell = cv.dequeueReusableCell(withReuseIdentifier: "HelpContentCell", for:indexPath) as! HelpContentCell
    let layer = cell.imageView.layer
    if (indexPath as NSIndexPath).row == 0
    {
      if let image = UIImage(named:"help_select_group")
      {
        layer.contents = image.cgImage
      }
      cell.label.text = LocString("HelpSelectingGroup")
    }
    else
    {
      if let image = UIImage(named:"help_assign_to_group")
      {
        layer.contents = image.cgImage
      }
      cell.label.text = LocString("HelpAssigningToGroup")
    }
    layer.contentsGravity = kCAGravityResizeAspect
    cell.label.textAlignment = .center
    cell.label.textColor = UIColor(red:0.9, green:0.9, blue:0.9, alpha:1.0)
    if let layout = cv.collectionViewLayout as? UICollectionViewFlowLayout
    {
      let frameSize = cv.frame.size
      layout.itemSize = CGSize(width: frameSize.width, height: frameSize.height)
    }
    return cell
  }

  //MARK: UICollectionViewDelegate

  func collectionView(_ cv:UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool
  {
    return false
  }

  func collectionView(_ cv:UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath)
  {
    if let helpContentCell = cell as? HelpContentCell
    {
      let frameSize = cv.frame.size
      helpContentCell.layoutContentsForWidth(frameSize.width, height:frameSize.height)
    }
  }

  //MARK: UIScrollViewDelegate

  func scrollViewDidEndDecelerating(_ scrollView: UIScrollView)
  {
    pageControl?.currentPage = scrollView.contentOffset.x > (0.80 * scrollView.frame.size.width) ? 1 : 0
  }
}
