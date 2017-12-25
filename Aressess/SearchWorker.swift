//
//  SearchWorker.swift
//  Aressess
//
//  Created by Kai Oezer on 12/25/17.
//  Copyright © 2017 Kai Oezer. All rights reserved.
//

import UIKit

class SearchWorker<T> : NSObject, UISearchBarDelegate, UISearchResultsUpdating
{
  private(set) var controller : UISearchController
  var searchables : [T]?
  var keywords : [String]?
  private(set) var results : [T]?

  typealias SearchCompletionCallback = ()->()
  var completionHandler : SearchCompletionCallback?

  override init()
  {
    controller = UISearchController(searchResultsController:nil)
    controller.searchBar.searchBarStyle = .default
    controller.dimsBackgroundDuringPresentation = false
    controller.hidesNavigationBarDuringPresentation = false
    //self.definesPresentationContext = true // necessary for search results to be displayed as a subview of this view controller
    //extendedLayoutIncludesOpaqueBars = false
    super.init()
    controller.searchResultsUpdater = self
    controller.searchBar.delegate = self
  }

  func refreshView()
  {
    if let keys = keywords, !keys.isEmpty
    {
      controller.isActive = true
      controller.searchBar.text = keys.joined(separator: " ") // triggers new search
    }
  }

  func deactivateView()
  {
    controller.isActive = false
  }

  // UISearchBarDelegate

  func searchBarSearchButtonClicked(_ searchBar: UISearchBar)
  {
    searchBar.resignFirstResponder()
  }

  // UISearchResultsUpdating

  func updateSearchResults(for searchController: UISearchController)
  {
    // do nothing if the view is offscreen
    keywords = nil
    if let text = controller.searchBar.text, !text.isEmpty
    {
      let strippedString = text.trimmingCharacters(in: CharacterSet.whitespaces)
      keywords = strippedString.components(separatedBy: " ")
    }
    _updateSearchResults()
  }

  /// The search results will include the news items that contain all of the given keywords in their title.
  private func _updateSearchResults()
  {
    results = nil
    if let items = searchables, let keys = keywords, !keys.isEmpty
    {
      var searchPredicates = [NSPredicate]()
      for keyword in keys
      {
        let lhs = NSExpression(forKeyPath:"title")
        let rhs = NSExpression(forConstantValue:keyword)
        let predicate = NSComparisonPredicate(leftExpression:lhs, rightExpression:rhs, modifier:.direct, type:.contains, options:.caseInsensitive)
        searchPredicates.append(predicate)
      }
      let compoundSearchPredicate = NSCompoundPredicate(andPredicateWithSubpredicates:searchPredicates)
      results = items.filter( { (n : T) in return compoundSearchPredicate.evaluate(with: n) } )
    }

    if let handler = completionHandler
    {
      handler()
    }
  }
}
