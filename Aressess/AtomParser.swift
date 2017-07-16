//
//  AtomParser.swift
//  Aressess
//
//  Created by Kai Özer on 8/1/14.
//  Copyright (c) 2014, 2017 Kai Özer. All rights reserved.
//

import Foundation

private let AtomNamespace = "http://www.w3.org/2005/Atom"

/// Parses XML strings in the Atom 1.0 format
open class AtomParser : Parser
{
  open var feed : AtomFeed?
  fileprivate var currentEntry : AtomEntry?
  fileprivate var expectingStringForEntryTitle : Bool = false
  fileprivate var expectingStringForEntryContent : Bool = false
  fileprivate var expectingStringForEntrySummary : Bool = false

  //MARK: Parser overrides

  override func parsingWillStart()
  {
  }

  override func parsingDidEnd()
  {
  }

  override func parsingStartsElementWithName(_ name: String, namespaceURI: String?, attributes: [String : String])
  {
    if (namespaceURI != nil) && (namespaceURI! == AtomNamespace)
    {
      switch name
      {
        case "feed" : _handleNewFeedElement(attributes as [NSObject : AnyObject]!)
        case "entry": _handleEntryElementWithAttributes(attributes as [NSObject : AnyObject]!)
        case "title": _handleTitleElementWithAttributes(attributes as [NSObject : AnyObject]!)
        case "link": _handleLinkElementWithAttributes(attributes as [NSObject : AnyObject]!)
        case "content": _handleContentElementWithAttributes(attributes as [NSObject : AnyObject]!)
        case "summary": _handleSummaryElementWithAttributes(attributes as [NSObject : AnyObject]!)
        default: break
      }
    }
    else
    {
    #if DEBUG
      print("Atom feed has wrong URI")
    #endif
    }
  }

  override func parsingEndsElementWithName(_ name: String, namespaceURI: String!)
  {
    if (namespaceURI != nil) && (namespaceURI! == AtomNamespace)
    {
      if let f = feed
      {
        switch name
        {
          case "entry":
            if currentEntry != nil
            {
              f.entries.append(currentEntry!)
              currentEntry = nil
            }
          case "title":
            expectingStringForEntryTitle = false
          case "content":
            expectingStringForEntryContent = false
          case "summary":
            expectingStringForEntrySummary = false
          default: break
        }
      }
    }
  }

  override func parsingFindsString(_ string: String)
  {
    if expectingStringForEntryTitle
    {
      if currentEntry != nil
      {
        if currentEntry!.title != nil
        {
          currentEntry!.title! += string
        }
        else
        {
          currentEntry!.title = string
        }
      }
    }
    else if expectingStringForEntryContent
    {
      if currentEntry != nil
      {
        if currentEntry!.content != nil
        {
          currentEntry!.content! += string
        }
        else
        {
          currentEntry!.content = string
        }
      }
    }
    else if expectingStringForEntrySummary
    {
      if currentEntry != nil
      {
        if currentEntry!.summary != nil
        {
          currentEntry!.summary! += string
        }
        else
        {
          currentEntry!.summary = string
        }
      }
    }
  }

  //MARK: Private

  fileprivate func _handleNewFeedElement(_ attributes : [AnyHashable: Any]!)
  {
    if feed != nil
    {
      print("unexpected additional feed element")
    }
    else
    {
      feed = AtomFeed()
    }
  }

  fileprivate func _handleEntryElementWithAttributes(_ attributes:[AnyHashable: Any]!)
  {
    if currentEntry == nil
    {
      currentEntry = AtomEntry()
    }
    
  }

  fileprivate func _handleTitleElementWithAttributes(_ attributes:[AnyHashable: Any]!)
  {
    if currentEntry != nil
    {
      expectingStringForEntryTitle = true
    }
  }

  fileprivate func _handleLinkElementWithAttributes(_ attributes:[AnyHashable: Any]!)
  {
    if (currentEntry != nil) && (currentEntry!.link != nil)
    {
      if let relValue = attributes?["rel"] as? NSString
      {
        if let typeValue = attributes?["type"] as? NSString
        {
          if (relValue == "alternate") && (typeValue == "text/html")
          {
            if let linkValue = attributes?["href"] as? NSString
            {
              currentEntry!.link = linkValue.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            }
          }
        }
      }
    }
  }

  fileprivate func _handleContentElementWithAttributes(_ attributes:[AnyHashable: Any]!)
  {
    if currentEntry != nil
    {
      expectingStringForEntryContent = true
    }
  }

  fileprivate func _handleSummaryElementWithAttributes(_ attributes:[AnyHashable: Any]!)
  {
    if currentEntry != nil
    {
      expectingStringForEntrySummary = true
    }
  }

}
